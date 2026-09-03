// lib/data/services/ble_service.dart
//
// Connectionless BLE proximity gate — a fourth layer on top of the
// existing Wi-Fi broadcast + room code (see udp_service.dart). The
// lecturer's phone advertises a short token derived from the sessionId;
// right before a student submits attendance, their phone runs a brief
// scan for that token. BLE's much shorter, wall-attenuated range (vs
// Wi-Fi) is what actually rejects "same subnet but different room /
// building" cases that neither UDP discovery nor the room code can catch.
//
// Deliberately advertise/scan only — no GATT connections. Android BLE
// peripherals reliably support only ~4-7 simultaneous GATT connections,
// which is a worse ceiling than the Wi-Fi router limits this feature
// exists alongside; passive scanning has no such cap.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../core/constants/ble_constants.dart';

/// Result of a proximity scan.
///
/// Only [matched] passes. Every other case blocks submission, including
/// [unsupported] (no BLE hardware at all) — there's no soft-pass case.
/// A student on hardware that genuinely can't run the check is a rare,
/// legitimate edge case, but the fix for that is the lecturer's manual
/// override after the session (manual_override_screen.dart), not a
/// silent bypass baked into the gate — the same silent pass would just
/// as easily be used by anyone wanting to dodge the check outright, not
/// only those with a genuine hardware gap.
enum BleProximityResult {
  matched,
  notMatched,
  bluetoothOff,
  permissionDenied,
  unsupported,
}

class BleService {
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  /// Derives a short, deterministic token from the session ID. Both the
  /// lecturer and student compute this independently from the sessionId
  /// they already exchange over UDP — nothing extra needs to be sent.
  static Uint8List _tokenFor(String sessionId) {
    final digest = sha256.convert(utf8.encode(sessionId)).bytes;
    return Uint8List.fromList(digest.sublist(0, BleConstants.tokenLength));
  }

  // ── Lecturer side: advertise ──────────────────────────────────────────

  /// Attempts to advertise [sessionId]'s token. Returns whether
  /// advertising actually started — false covers unsupported hardware,
  /// denied permission, and Bluetooth being off alike, since callers only
  /// need to know whether to tell students this session has the gate.
  Future<bool> startAdvertising(String sessionId) async {
    try {
      var permission = await _peripheral.requestPermission();

      if (permission == PeripheralBluetoothState.turnedOff) {
        // Prompt the lecturer with the system "Turn on Bluetooth?" dialog —
        // the same pattern Maps uses for "turn on Location" — instead of
        // silently running the whole session with the gate off because the
        // radio happened to be off when it started.
        final enabled = await _peripheral.enableBluetooth();
        if (!enabled) {
          print('[BleService] Lecturer declined to enable Bluetooth');
          return false;
        }
        permission = await _peripheral.requestPermission();
      }

      if (permission != PeripheralBluetoothState.granted) {
        print('[BleService] Advertise permission not granted: $permission');
        return false;
      }

      final result = await _peripheral.start(
        advertiseData: AdvertiseDataCore(
          serviceUuid: BleConstants.serviceUuid,
          manufacturerId: BleConstants.manufacturerId,
          manufacturerData: _tokenFor(sessionId),
        ),
      );
      final started = result == PeripheralBluetoothState.ready;
      print(
        '[BleService] Advertising ${started ? "started" : "failed ($result)"} '
        'for session $sessionId',
      );
      return started;
    } catch (e) {
      print('[BleService] Error starting advertising: $e');
      return false;
    }
  }

  Future<void> stopAdvertising() async {
    try {
      await _peripheral.stop();
      print('[BleService] Advertising stopped');
    } catch (e) {
      print('[BleService] Error stopping advertising: $e');
    }
  }

  // ── Student side: scan ────────────────────────────────────────────────

  /// Scans for up to [timeout] looking for a peripheral advertising
  /// [sessionId]'s token on the app's service UUID.
  Future<BleProximityResult> scanForToken(
    String sessionId, {
    Duration timeout = BleConstants.scanTimeout,
  }) async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        return BleProximityResult.unsupported;
      }
    } catch (e) {
      print('[BleService] isSupported check failed: $e');
      return BleProximityResult.unsupported;
    }

    BluetoothAdapterState state;
    try {
      state = await FlutterBluePlus.adapterState.first;
    } catch (e) {
      print('[BleService] adapterState check failed: $e');
      return BleProximityResult.unsupported;
    }

    if (state == BluetoothAdapterState.unauthorized) {
      return BleProximityResult.permissionDenied;
    }

    if (state != BluetoothAdapterState.on) {
      // Prompt the same system "Turn on Bluetooth?" dialog Maps uses for
      // "turn on Location" — a student whose Bluetooth is off (whether
      // habitually, or specifically to dodge this check) gets asked to
      // turn it back on instead of silently passing the gate. This is the
      // fix for the bypass: previously "off" and "no hardware" were
      // treated identically and both fell through as a soft pass.
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        print('[BleService] User declined or failed to enable Bluetooth: $e');
        return BleProximityResult.bluetoothOff;
      }
    }

    final expected = _tokenFor(sessionId);
    final completer = Completer<BleProximityResult>();
    StreamSubscription? sub;

    void finish(BleProximityResult result) {
      if (completer.isCompleted) return;
      completer.complete(result);
      sub?.cancel();
      FlutterBluePlus.stopScan();
    }

    try {
      sub = FlutterBluePlus.onScanResults.listen(
        (results) {
          for (final r in results) {
            final data = r.advertisementData
                .manufacturerData[BleConstants.manufacturerId];
            if (data != null && _matches(data, expected)) {
              finish(BleProximityResult.matched);
              return;
            }
          }
        },
        onError: (Object e) {
          print('[BleService] Scan error: $e');
          // Hardware and radio-on are already confirmed above, so a
          // failure here is almost certainly a denied runtime permission.
          finish(BleProximityResult.permissionDenied);
        },
      );

      await FlutterBluePlus.startScan(
        withServices: [Guid(BleConstants.serviceUuid)],
        timeout: timeout,
      );

      // startScan's own timeout stops the radio; give the results stream a
      // moment to deliver any final batch before giving up.
      unawaited(
        Future.delayed(timeout + const Duration(milliseconds: 500), () {
          finish(BleProximityResult.notMatched);
        }),
      );
    } catch (e) {
      print('[BleService] Error starting scan: $e');
      finish(BleProximityResult.permissionDenied);
    }

    return completer.future;
  }

  bool _matches(List<int> received, List<int> expected) {
    if (received.length != expected.length) return false;
    for (var i = 0; i < expected.length; i++) {
      if (received[i] != expected[i]) return false;
    }
    return true;
  }
}

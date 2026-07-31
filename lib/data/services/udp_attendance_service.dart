// lib/data/services/udp_attendance_service.dart
//
// UDP-based attendance submission (bidirectional).
// Student sends attendance request via UDP, lecturer responds with confirmation.
// Both save to local database immediately.

import 'dart:io';
import 'dart:convert';
import 'package:oromark/core/constants/network_constants.dart';
import 'package:oromark/data/database/app_database.dart';
import 'package:oromark/presentation/student/home/student_home_controller.dart';

class UDPAttendanceService {
  final AppDatabase _db;
  late RawDatagramSocket _socket;

  UDPAttendanceService(this._db);

  /// Student submits attendance via UDP to lecturer
  ///
  /// Returns: 'PRESENT' or 'LATE' from lecturer's confirmation
  /// Throws: Exception if communication fails
  Future<String> submitAttendanceViaUDP({
    required DetectedSession session,
    required String studentId,
    required int localPort,  // Port to listen for response
  }) async {
    try {
      // Create UDP socket to send and receive
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, localPort);

      print('[UDPAttendanceService] Listening on port $localPort');

      // Build attendance payload
      final payload = {
        'type': 'attendance_submit',
        'sessionId': session.sessionId,
        'studentId': studentId,
        'roomCode': session.roomCode,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final message = jsonEncode(payload).codeUnits;

      // Send UDP packet to lecturer
      final lecturerIP = InternetAddress(session.lecturerIP);
      _socket.send(message, lecturerIP, NetworkConstants.udpPort);  // Send to lecturer's UDP port

      print('[UDPAttendanceService] Sent attendance to ${session.lecturerIP}:${NetworkConstants.udpPort}');
      print('[UDPAttendanceService] Payload: ${jsonEncode(payload)}');

      // Wait for confirmation from lecturer (max 10 seconds)
      final confirmation = await _waitForConfirmation();

      print('[UDPAttendanceService] Received confirmation: $confirmation');

      // Parse lecturer's response
      final data = jsonDecode(confirmation) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'PRESENT';
      final lecturerMessage = data['message'] as String? ?? '';

      // Save to local database
      await _db.insertAttendanceRecord(
        sessionId: session.sessionId,
        studentId: studentId,
        status: status,
        submittedAt: DateTime.now().millisecondsSinceEpoch,
        // synced: true,  // ← UDP is direct, so mark as synced immediately
      );

      print('[UDPAttendanceService] Saved locally: $studentId → $status');

      _socket.close();
      return status;
    } catch (e) {
      print('[UDPAttendanceService] Failed: $e');
      _socket.close();
      rethrow;
    }
  }

  /// Wait for confirmation from lecturer via UDP (max 10 seconds)
  Future<String> _waitForConfirmation() async {
    try {
      final completer = Future<String>.delayed(const Duration(seconds: 10), () {
        throw TimeoutException('No confirmation from lecturer within 10 seconds');
      });

      final subscription = _socket.asBroadcastStream().listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket.receive();
          if (datagram != null) {
            final message = String.fromCharCodes(datagram.data);
            print('[UDPAttendanceService] Raw UDP message: $message');

            // Check if this is a confirmation
            try {
              final data = jsonDecode(message) as Map<String, dynamic>;
              if (data['type'] == 'attendance_confirm') {
                // This is the confirmation we're waiting for
                subscription.cancel();
              }
            } catch (_) {
              // Not JSON, ignore
            }
          }
        }
      });

      // Wait for first valid message or timeout
      while (true) {
        try {
          final datagram = _socket.receive();
          if (datagram != null) {
            final message = String.fromCharCodes(datagram.data);
            final data = jsonDecode(message) as Map<String, dynamic>;

            if (data['type'] == 'attendance_confirm') {
              subscription.cancel();
              return message;
            }
          }
        } catch (e) {
          if (e is TimeoutException) {
            rethrow;
          }
        }

        // Yield control
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      print('[UDPAttendanceService] Confirmation error: $e');
      rethrow;
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
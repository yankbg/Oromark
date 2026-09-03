// lib/providers/session_discovery_provider.dart
//
// Riverpod provider that listens to UDP broadcasts from lecturers
// and exposes discovered sessions as a reactive stream.
//
// When session_discovery_screen.dart mounts, this provider automatically:
// 1. Binds to UDP port (NetworkConstants.udpPort)
// 2. Listens for incoming broadcasts
// 3. Parses session JSON data
// 4. Emits List<DetectedSession> whenever a new broadcast arrives
// 5. Cleans up (stops listening) when screen unmounts
//
// Usage in widget:
//   final discoveredSessionsAsync = ref.watch(discoveredSessionsProvider);
//   discoveredSessionsAsync.when(
//     loading: () => LoadingWidget(),
//     data: (sessions) => ListView(...),
//     error: (e, st) => ErrorWidget(),
//   )

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oromark/core/constants/network_constants.dart';
import 'package:oromark/presentation/student/home/student_home_controller.dart';
import 'package:oromark/data/database/app_database.dart';
import 'app_database_provider.dart';
import 'auth_state_provider.dart';

/// Looks up whether the logged-in student already has an attendance record
/// for [sessionId] — used to disable an already-confirmed session tile in
/// the discovery sheet.
final attendanceRecordProvider =
    FutureProvider.family<AttendanceRecord?, String>((ref, sessionId) async {
      final authResult = ref.watch(authStateNotifierProvider).value;
      if (authResult == null) return null;

      final db = ref.watch(appDatabaseProvider);
      return db.getAttendanceRecord(
        sessionId: sessionId,
        studentId: authResult.userId,
      );
    });

/// Provides the UDP service singleton for session discovery
final sessionUdpServiceProvider = Provider<RawDatagramSocket?>((_) => null);

/// Listens to UDP broadcasts from lecturers and emits discovered sessions
///
/// Flow:
/// 1. Binds RawDatagramSocket to UDP_PORT
/// 2. Listens for incoming datagrams
/// 3. Parses JSON → DetectedSession
/// 4. Maintains a Map<sessionId, DetectedSession>
/// 5. Yields the full list whenever a new session arrives
///
/// The stream will:
/// - Start with AsyncLoading (showing "Listening for broadcasts...")
/// - Emit AsyncData<List<DetectedSession>> each time a broadcast is received
/// - Emit AsyncError if socket binding fails
///
/// Sessions expire automatically (checked in UI via session.remaining)

final discoveredSessionsProvider = StreamProvider<List<DetectedSession>>((ref) {
  ref.keepAlive(); // Keep alive across navigation ← NEW
  return _discoveredSessionsStream(); // Extracted into helper function ← NEW
});

// A missed "ENDED" broadcast (dropped UDP packet, app briefly backgrounded
// during the 3-packet burst, etc.) must not leave a session stuck forever —
// a default session runs for hours, so isExpired alone won't catch it any
// time soon. Broadcasts repeat every broadcastIntervalPresent/Late seconds
// (6s/20s) while a session is genuinely still live, so treat a session as
// gone once nothing has been heard from it for a few late-interval periods.
const _staleAfter = Duration(seconds: 60);

Stream<List<DetectedSession>> _discoveredSessionsStream() {
  final sessions = <String, DetectedSession>{};
  final lastSeen = <String, DateTime>{};
  RawDatagramSocket? socket;
  Timer? pruneTimer;
  late final StreamController<List<DetectedSession>> controller;

  void emit() {
    final sorted = sessions.values.toList()
      ..sort((a, b) => b.remaining.compareTo(a.remaining));
    controller.add(sorted);
  }

  // Drops any session past its own end time, or one whose broadcasts have
  // simply stopped arriving (see _staleAfter) — the fallback for when the
  // lecturer's "ended" broadcast (below) is missed, so a stale session
  // doesn't sit in the list forever with nothing to remove it.
  void pruneExpired() {
    final now = DateTime.now();
    final before = sessions.length;
    sessions.removeWhere((id, s) {
      final seen = lastSeen[id];
      return s.isExpired || (seen != null && now.difference(seen) > _staleAfter);
    });
    lastSeen.removeWhere((id, _) => !sessions.containsKey(id));
    if (sessions.length != before) emit();
  }

  Future<void> start() async {
    try {
      // ── Bind to UDP port ─────────────────────────────────────────────
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        NetworkConstants.udpPort,
      );

      print(
        '[DiscoveryProvider] UDP listener started on port ${NetworkConstants.udpPort}',
      );

      pruneTimer = Timer.periodic(const Duration(seconds: 5), (_) => pruneExpired());

      socket!.listen(
        (event) {
          // RawSocketEvent.read means data is available
          if (event != RawSocketEvent.read) return;
          final datagram = socket!.receive();
          if (datagram == null) return;

          try {
            // ── Decode UDP packet ──────────────────────────────────────
            final message = utf8.decode(datagram.data);
            final sessionData = jsonDecode(message) as Map<String, dynamic>;
            final sessionId = sessionData['sessionId'] as String;

            // The lecturer sends this once, right when they end the
            // session — remove it immediately instead of waiting for its
            // natural end time (or the periodic prune above) to catch up.
            if (sessionData['status'] == 'ENDED') {
              lastSeen.remove(sessionId);
              if (sessions.remove(sessionId) != null) {
                print('[DiscoveryProvider] Session ended by lecturer: $sessionId');
                emit();
              }
              return;
            }

            // ── Parse into DetectedSession ─────────────────────────────
            final detected = DetectedSession(
              sessionId: sessionId,
              courseCode: sessionData['courseCode'] as String,
              courseName: sessionData['courseName'] as String,
              lecturerName: 'lecturer',
              room: sessionData['roomCode'] as String,
              roomCode:
                  sessionData['roomCode']
                      as String, // [SENSITIVE] only shown to lecturer
              presentCutoff: DateTime.parse(sessionData['startTime'] as String)
                  .toLocal()
                  .add(
                    const Duration(minutes: NetworkConstants.presentMinutes),
                  ), // or whatever your present window is
              lateCutoff: DateTime.parse(
                sessionData['endTime'] as String,
              ).toLocal(),
              lecturerIP: sessionData['lecturerIP'] as String,
              lecturerPort: sessionData['lecturerPort'] as int,
              isLateFromBroadcast: sessionData['isLate'] as bool? ?? false,
              bleAvailable: sessionData['bleAvailable'] as bool? ?? false,
            );

            // ── Update sessions map & emit ──────────────────────────────
            sessions[detected.sessionId] = detected;
            lastSeen[detected.sessionId] = DateTime.now();
            emit();

            print(
              '[DiscoveryProvider] Broadcast received: ${detected.courseCode} '
              'from ${detected.lecturerName} (code: ${detected.roomCode})',
            );
          } catch (e) {
            print('[DiscoveryProvider] Error parsing UDP packet: $e');
            // Continue listening; one bad packet shouldn't crash the stream
          }
        },
        onError: (Object e) {
          print('[DiscoveryProvider] Socket error: $e');
          controller.addError(e);
        },
      );
    } catch (e) {
      controller.addError(e);
    }
  }

  controller = StreamController<List<DetectedSession>>(
    onListen: start,
    onCancel: () {
      // ── Cleanup when stream is cancelled ────────────────────────────
      pruneTimer?.cancel();
      socket?.close();
      print('[DiscoveryProvider] UDP listener stopped');
    },
  );

  return controller.stream;
}

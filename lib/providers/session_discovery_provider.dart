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
final discoveredSessionsProvider =
StreamProvider<List<DetectedSession>>((ref) async* {

  RawDatagramSocket? socket;
  final sessions = <String, DetectedSession>{};

  try {
    // ── Bind to UDP port ─────────────────────────────────────────────────
    socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      NetworkConstants.udpPort,
    );

    print('[DiscoveryProvider] UDP listener started on port ${NetworkConstants.udpPort}');

    // ── Listen for incoming broadcasts ────────────────────────────────────
    await for (final event in socket) {
      // RawSocketEvent.read means data is available
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();

        if (datagram == null) continue;

        try {
          // ── Decode UDP packet ────────────────────────────────────────
          final message = utf8.decode(datagram.data);
          final sessionData = jsonDecode(message) as Map<String, dynamic>;

          // ── Parse into DetectedSession ───────────────────────────────
          final detected = DetectedSession(
            sessionId: sessionData['sessionId'] as String,
            courseCode: sessionData['courseCode'] as String,
            courseName: sessionData['courseName'] as String,
            lecturerName: sessionData['lecturerName'] as String,
            room: sessionData['room'] as String,
            roomCode: sessionData['roomCode'] as String, // [SENSITIVE] only shown to lecturer
            presentCutoff: DateTime.now().add(
              Duration(minutes: sessionData['presentMinutes'] as int),
            ),
            lateCutoff: DateTime.now().add(
              Duration(minutes: sessionData['lateMinutes'] as int),
            ),
            lecturerIP: sessionData['lecturerIP'] as String,
            lecturerPort: sessionData['lecturerPort'] as int,
          );

          // ── Update sessions map & emit ───────────────────────────────
          sessions[detected.sessionId] = detected;

          // Yield the full current list of sessions
          // Listeners will see all active sessions, sorted by remaining time
          final sorted = sessions.values
              .toList()
            ..sort((a, b) => b.remaining.compareTo(a.remaining));

          yield sorted;

          print('[DiscoveryProvider] Broadcast received: ${detected.courseCode} '
              'from ${detected.lecturerName} (code: ${detected.roomCode})');
        } catch (e) {
          print('[DiscoveryProvider] Error parsing UDP packet: $e');
          // Continue listening; one bad packet shouldn't crash the stream
        }
      }
    }
  } on SocketException catch (e) {
    print('[DiscoveryProvider] Socket error: $e');
    rethrow;
  } finally {
    // ── Cleanup when stream is cancelled ─────────────────────────────────
    socket?.close();
    print('[DiscoveryProvider] UDP listener stopped');
  }
});
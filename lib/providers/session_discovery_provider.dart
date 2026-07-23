// lib/providers/session_discovery_provider.dart
//
// Riverpod provider that manages UDP session discovery.
// Listens for broadcasts from lecturers' phones and exposes detected sessions.

import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/services/udp_service.dart';
import '../presentation/student/home/student_home_controller.dart';

part 'session_discovery_provider.g.dart';

/// Singleton UDP service for listening to broadcasts
@riverpod
UdpService udpService(UdpServiceRef ref) {
  return UdpService();
}

/// Manages discovered sessions state
@riverpod
class SessionDiscoveryNotifier extends _$SessionDiscoveryNotifier {
  @override
  Future<List<DetectedSession>> build() async {
    final udp = ref.watch(udpServiceProvider);

    // Start listening when this provider is first accessed
    _startListening(udp);

    // Return empty list initially — will be updated via setState
    return [];
  }

  final List<DetectedSession> _sessions = [];

  Future<void> _startListening(UdpService udp) async {
    try {
      await udp.startListening((Map<String, dynamic> data) {
        // Parse UDP broadcast payload
        try {
          final session = DetectedSession(
            sessionId: data['sessionId'] as String? ?? 'unknown',
            courseCode: data['courseCode'] as String? ?? 'N/A',
            courseName: data['courseName'] as String? ?? 'Unknown Course',
            lecturerName: data['lecturerName'] as String? ?? 'Unknown Lecturer',
            room: data['room'] as String? ?? 'TBA',
            roomCode: data['roomCode'] as String? ?? 'XXXX',
            presentCutoff: _parseDateTime(data['presentCutoff'] as String?),
            lateCutoff: _parseDateTime(data['lateCutoff'] as String?),
            lecturerIP: data['lecturerIP'] as String? ?? '0.0.0.0',
            lecturerPort: (data['lecturerPort'] as int?) ?? 3000,
          );

          // Check if session already exists (by sessionId)
          final exists = _sessions.any((s) => s.sessionId == session.sessionId);
          if (!exists) {
            _sessions.add(session);
            state = AsyncValue.data(List.from(_sessions));
          }
        } catch (e) {
          print('Error parsing UDP broadcast: $e');
        }
      });

      print('UDP discovery listening started');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      print('Error starting UDP listener: $e');
    }
  }

  DateTime _parseDateTime(String? iso8601) {
    if (iso8601 == null) return DateTime.now();
    try {
      return DateTime.parse(iso8601);
    } catch (_) {
      return DateTime.now();
    }
  }

  /// Stop listening when provider is disposed
  void stopListening() {
    ref.read(udpServiceProvider).stopListening();
  }

  /// Clear all discovered sessions
  void clearSessions() {
    _sessions.clear();
    state = const AsyncValue.data([]);
  }
}

/// Expose the discovered sessions
@riverpod
Future<List<DetectedSession>> discoveredSessions(DiscoveredSessionsRef ref) {
  return ref.watch(sessionDiscoveryNotifierProvider.future);
}
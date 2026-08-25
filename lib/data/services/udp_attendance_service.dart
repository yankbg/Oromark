// lib/data/services/udp_attendance_service.dart
//
// UDP-based attendance submission (bidirectional).
// Student sends attendance request via UDP, lecturer responds with confirmation.
// Both save to local database immediately.

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:oromark/data/database/app_database.dart';
import 'package:oromark/presentation/student/home/student_home_controller.dart';

class UDPAttendanceService {
  final AppDatabase _db;
  RawDatagramSocket? _socket;

  UDPAttendanceService(this._db);

  /// Student submits attendance via UDP to lecturer
  ///
  /// Flow:
  /// 1. Create UDP socket on localPort
  /// 2. Send attendance request to lecturer:5501
  /// 3. Wait for confirmation response (max 10 seconds)
  /// 4. Save to local database when received
  /// 5. Return status ('PRESENT' or 'LATE')
  ///
  /// Returns: 'PRESENT' or 'LATE' from lecturer's confirmation
  /// Throws: Exception if communication fails
  Future<String> submitAttendanceViaUDP({
    required DetectedSession session,
    required String studentId,
    required int localPort,  // Port to listen for response (e.g., 5502)
  }) async {
    try {
      // Create UDP socket to send and receive
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, localPort);

      print('[UDPAttendanceService] Listening on port $localPort for confirmation');

      // Build attendance payload
      final payload = {
        'type': 'attendance_submit',
        'sessionId': session.sessionId,
        'studentId': studentId,
        'roomCode': session.roomCode,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      final message = utf8.encode(jsonEncode(payload));

      // Send UDP packet to lecturer on :5501
      final lecturerIP = InternetAddress(session.lecturerIP);
      _socket!.send(message, lecturerIP, 5501);

      print('[UDPAttendanceService] Sent attendance request to ${session.lecturerIP}:5501');
      print('[UDPAttendanceService] Payload: ${jsonEncode(payload)}');

      // Wait for confirmation from lecturer (max 10 seconds)
      final confirmation = await _waitForConfirmation();

      print('[UDPAttendanceService] Received confirmation: $confirmation');

      // Parse lecturer's response
      final data = jsonDecode(confirmation) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'PRESENT';

      // Save to local database
      await _db.insertAttendanceRecord(
        sessionId: session.sessionId,
        studentId: studentId,
        status: status,
        submittedAt: DateTime.now().millisecondsSinceEpoch,
        // synced: true,  // ← UDP is direct, so mark as synced immediately
      );

      print('[UDPAttendanceService] Saved locally: $studentId → $status');

      _socket?.close();
      return status;
    } catch (e) {
      print('[UDPAttendanceService] Failed: $e');
      _socket?.close();
      rethrow;
    }
  }

  /// Wait for confirmation from lecturer via UDP (max 10 seconds)
  Future<String> _waitForConfirmation() async {
    final startTime = DateTime.now();
    const timeout = Duration(seconds: 10);

    while (DateTime.now().difference(startTime) < timeout) {
      try {
        // Check if there's data to read
        final datagram = _socket?.receive();

        if (datagram != null) {
          final message = utf8.decode(datagram.data);
          print('[UDPAttendanceService] Raw message received: $message');

          try {
            final data = jsonDecode(message) as Map<String, dynamic>;

            // Check if this is the confirmation we're waiting for
            if (data['type'] == 'attendance_confirm') {
              return message;
            }
          } catch (e) {
            print('[UDPAttendanceService] Failed to parse message: $e');
            // Not valid JSON, ignore and continue listening
          }
        }

        // Yield control to avoid blocking
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('[UDPAttendanceService] Error receiving: $e');
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    throw TimeoutException('No confirmation from lecturer within 10 seconds');
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
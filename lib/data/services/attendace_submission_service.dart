// lib/data/services/attendance_submission_service.dart
//
// HTTP service for submitting attendance to lecturer's server.
// Handles request/response, error handling, and database persistence.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../presentation/student/home/student_home_controller.dart';
import '../database/app_database.dart';

class AttendanceSubmissionService {
  final AppDatabase _db;

  AttendanceSubmissionService(this._db);

  /// Submit attendance via HTTP POST to lecturer's server
  /// Returns the attendance status (PRESENT, LATE, ABSENT, or ERROR)
  Future<String> submitAttendance({
    required DetectedSession session,
    required String studentId,
  }) async {
    try {
      // Construct the HTTP endpoint
      final uri = Uri.http(
        session.lecturerIP,
        '/attendance/submit',
        {'port': session.lecturerPort.toString()},
      );

      // Build request payload
      final payload = {
        'sessionId': session.sessionId,
        'studentId': studentId,
        'roomCode': session.roomCode,
        'timestamp': DateTime.now().toIso8601String(),
        'deviceId': 'device_${studentId}_${DateTime.now().millisecondsSinceEpoch}',
      };

      print('[AttendanceSubmission] POST to ${session.lecturerIP}:${session.lecturerPort}');
      print('[AttendanceSubmission] Payload: $payload');

      // Send POST request with 5-second timeout
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
        // Custom timeout per NetworkConstants recommendations
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException(
          'Attendance submission timed out after 5 seconds',
        ),
      );

      print('[AttendanceSubmission] Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse server response
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final status = responseData['status'] as String? ?? 'PRESENT';

        print('[AttendanceSubmission] Server returned status: $status');

        // Insert attendance record into local database
        await _db.insertAttendanceRecord(
          sessionId: session.sessionId,
          studentId: studentId,
          status: status,
          submittedAt: DateTime.now(),
        );

        return status; // PRESENT, LATE, or ABSENT
      } else if (response.statusCode == 400) {
        // Bad request — likely invalid room code or session expired
        final error = jsonDecode(response.body)['message'] ?? 'Invalid request';
        print('[AttendanceSubmission] Server error: $error');
        throw BadRequestException(error);
      } else if (response.statusCode == 404) {
        // Session not found
        throw NotFoundException('Session not found on lecturer server');
      } else if (response.statusCode == 409) {
        // Duplicate submission
        throw DuplicateSubmissionException('You already submitted attendance');
      } else {
        // Other server errors
        throw ServerException(
          'Server error: ${response.statusCode}\n${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      print('[AttendanceSubmission] Timeout: $e');
      rethrow;
    } on http.ClientException catch (e) {
      print('[AttendanceSubmission] Network error: $e');
      throw NetworkException(
        'Could not reach lecturer server. Check WiFi connection.',
      );
    } catch (e) {
      print('[AttendanceSubmission] Unexpected error: $e');
      rethrow;
    }
  }
}

// ── Custom Exceptions ─────────────────────────────────────────────────────────
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

class BadRequestException implements Exception {
  final String message;
  BadRequestException(this.message);
  @override
  String toString() => 'Bad Request: $message';
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
  @override
  String toString() => 'Not Found: $message';
}

class DuplicateSubmissionException implements Exception {
  final String message;
  DuplicateSubmissionException(this.message);
  @override
  String toString() => 'Duplicate Submission: $message';
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
  @override
  String toString() => 'Server Error: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => 'Network Error: $message';
}
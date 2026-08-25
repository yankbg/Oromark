// lib/data/services/attendance_submission_service.dart
//
// HTTP service for submitting attendance to lecturer's server.
// Handles request/response, error handling, and database persistence.

import 'package:drift/drift.dart' show Value;
import '../../core/constants/network_constants.dart';
import '../../presentation/student/home/student_home_controller.dart';
import '../database/app_database.dart';

class AttendanceSubmissionService {
  final AppDatabase _db;

  AttendanceSubmissionService(this._db);

  /// Persists a server-confirmed attendance result to the student's own
  /// local database: the AttendanceRecord itself, plus the session's
  /// metadata (course, timing) so the student's History screen can show it
  /// without ever having received the lecturer's Sessions row.
  ///
  /// Call this with the status the server already returned from the actual
  /// submission POST (ConfirmationScreen posts directly to the lecturer's
  /// /attendance endpoint).
  Future<void> persistConfirmedAttendance({
    required DetectedSession session,
    required String studentId,
    required String status,
  }) async {
    await _db.insertAttendanceRecord(
      sessionId: session.sessionId,
      studentId: studentId,
      status: status,
      submittedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final startTime = session.presentCutoff.subtract(
      const Duration(minutes: NetworkConstants.presentMinutes),
    );
    await _db.upsertSessionMeta(
      SessionsCompanion.insert(
        sessionId: session.sessionId,
        courseCode: session.courseCode,
        courseName: session.courseName,
        roomCode: session.roomCode,
        lecturerName: Value(session.lecturerName),
        startTime: startTime.millisecondsSinceEpoch,
        endTime: session.lateCutoff.millisecondsSinceEpoch,
        presentCutoff: session.presentCutoff.toIso8601String(),
        lateCutoff: session.lateCutoff.toIso8601String(),
        status: 'ENDED',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

}
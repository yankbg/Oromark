// lib/data/services/sync_service.dart
//
// Pushes on-device SQLite data to the OROmark sync server (server/), which
// mirrors it into Neon Postgres for the future web admin dashboard.
//
// This is entirely separate from the live attendance flow — the lecturer
// broadcasts over UDP and students confirm via the local HTTP server, all
// on the classroom LAN, with zero internet involved. Sync only runs
// best-effort, whenever the phone happens to have real internet, and never
// blocks or breaks anything if it doesn't. The app never holds Postgres
// credentials — only the sync server's URL and a shared API key, both
// read from .env.

import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../database/app_database.dart';

class SyncService {
  final AppDatabase _db;
  SyncService(this._db);

  /// Bootstraps a password hash into Neon for an account that only ever
  /// existed locally (the 4 seeded students + 1 lecturer that predate the
  /// password_hash column, plus anyone else who's only ever logged in
  /// on-device). Called by LoginController right after a successful local
  /// SQLite login, whenever the earlier network login attempt told us the
  /// account doesn't exist in Neon yet (404 not_found) — i.e. we know
  /// there's internet right now, we just don't have a password there yet.
  ///
  /// The server never overwrites an existing hash with this call (e.g. one
  /// an admin set via the dashboard) — it only fills it in if it's null —
  /// so this is safe to call opportunistically. Best-effort: failures are
  /// swallowed, exactly like [syncNow], and just retried on the next login.
  Future<bool> pushPasswordBootstrap({
    required bool isLecturer,
    required String id,
    required String password,
  }) async {
    final apiUrl = dotenv.env['SYNC_API_URL'];
    final apiKey = dotenv.env['SYNC_API_KEY'];
    if (apiUrl == null || apiUrl.isEmpty || apiKey == null || apiKey.isEmpty) {
      return false;
    }
    try {
      final response = await http
          .post(
            Uri.parse('$apiUrl/auth/bootstrap-password'),
            headers: {
              'Content-Type': 'application/json',
              'X-Api-Key': apiKey,
            },
            body: jsonEncode({
              'role': isLecturer ? 'lecturer' : 'student',
              'id': id,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print('[SyncService] Password bootstrap skipped: $e');
      return false;
    }
  }

  /// Pulls the given lecturer's courses (and each course's enrolled-student
  /// roster) from Neon and caches them locally. This is the only direction
  /// sync ever runs the other way — everywhere else the app only pushes
  /// local SQLite up to Neon, so a course created straight in Neon via the
  /// admin dashboard would otherwise never reach the lecturer's device.
  /// Called once right after a successful network login. Best-effort: on
  /// any failure, whatever's already cached locally is left untouched.
  Future<void> pullLecturerData(String lecturerId) async {
    final apiUrl = dotenv.env['SYNC_API_URL'];
    final apiKey = dotenv.env['SYNC_API_KEY'];
    if (apiUrl == null || apiUrl.isEmpty || apiKey == null || apiKey.isEmpty) {
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse('$apiUrl/lecturer/courses').replace(
              queryParameters: {'id': lecturerId},
            ),
            headers: {'X-Api-Key': apiKey},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        print('[SyncService] Lecturer-courses pull failed: ${response.statusCode} ${response.body}');
        return;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final courses = (body['courses'] as List).cast<Map<String, dynamic>>();
      final enrolledStudents = (body['enrolledStudents'] as List).cast<Map<String, dynamic>>();

      for (final c in courses) {
        await _db.upsertCourse(CoursesCompanion.insert(
          courseCode: c['courseCode'] as String,
          courseName: c['courseName'] as String,
          group: Value(c['group'] as String?),
          enrolled: Value(c['enrolled'] as int? ?? 0),
          avgAttendance: Value(c['avgAttendance'] as int? ?? 0),
          lecturerId: Value(c['lecturerId'] as String?),
        ));
      }

      final rosterByCourse = <String, List<EnrolledStudentsCompanion>>{};
      for (final e in enrolledStudents) {
        final courseCode = e['courseCode'] as String;
        rosterByCourse.putIfAbsent(courseCode, () => []).add(
              EnrolledStudentsCompanion.insert(
                studentId: e['studentId'] as String,
                courseCode: courseCode,
                fullName: e['fullName'] as String,
              ),
            );
      }
      for (final c in courses) {
        final courseCode = c['courseCode'] as String;
        await _db.replaceEnrolledStudents(courseCode, rosterByCourse[courseCode] ?? []);
      }
    } catch (e) {
      print('[SyncService] Lecturer-courses pull skipped: $e');
    }
  }

  /// Pushes everything unsynced to the server. Safe to call anytime —
  /// silently does nothing if the server isn't configured or unreachable.
  Future<void> syncNow() async {
    final apiUrl = dotenv.env['SYNC_API_URL'];
    final apiKey = dotenv.env['SYNC_API_KEY'];
    if (apiUrl == null || apiUrl.isEmpty || apiKey == null || apiKey.isEmpty) {
      return; // Sync server not configured — nothing to do.
    }

    try {
      final unsyncedSessions = await _db.getUnsyncedSessions();
      final unsyncedAttendance = await _db.getUnsynced();

      // Roster/reference data is small and upserts are idempotent, so it's
      // simplest to just resend all of it rather than track sync flags for
      // every table.
      final courses = await _db.getAllCourses();
      final lecturers = await _db.getAllLecturers();
      final students = await _db.getAllStudents();
      final enrolledStudents = await _db.getAllEnrolledStudents();

      if (unsyncedSessions.isEmpty &&
          unsyncedAttendance.isEmpty &&
          courses.isEmpty &&
          lecturers.isEmpty &&
          students.isEmpty &&
          enrolledStudents.isEmpty) {
        return;
      }

      final body = jsonEncode({
        'courses': courses
            .map((c) => {
                  'courseCode': c.courseCode,
                  'courseName': c.courseName,
                  'group': c.group,
                  'enrolled': c.enrolled,
                  'avgAttendance': c.avgAttendance,
                  'lecturerId': c.lecturerId,
                })
            .toList(),
        'lecturers': lecturers
            .map((l) => {
                  'lecturerId': l.lecturerId,
                  'lecturerName': l.lecturerName,
                  'lecturerEmail': l.lecturerEmail,
                  'department': l.department,
                })
            .toList(),
        'students': students
            .map((s) => {
                  'studentId': s.studentId,
                  'studentName': s.studentName,
                  'studentEmail': s.studentEmail,
                  'phoneNumber': s.phoneNumber,
                  'programme': s.programme,
                  'yearOfStudy': s.yearOfStudy,
                  'avatarUrl': s.avatarUrl,
                })
            .toList(),
        'enrolledStudents': enrolledStudents
            .map((e) => {
                  'studentId': e.studentId,
                  'courseCode': e.courseCode,
                  'fullName': e.fullName,
                })
            .toList(),
        'sessions': unsyncedSessions
            .map((s) => {
                  'sessionId': s.sessionId,
                  'courseCode': s.courseCode,
                  'courseName': s.courseName,
                  'lecturerName': s.lecturerName,
                  'roomCode': s.roomCode,
                  'startTime': s.startTime,
                  'endTime': s.endTime,
                  'presentCutoff': s.presentCutoff,
                  'lateCutoff': s.lateCutoff,
                  'status': s.status,
                  'createdAt': s.createdAt,
                })
            .toList(),
        'attendanceRecords': unsyncedAttendance
            .map((a) => {
                  'sessionId': a.sessionId,
                  'studentId': a.studentId,
                  'status': a.status,
                  'timestamp': a.timestamp,
                })
            .toList(),
      });

      final response = await _postWithRetry(apiUrl, apiKey, body);
      if (response == null) return; // both attempts failed — retry next launch

      if (response.statusCode == 200) {
        if (unsyncedSessions.isNotEmpty) {
          await _db.markSessionsSynced(
            unsyncedSessions.map((s) => s.sessionId).toList(),
          );
        }
        if (unsyncedAttendance.isNotEmpty) {
          await _db.markSynced(unsyncedAttendance.map((a) => a.id).toList());
        }
      } else {
        print('[SyncService] Server rejected sync: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // No internet, server down — fine, we'll retry next launch.
      print('[SyncService] Sync skipped: $e');
    }
  }

  /// One request, then — if it fails for any reason (DNS not ready yet
  /// right after boot, Render's free tier cold-starting, a slow network) —
  /// one retry after a short delay. 15s was too tight for a Render free-tier
  /// cold start in practice; this is a background call with no UI cost to
  /// waiting longer.
  Future<http.Response?> _postWithRetry(
    String apiUrl,
    String apiKey,
    String body,
  ) async {
    const attempts = 2;
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        return await http
            .post(
              Uri.parse('$apiUrl/sync'),
              headers: {
                'Content-Type': 'application/json',
                'X-Api-Key': apiKey,
              },
              body: body,
            )
            .timeout(const Duration(seconds: 45));
      } catch (e) {
        final willRetry = attempt < attempts;
        print('[SyncService] Attempt $attempt/$attempts failed'
            '${willRetry ? ", retrying in 5s" : ""}: $e');
        if (willRetry) await Future.delayed(const Duration(seconds: 5));
      }
    }
    return null;
  }
}

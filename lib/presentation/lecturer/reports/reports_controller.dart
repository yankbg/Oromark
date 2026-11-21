// lib/presentation/lecturer/reports/reports_controller.dart
//
// All state and logic for the lecturer's Reports screen. Built entirely
// from local SQLite — every ENDED session for this lecturer's courses,
// plus its attendance_records — since that's exactly what's already on
// this device once a session has been run and ended (see
// session_notifier.dart's _computeAbsent()). No network/Neon round trip
// needed; this is the lecturer's own data, on their own phone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/auth_state_provider.dart';

// ── View models ──────────────────────────────────────────────────────────────

/// One ended session's attendance breakdown — one bar in the "Attendance
/// Over Time" chart.
class SessionReportEntry {
  final String sessionId;
  final String courseCode;
  final DateTime date;
  final int present;
  final int late;
  final int absent;

  const SessionReportEntry({
    required this.sessionId,
    required this.courseCode,
    required this.date,
    required this.present,
    required this.late,
    required this.absent,
  });

  int get total => present + late + absent;
}

/// One course's attendance rate across all its ended sessions — one bar in
/// the course-ranking chart. Computed here from real attendance records,
/// not from Courses.avgAttendance (that column is server-side/mock-set and
/// never actually recomputed on-device — see course_controller.dart's TODO).
class CourseAttendance {
  final String courseCode;
  final String courseName;
  final double rate; // 0.0–1.0; present = full credit, late = half credit
  final int sessionCount;

  const CourseAttendance({
    required this.courseCode,
    required this.courseName,
    required this.rate,
    required this.sessionCount,
  });
}

class ReportsState {
  final bool isLoading;
  final String? error;
  final List<SessionReportEntry> sessions; // chronological, oldest first
  final List<CourseAttendance> courseRanking; // best attendance first

  const ReportsState({
    this.isLoading = true,
    this.error,
    this.sessions = const [],
    this.courseRanking = const [],
  });

  int get totalSessions => sessions.length;
  int get totalPresent => sessions.fold(0, (sum, s) => sum + s.present);
  int get totalLate => sessions.fold(0, (sum, s) => sum + s.late);
  int get totalAbsent => sessions.fold(0, (sum, s) => sum + s.absent);

  double get overallRate {
    final totalRecords = totalPresent + totalLate + totalAbsent;
    if (totalRecords == 0) return 0;
    return (totalPresent + totalLate * 0.5) / totalRecords;
  }

  ReportsState copyWith({
    bool? isLoading,
    String? error,
    List<SessionReportEntry>? sessions,
    List<CourseAttendance>? courseRanking,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sessions: sessions ?? this.sessions,
      courseRanking: courseRanking ?? this.courseRanking,
    );
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class ReportsController extends ChangeNotifier {
  final AppDatabase _db;
  final WidgetRef _ref;
  ReportsController(this._db, this._ref) {
    _load();
  }

  ReportsState state = const ReportsState();

  Future<void> refresh() => _load();

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      final lecturerId = _ref.read(authStateNotifierProvider).value?.userId;
      if (lecturerId == null) {
        state = const ReportsState(isLoading: false);
        notifyListeners();
        return;
      }

      final courses = await _db.getCoursesForLecturer(lecturerId);
      final courseNameByCode = {for (final c in courses) c.courseCode: c.courseName};
      final endedSessions = await _db.getEndedSessionsForCourses(
        courses.map((c) => c.courseCode).toList(),
      );

      final sessionEntries = <SessionReportEntry>[];
      // courseCode -> running present/late/total for the ranking chart
      final perCourse = <String, ({int present, int late, int total})>{};

      for (final session in endedSessions) {
        final records = await _db.getSessionAttendance(session.sessionId);
        final present = records.where((r) => r.status == 'PRESENT').length;
        final late = records.where((r) => r.status == 'LATE').length;
        final absent = records.where((r) => r.status == 'ABSENT').length;

        sessionEntries.add(SessionReportEntry(
          sessionId: session.sessionId,
          courseCode: session.courseCode,
          date: DateTime.fromMillisecondsSinceEpoch(session.startTime),
          present: present,
          late: late,
          absent: absent,
        ));

        final prior = perCourse[session.courseCode] ?? (present: 0, late: 0, total: 0);
        perCourse[session.courseCode] = (
          present: prior.present + present,
          late: prior.late + late,
          total: prior.total + present + late + absent,
        );
      }

      final ranking = perCourse.entries
          .where((e) => e.value.total > 0) // skip courses with no attendance data at all
          .map((e) {
            final agg = e.value;
            return CourseAttendance(
              courseCode: e.key,
              courseName: courseNameByCode[e.key] ?? e.key,
              rate: (agg.present + agg.late * 0.5) / agg.total,
              sessionCount:
                  sessionEntries.where((s) => s.courseCode == e.key).length,
            );
          })
          .toList()
        ..sort((a, b) => b.rate.compareTo(a.rate));

      state = ReportsState(
        isLoading: false,
        sessions: sessionEntries,
        courseRanking: ranking,
      );
    } catch (e) {
      state = ReportsState(isLoading: false, error: 'Could not load reports: $e');
    }
    notifyListeners();
  }
}

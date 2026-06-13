// lib/data/models/course_model.dart
//
// Plain Dart model for a course.
// Matches the local SQLite "courses" table from the brief.
// Supabase serialisation stubs are included but no-ops until
// your teammate wires up the backend.

class CourseModel {
  final String courseCode;
  final String courseName;
  final String? lecturerId;
  final int enrolled;         // total students enrolled
  final int avgAttendance;    // 0–100 percentage, computed server-side / mock
  final String? lastSessionAt; // human-readable string for now, e.g. "2 days ago"
  final String group;         // e.g. "Group A", "Final Year"

  const CourseModel({
    required this.courseCode,
    required this.courseName,
    this.lecturerId,
    this.enrolled = 0,
    this.avgAttendance = 0,
    this.lastSessionAt,
    this.group = '',
  });

  // ── JSON (Supabase) ──────────────────────────────────────────────────────

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    return CourseModel(
      courseCode:    json['course_code'] as String,
      courseName:    json['course_name'] as String,
      lecturerId:    json['lecturer_id'] as String?,
      enrolled:      (json['enrolled'] as int?) ?? 0,
      avgAttendance: (json['avg_attendance'] as int?) ?? 0,
      lastSessionAt: json['last_session_at'] as String?,
      group:         (json['group'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'course_code':     courseCode,
    'course_name':     courseName,
    'lecturer_id':     lecturerId,
    'enrolled':        enrolled,
    'avg_attendance':  avgAttendance,
    'last_session_at': lastSessionAt,
    'group':           group,
  };

  // ── copyWith ────────────────────────────────────────────────────────────

  CourseModel copyWith({
    String? courseCode,
    String? courseName,
    String? lecturerId,
    int? enrolled,
    int? avgAttendance,
    String? lastSessionAt,
    String? group,
  }) {
    return CourseModel(
      courseCode:    courseCode    ?? this.courseCode,
      courseName:    courseName    ?? this.courseName,
      lecturerId:    lecturerId    ?? this.lecturerId,
      enrolled:      enrolled      ?? this.enrolled,
      avgAttendance: avgAttendance ?? this.avgAttendance,
      lastSessionAt: lastSessionAt ?? this.lastSessionAt,
      group:         group         ?? this.group,
    );
  }

  @override
  String toString() =>
      'CourseModel(code: $courseCode, name: $courseName, enrolled: $enrolled)';
}
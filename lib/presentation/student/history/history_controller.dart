// lib/presentation/student/history/history_controller.dart
//
// All state and logic for the attendance history screen.
// [MOCK] tags mark places a real drift query will replace.

import 'package:flutter/material.dart';

// ── Status enum ───────────────────────────────────────────────────────────────
enum AttendanceStatus { present, late, absent }

// ── History record model ──────────────────────────────────────────────────────
// Will be replaced by drift AttendanceRecord + Session join when backend wired.
class HistoryRecord {
  final String id;
  final String courseCode;
  final String courseName;
  final DateTime sessionDate;
  final AttendanceStatus status;
  final int? lateMinutes; // only set when status == late

  const HistoryRecord({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.sessionDate,
    required this.status,
    this.lateMinutes,
  });
}

// ── Filter chip options ───────────────────────────────────────────────────────
enum HistoryFilter { all, present, late, absent }

extension HistoryFilterLabel on HistoryFilter {
  String get label => switch (this) {
    HistoryFilter.all     => 'All',
    HistoryFilter.present => 'Present',
    HistoryFilter.late    => 'Late',
    HistoryFilter.absent  => 'Absent',
  };
}

// ── Controller ────────────────────────────────────────────────────────────────
class HistoryController extends ChangeNotifier {
  HistoryController() {
    _load(); // [MOCK] — replace with drift query
  }

  // ── Public state ────────────────────────────────────────────────────────────
  bool isLoading = true;
  HistoryFilter activeFilter = HistoryFilter.all;
  List<HistoryRecord> _all = [];

  // ── Derived ─────────────────────────────────────────────────────────────────
  List<HistoryRecord> get filtered => activeFilter == HistoryFilter.all
      ? _all
      : _all
      .where((r) => r.status == _filterToStatus(activeFilter))
      .toList();

  int get totalPresent => _all.where((r) => r.status == AttendanceStatus.present).length;
  int get totalLate    => _all.where((r) => r.status == AttendanceStatus.late).length;
  int get totalAbsent  => _all.where((r) => r.status == AttendanceStatus.absent).length;
  int get totalSessions => _all.length;

  double get attendanceRate {
    if (totalSessions == 0) return 0;
    // Present = full credit, Late = half credit
    return ((totalPresent + totalLate * 0.5) / totalSessions).clamp(0.0, 1.0);
  }

  String get standingLabel {
    final r = attendanceRate;
    if (r >= 0.85) return 'Good Standing';
    if (r >= 0.70) return 'Fair Standing';
    return 'At Risk';
  }

  Color get standingColor {
    final r = attendanceRate;
    if (r >= 0.85) return const Color(0xFF0F6E56); // AppColors.primary
    if (r >= 0.70) return const Color(0xFFBA7517); // AppColors.warning
    return const Color(0xFFE24B4A);                // AppColors.error
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  void setFilter(HistoryFilter f) {
    activeFilter = f;
    notifyListeners();
  }

  // ── [MOCK] data load ─────────────────────────────────────────────────────────
  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _all = _mockRecords;
    isLoading = false;
    notifyListeners();
  }

  AttendanceStatus? _filterToStatus(HistoryFilter f) => switch (f) {
    HistoryFilter.present => AttendanceStatus.present,
    HistoryFilter.late    => AttendanceStatus.late,
    HistoryFilter.absent  => AttendanceStatus.absent,
    _                     => null,
  };

  // ── Mock data ────────────────────────────────────────────────────────────────
  static final _mockRecords = <HistoryRecord>[
    HistoryRecord(
      id: '1',
      courseCode: 'CS301',
      courseName: 'Software Engineering',
      sessionDate: DateTime(2026, 10, 24, 10, 0),
      status: AttendanceStatus.present,
    ),
    HistoryRecord(
      id: '2',
      courseCode: 'MA202',
      courseName: 'Discrete Math',
      sessionDate: DateTime(2026, 10, 23, 14, 15),
      status: AttendanceStatus.late,
      lateMinutes: 12,
    ),
    HistoryRecord(
      id: '3',
      courseCode: 'PY101',
      courseName: 'Intro to Psychology',
      sessionDate: DateTime(2026, 10, 22, 9, 0),
      status: AttendanceStatus.absent,
    ),
    HistoryRecord(
      id: '4',
      courseCode: 'CS202',
      courseName: 'Database Systems',
      sessionDate: DateTime(2026, 10, 21, 11, 30),
      status: AttendanceStatus.present,
    ),
    HistoryRecord(
      id: '5',
      courseCode: 'CS405',
      courseName: 'Cloud Computing',
      sessionDate: DateTime(2026, 10, 21, 16, 0),
      status: AttendanceStatus.present,
    ),
    HistoryRecord(
      id: '6',
      courseCode: 'CS312',
      courseName: 'Computer Networks',
      sessionDate: DateTime(2026, 10, 20, 8, 0),
      status: AttendanceStatus.present,
    ),
    HistoryRecord(
      id: '7',
      courseCode: 'MA202',
      courseName: 'Discrete Math',
      sessionDate: DateTime(2026, 10, 19, 14, 0),
      status: AttendanceStatus.absent,
    ),
    HistoryRecord(
      id: '8',
      courseCode: 'CS301',
      courseName: 'Software Engineering',
      sessionDate: DateTime(2026, 10, 18, 10, 0),
      status: AttendanceStatus.late,
      lateMinutes: 7,
    ),
    HistoryRecord(
      id: '9',
      courseCode: 'CS405',
      courseName: 'Cloud Computing',
      sessionDate: DateTime(2026, 10, 17, 16, 0),
      status: AttendanceStatus.present,
    ),
    HistoryRecord(
      id: '10',
      courseCode: 'CS202',
      courseName: 'Database Systems',
      sessionDate: DateTime(2026, 10, 16, 11, 30),
      status: AttendanceStatus.present,
    ),
  ];
}
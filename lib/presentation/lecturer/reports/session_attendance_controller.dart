// lib/presentation/lecturer/reports/session_attendance_controller.dart
//
// State + mock data for the session attendance detail screen.
// Shown when lecturer taps a completed session card in CourseDetailScreen.
// [MOCK] tags = replace with drift query when backend is wired.

import 'package:flutter/material.dart';

// ── Attendance status ─────────────────────────────────────────────────────────

enum AttendanceStatus { present, late, absent }

// ── Session attendance record ─────────────────────────────────────────────────

class SessionAttendanceRecord {
  final String           name;
  final String           studentId;
  final AttendanceStatus status;
  final DateTime?        checkInTime; // null when absent

  const SessionAttendanceRecord({
    required this.name,
    required this.studentId,
    required this.status,
    this.checkInTime,
  });
}

// ── Session metadata passed from the course detail card ───────────────────────

class PastSessionInfo {
  final String month;
  final String day;
  final String title;
  final String time;
  final String attendance;   // e.g. "92%"
  final Color  attendanceColor;

  const PastSessionInfo({
    required this.month,
    required this.day,
    required this.title,
    required this.time,
    required this.attendance,
    required this.attendanceColor,
  });
}

// ── Filter ────────────────────────────────────────────────────────────────────

enum AttendanceFilter { all, present, late, absent }

extension AttendanceFilterLabel on AttendanceFilter {
  String get label => switch (this) {
    AttendanceFilter.all     => 'All',
    AttendanceFilter.present => 'Present',
    AttendanceFilter.late    => 'Late',
    AttendanceFilter.absent  => 'Absent',
  };
}

// ── Controller ────────────────────────────────────────────────────────────────

class SessionAttendanceController extends ChangeNotifier {
  SessionAttendanceController({required this.session}) {
    _load();
  }

  final PastSessionInfo session;

  // ── Public state ────────────────────────────────────────────────────────────
  bool isLoading = true;
  AttendanceFilter activeFilter = AttendanceFilter.all;
  String searchQuery = '';
  List<SessionAttendanceRecord> _all = [];

  // ── Derived ─────────────────────────────────────────────────────────────────

  List<SessionAttendanceRecord> get filtered {
    var list = _all;

    if (activeFilter != AttendanceFilter.all) {
      final target = _filterToStatus(activeFilter);
      list = list.where((r) => r.status == target).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where((r) =>
      r.name.toLowerCase().contains(q) ||
          r.studentId.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  int get totalPresent =>
      _all.where((r) => r.status == AttendanceStatus.present).length;
  int get totalLate =>
      _all.where((r) => r.status == AttendanceStatus.late).length;
  int get totalAbsent =>
      _all.where((r) => r.status == AttendanceStatus.absent).length;
  int get totalEnrolled => _all.length;

  double get presentRate =>
      totalEnrolled == 0 ? 0 : totalPresent / totalEnrolled;

  // ── Actions ──────────────────────────────────────────────────────────────────

  void setFilter(AttendanceFilter f) {
    activeFilter = f;
    notifyListeners();
  }

  void setSearch(String q) {
    searchQuery = q;
    notifyListeners();
  }

  // ── [MOCK] load ──────────────────────────────────────────────────────────────

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _all = _mockRecords;
    isLoading = false;
    notifyListeners();
  }

  AttendanceStatus? _filterToStatus(AttendanceFilter f) => switch (f) {
    AttendanceFilter.present => AttendanceStatus.present,
    AttendanceFilter.late    => AttendanceStatus.late,
    AttendanceFilter.absent  => AttendanceStatus.absent,
    _                        => null,
  };

  // ── Mock data — consistent with session_controller.dart CS301 students ───────
  static final _mockRecords = <SessionAttendanceRecord>[
    SessionAttendanceRecord(
      name:        'Alex Rivera',
      studentId:   'U-2023-8841',
      status:      AttendanceStatus.present,
      checkInTime: DateTime(2026, 10, 21, 10, 17),
    ),
    SessionAttendanceRecord(
      name:        'Elena Sofia',
      studentId:   'U-2023-9102',
      status:      AttendanceStatus.late,
      checkInTime: DateTime(2026, 10, 21, 10, 22),
    ),
    SessionAttendanceRecord(
      name:        'Jordan Mills',
      studentId:   'U-2023-7443',
      status:      AttendanceStatus.absent,
      checkInTime: null,
    ),
    SessionAttendanceRecord(
      name:        'Maya Kaur',
      studentId:   'U-2023-1109',
      status:      AttendanceStatus.present,
      checkInTime: DateTime(2026, 10, 21, 10, 16),
    ),
    SessionAttendanceRecord(
      name:        'Liam Chen',
      studentId:   'U-2023-6621',
      status:      AttendanceStatus.present,
      checkInTime: DateTime(2026, 10, 21, 10, 19),
    ),
    SessionAttendanceRecord(
      name:        'Amara Diallo',
      studentId:   'U-2023-3312',
      status:      AttendanceStatus.present,
      checkInTime: DateTime(2026, 10, 21, 10, 15),
    ),
    SessionAttendanceRecord(
      name:        'Tobias Owusu',
      studentId:   'U-2023-4471',
      status:      AttendanceStatus.absent,
      checkInTime: null,
    ),
    SessionAttendanceRecord(
      name:        'Priya Nair',
      studentId:   'U-2023-5503',
      status:      AttendanceStatus.late,
      checkInTime: DateTime(2026, 10, 21, 10, 21),
    ),
    SessionAttendanceRecord(
      name:        'Samuel Osei',
      studentId:   'U-2023-2287',
      status:      AttendanceStatus.present,
      checkInTime: DateTime(2026, 10, 21, 10, 14),
    ),
    SessionAttendanceRecord(
      name:        'Fatima Bah',
      studentId:   'U-2023-6634',
      status:      AttendanceStatus.absent,
      checkInTime: null,
    ),
    SessionAttendanceRecord(
      name:        'Kevin Mwangi',
      studentId:   'U-2023-8812',
      status:      AttendanceStatus.present,
      checkInTime: DateTime(2026, 10, 21, 10, 18),
    ),
    SessionAttendanceRecord(
      name:        'Grace Nakato',
      studentId:   'U-2023-7720',
      status:      AttendanceStatus.present,
      checkInTime: DateTime(2026, 10, 21, 10, 13),
    ),
  ];
}
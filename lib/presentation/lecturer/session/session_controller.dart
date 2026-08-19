// lib/presentation/lecturer/session/session_controller.dart
//
// Owns every piece of mutable state for the live session dashboard.
// The screen reads this via a Riverpod StateNotifierProvider.
//
// [MOCK] tags mark places that will be replaced by real drift streams
// and sessionNotifier calls when Supabase/backend is wired.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oromark/core/constants/network_constants.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/app_database_provider.dart';

// ── Window enum ───────────────────────────────────────────────────────────────

enum SessionWindow { present, late, ended }

// ── Student entry model ───────────────────────────────────────────────────────
// Will be replaced by drift AttendanceRecord + EnrolledStudent join.

enum CheckInStatus { present, late, notCheckedIn }

class StudentEntry {
  final String         name;
  final String         studentId;
  final DateTime?      checkInTime;  // null = not checked in
  final CheckInStatus  status;

  const StudentEntry({
    required this.name,
    required this.studentId,
    this.checkInTime,
    required this.status,
  });
}

// ── Dashboard state ───────────────────────────────────────────────────────────

class ActiveSessionState {
  final String         courseCode;
  final String         courseName;
  final String         room;
  final DateTime       startedAt;
  final DateTime       presentCutoff;
  final DateTime       lateCutoff;
  final SessionWindow  window;
  final int            presentCount;
  final int            lateCount;
  final int            enrolled;
  final List<StudentEntry> students;
  final String         searchQuery;
  final CheckInStatus? filterStatus; // null = All

  const ActiveSessionState({
    required this.courseCode,
    required this.courseName,
    required this.room,
    required this.startedAt,
    required this.presentCutoff,
    required this.lateCutoff,
    required this.window,
    required this.presentCount,
    required this.lateCount,
    required this.enrolled,
    required this.students,
    this.searchQuery  = '',
    this.filterStatus,
  });

  // ── Derived ──────────────────────────────────────────────────────────────

  int get notCheckedIn =>
      enrolled - presentCount - lateCount;

  Duration get remaining {
    final cutoff =
    window == SessionWindow.present ? presentCutoff : lateCutoff;
    final diff = cutoff.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  double get coverageRate =>
      enrolled == 0 ? 0 : (presentCount + lateCount) / enrolled;

  /// Students visible after search + filter
  List<StudentEntry> get filtered {
    var list = students;

    if (filterStatus != null) {
      list = list.where((s) => s.status == filterStatus).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where((s) =>
      s.name.toLowerCase().contains(q) ||
          s.studentId.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  ActiveSessionState copyWith({
    SessionWindow?       window,
    int?                 presentCount,
    int?                 lateCount,
    List<StudentEntry>?  students,
    String?              searchQuery,
    CheckInStatus?       filterStatus,
    bool                 clearFilter = false,
  }) {
    return ActiveSessionState(
      courseCode:    courseCode,
      courseName:    courseName,
      room:          room,
      startedAt:     startedAt,
      presentCutoff: presentCutoff,
      lateCutoff:    lateCutoff,
      enrolled:      enrolled,
      window:        window       ?? this.window,
      presentCount:  presentCount ?? this.presentCount,
      lateCount:     lateCount    ?? this.lateCount,
      students:      students     ?? this.students,
      searchQuery:   searchQuery  ?? this.searchQuery,
      filterStatus:  clearFilter  ? null : (filterStatus ?? this.filterStatus),
    );
  }
}

// ── [MOCK] student data — matches history_controller.dart course CS301 ────────

final _mockStudents = <StudentEntry>[
  StudentEntry(
    name:        'Alex Rivera',
    studentId:   'U-2023-8841',
    checkInTime: DateTime(2026, 10, 24, 10, 17),
    status:      CheckInStatus.present,
  ),
  StudentEntry(
    name:        'Elena Sofia',
    studentId:   'U-2023-9102',
    checkInTime: DateTime(2026, 10, 24, 10, 22),
    status:      CheckInStatus.late,
  ),
  StudentEntry(
    name:        'Jordan Mills',
    studentId:   'U-2023-7443',
    checkInTime: null,
    status:      CheckInStatus.notCheckedIn,
  ),
  StudentEntry(
    name:        'Maya Kaur',
    studentId:   'U-2023-1109',
    checkInTime: DateTime(2026, 10, 24, 10, 16),
    status:      CheckInStatus.present,
  ),
  StudentEntry(
    name:        'Liam Chen',
    studentId:   'U-2023-6621',
    checkInTime: DateTime(2026, 10, 24, 10, 19),
    status:      CheckInStatus.present,
  ),
  StudentEntry(
    name:        'Amara Diallo',
    studentId:   'U-2023-3312',
    checkInTime: DateTime(2026, 10, 24, 10, 15),
    status:      CheckInStatus.present,
  ),
  StudentEntry(
    name:        'Tobias Owusu',
    studentId:   'U-2023-4471',
    checkInTime: null,
    status:      CheckInStatus.notCheckedIn,
  ),
  StudentEntry(
    name:        'Priya Nair',
    studentId:   'U-2023-5503',
    checkInTime: DateTime(2026, 10, 24, 10, 21),
    status:      CheckInStatus.late,
  ),
];

// ── Notifier ──────────────────────────────────────────────────────────────────

class SessionController extends StateNotifier<ActiveSessionState> {
  Timer? _ticker;
  StreamSubscription<List<AttendanceRecord>>? _attendanceSubscription;
  final AppDatabase _db;
  final String _sessionId;
  final String _courseCode;
  final String _courseName;
  final int _enrolled;

  SessionController({
    required AppDatabase db,
    required String sessionId,
    required String courseCode,
    required String courseName,
    required int enrolled,
  })
      : _db = db,
        _sessionId = sessionId,
        _courseCode = courseCode,
        _courseName = courseName,
        _enrolled = enrolled,
        super(_buildInitialState(sessionId,courseCode, courseName, enrolled)) {
    _startTicker();
    _subscribeToAttendance();
    // [MOCK] — simulate 2 more students checking in after 5 s
    // Future.delayed(const Duration(seconds: 5), () {
    //   if (!mounted) return;
    //   state = state.copyWith(presentCount: state.presentCount + 2);
    // });
  }

  static ActiveSessionState _buildInitialState(
      String sessionId,
      String courseCode,
      String courseName,
      int enrolled,
      ) {
    final now = DateTime.now();
    return ActiveSessionState(
      courseCode:    courseCode,
      courseName:    courseName,
      room:          'A204',
      startedAt:     now.subtract(const Duration(minutes: 2)),
      presentCutoff: now.add(const Duration(minutes: NetworkConstants.presentMinutes)),
      lateCutoff:    now.add(const Duration(minutes: NetworkConstants.lateMinutes)),
      window:        SessionWindow.present,
      presentCount:  0,
      lateCount:     0,
      enrolled:      enrolled,
      students:      [],
    );
  }
  // Subscribe to real-time attendance updates
  // void _subscribeToAttendance() {
  //   // TODO: Get actual session ID from context — for now use mock courseCode
  //   const sessionId = 'session-cs301-2026-10-24';
  //
  //   _attendanceSubscription = _db.watchSessionAttendance(sessionId).listen(
  //         (records) {
  //       // Rebuild student list from enrolled + attendance records
  //       _rebuildStudentList(records);
  //     },
  //   );
  // }
  void _subscribeToAttendance() {
    _attendanceSubscription =
        _db.watchSessionAttendance(_sessionId).listen((records) {
          _rebuildStudentList(records);
        });
  }


  Future<void> _rebuildStudentList(List<AttendanceRecord> attendanceRecords) async {
    final enrolled = await _db.getEnrolledStudents(_courseCode);

    // Create a map of student ID → attendance record for fast lookup
    final attendanceMap = {
      for (final record in attendanceRecords) record.studentId: record,
    };

    // Build StudentEntry list from enrolled students + attendance
    final students = enrolled.map((enrolledStudent) {
      final attendance = attendanceMap[enrolledStudent.studentId];
      return StudentEntry(
        name:        enrolledStudent.fullName,
        studentId:   enrolledStudent.studentId,
        checkInTime: attendance != null ? DateTime.fromMillisecondsSinceEpoch(attendance.timestamp) : null,
        status:      attendance == null
            ? CheckInStatus.notCheckedIn
            : attendance.status == 'PRESENT'
            ? CheckInStatus.present
            : CheckInStatus.late,
      );
    }).toList();

    // Count present and late
    final presentCount = students.where((s) => s.status == CheckInStatus.present).length;
    final lateCount = students.where((s) => s.status == CheckInStatus.late).length;

    state = state.copyWith(
      students:      students,
      presentCount:  presentCount,
      lateCount:     lateCount,
    );
  }

  // Tick every second to keep the countdown live
  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      // Auto-advance window
      final now = DateTime.now();
      if (state.window == SessionWindow.present &&
          now.isAfter(state.presentCutoff)) {
        state = state.copyWith(window: SessionWindow.late);
      } else if (state.window == SessionWindow.late &&
          now.isAfter(state.lateCutoff)) {
        state = state.copyWith(window: SessionWindow.ended);
        _ticker?.cancel();
      } else {
        // Force rebuild for countdown
        state = state.copyWith();
      }
    });
  }

  // Manual advance to late window
  void startLateWindow() {
    if (state.window != SessionWindow.present) return;
    state = state.copyWith(window: SessionWindow.late);
  }

  void updateSearch(String query) =>
      state = state.copyWith(searchQuery: query);

  void setFilter(CheckInStatus? status) {
    if (status == state.filterStatus) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(filterStatus: status);
    }
  }

  // TODO: replace with sessionNotifierProvider.notifier.endSession()
  Future<void> endSession(void Function() onEnded) async {
    _ticker?.cancel();
    state = state.copyWith(window: SessionWindow.ended);
    onEnded();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _attendanceSubscription?.cancel();
    super.dispose();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

class SessionSummaryState {
  final String            courseCode;
  final String            courseName;
  final DateTime          startedAt;
  final DateTime          endedAt;
  final int               presentCount;
  final int               lateCount;
  final int               enrolled;
  final List<StudentEntry> absentStudents;

  const SessionSummaryState({
    required this.courseCode,
    required this.courseName,
    required this.startedAt,
    required this.endedAt,
    required this.presentCount,
    required this.lateCount,
    required this.enrolled,
    required this.absentStudents,
  });

  int get absentCount => enrolled - presentCount - lateCount;

  /// Duration in minutes
  int get durationMinutes =>
      endedAt.difference(startedAt).inMinutes;

  /// Percentage of students present
  double get presentPercentage =>
      presentCount / enrolled;

  /// Percentage of students late
  double get latePercentage =>
      lateCount / enrolled;

  /// Percentage of students absent
  double get absentPercentage =>
      absentCount / enrolled;
}

final sessionControllerProvider = StateNotifierProvider.family<
    SessionController,
    ActiveSessionState,
    ({String sessionId,String courseCode, String courseName, int enrolled})>(
      (ref, params) => SessionController(
    db: ref.watch(appDatabaseProvider),
    sessionId:  params.sessionId,
    courseCode: params.courseCode,
    courseName: params.courseName,
    enrolled: params.enrolled,
  ),
);
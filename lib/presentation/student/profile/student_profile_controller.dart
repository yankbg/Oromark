// lib/presentation/student/profile/student_profile_controller.dart
//
// All state and logic for the student profile screen.
// Reads from the drift StudentProfiles and EnrolledStudents tables.
//
// HOW IT PLUGS IN
//   ProfileScreen is a ConsumerStatefulWidget.
//   It creates this controller in initState(), passing in the AppDatabase
//   obtained from ref.read(appDatabaseProvider).
//
// SUPABASE TODO
//   Once auth is wired, replace _kMockStudentId with the Supabase user's
//   studentId from the session, and call upsertStudentProfile() after sync.

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/database/app_database.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

/// Hardcoded for mock mode.
/// TODO: replace with Supabase auth: supabase.auth.currentUser?.userMetadata?['student_id']
const _kMockStudentId = 'U-2023-8841';

// ── View-model ────────────────────────────────────────────────────────────────

/// Flattened data the UI reads; built from drift rows so the screen
/// never imports drift types directly.
class StudentProfileViewModel {
  final String fullName;
  final String studentId;
  final String email;
  final String phone;
  final String yearLabel;
  final String department;
  final int enrolledCourseCount;

  const StudentProfileViewModel({
    required this.fullName,
    required this.studentId,
    required this.email,
    required this.phone,
    required this.yearLabel,
    required this.department,
    required this.enrolledCourseCount,
  });

  /// Initials used for the avatar fallback (e.g. "AR" from "Alex Rivera").
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class StudentProfileController extends ChangeNotifier {
  StudentProfileController({required AppDatabase db}) : _db = db {
    _subscribe();
  }

  final AppDatabase _db;

  // ── Public state ────────────────────────────────────────────────────────────

  bool isLoading = true;
  StudentProfileViewModel? profile;
  String? error;

  // ── Private ─────────────────────────────────────────────────────────────────

  StreamSubscription<Student?>? _profileSub;

  // ── Init ─────────────────────────────────────────────────────────────────────

  void _subscribe() {
    // watchStudentProfile gives us a live stream — if a Supabase sync writes a
    // new avatar URL the screen will repaint automatically, no manual refresh.
    _profileSub = _db
        .watchStudentProfile(_kMockStudentId)
        .listen(_onProfileRow, onError: _onError);
  }

  // ── Stream handler ────────────────────────────────────────────────────────────

  Future<void> _onProfileRow(Student? row) async {
    if (row == null) {
      // Profile row missing — shouldn't happen after seeding, but handle
      // gracefully so the screen shows something useful.
      profile = const StudentProfileViewModel(
        fullName:            'Loading…',
        studentId:           _kMockStudentId,
        email:               '',
        phone:               '',
        yearLabel:           '',
        department:          '',
        enrolledCourseCount: 0,
      );
      isLoading = false;
      notifyListeners();
      return;
    }

    // Fetch enrolled-course count alongside the profile row
    final courses = await _db.getCoursesForStudent(row.studentId);

    profile = StudentProfileViewModel(
      fullName:            row.studentName,
      studentId:           row.studentId,
      email:               row.studentEmail,
      phone:               row.phoneNumber ?? '',
      yearLabel:           row.yearOfStudy,
      department:          row.programme,
      enrolledCourseCount: courses.length,
    );

    isLoading = false;
    notifyListeners();
  }

  void _onError(Object err) {
    error     = 'Could not load profile: $err';
    isLoading = false;
    notifyListeners();
  }

  // ── Actions ──────────────────────────────────────────────────────────────────

  /// Manual refresh — useful for pull-to-refresh.
  /// In production this would trigger a Supabase re-fetch first.
  Future<void> refresh() async {
    isLoading = true;
    error     = null;
    notifyListeners();
    // The stream will fire again on its own; just wait for it.
    // For an immediate re-query without waiting for an emission:
    final row = await _db.getStudentProfile(_kMockStudentId);
    await _onProfileRow(row);
  }

  // ── Dispose ──────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }
}
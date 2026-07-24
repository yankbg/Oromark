// lib/presentation/student/home/student_home_controller.dart
//
// Owns every piece of mutable state for the student home screen.
// The screen itself (student_home_screen.dart) only calls methods and reads
// the exposed fields — no logic lives there.
//
// [MOCK] tags mark places a real UdpService / Riverpod provider will replace.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oromark/data/database/app_database.dart';
import 'package:oromark/data/services/attendace_submission_service.dart';
import 'package:oromark/data/services/udp_service.dart';
import 'package:oromark/providers/session_discovery_provider.dart';

// ── Detected session model ────────────────────────────────────────────────────
// Pure data; no Flutter dependency. Will be replaced by the domain entity
// from lib/domain/entities/session.dart when UdpService is wired.
class DetectedSession {
  final String sessionId;
  final String courseCode;
  final String courseName;
  final String lecturerName;
  final String room;
  final String roomCode;
  final DateTime presentCutoff;
  final DateTime lateCutoff;
  final String lecturerIP;
  final int lecturerPort;

  const DetectedSession({
    required this.sessionId,
    required this.courseCode,
    required this.courseName,
    required this.lecturerName,
    required this.room,
    required this.roomCode,
    required this.presentCutoff,
    required this.lateCutoff,
    required this.lecturerIP,
    required this.lecturerPort,
  });

  bool get isLate => DateTime.now().isAfter(presentCutoff);

  Duration get remaining {
    final cutoff = isLate ? lateCutoff : presentCutoff;
    final diff = cutoff.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isExpired => DateTime.now().isAfter(lateCutoff);
  @override
  String toString() => '$courseCode by $lecturerName ($roomCode)';
}

// ── Controller ────────────────────────────────────────────────────────────────
class StudentHomeController extends ChangeNotifier {
  StudentHomeController({
    required TickerProvider vsync,
    required UdpService udpService,
    AppDatabase? database,}): _db = database,
        _udpService = udpService {
    _initAnimations(vsync);
    _startListening(); // [MOCK] — replace with udpService.startListening()
    _startCountdownTicker();
  }
  final AppDatabase? _db;
  final UdpService _udpService;

  // ── Public state ────────────────────────────────────────────────────────────
  DetectedSession? session;
  bool confirmed = false;
  int navIndex = 0;

  // Submission state
  bool isSubmitting = false;
  String? submissionError;
  String? attendanceStatus; // PRESENT, LATE, ABSENT, or ERROR

  // Wave animation controllers — exposed so the screen can pass to widgets
  late final AnimationController wave1;
  late final AnimationController wave2;

  // ── Private ─────────────────────────────────────────────────────────────────
  Timer? _countdownTicker;

  // ── Init ─────────────────────────────────────────────────────────────────────
  void _initAnimations(TickerProvider vsync) {
    wave1 = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 3),
    )..repeat();

    wave2 = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 3),
    );
    // Stagger wave2 by 1.5 s so rings alternate
    Future.delayed(const Duration(milliseconds: 1500), () {
      wave2.repeat();
    });
  }

  // ── [MOCK] Simulates receiving a UDP broadcast after 2 s ──────────────────
  // void _startMockSession() {
  //   Future.delayed(const Duration(seconds: 2), () {
  //     final now = DateTime.now();
  //     session = DetectedSession(
  //       sessionId: 'mock-uuid-001',
  //       courseCode: 'CS301',
  //       courseName: 'Software Engineering',
  //       lecturerName: 'Dr. Henderson',
  //       room: 'A204',
  //       roomCode: 'ALPHA7',
  //       presentCutoff: now.add(const Duration(minutes: 8, seconds: 45)),
  //       lateCutoff: now.add(const Duration(minutes: 18, seconds: 45)),
  //       lecturerIP: '0.0.0.0',
  //       lecturerPort: 3000
  //     );
  //     notifyListeners();
  //   });
  // }
  Future<void> _startListening() async {
    try {
      await _udpService.startListening((sessionData) {
        final data = sessionData;

        final detected = DetectedSession(
          sessionId: data['sessionId'] as String,
          courseCode: data['courseCode'] as String,
          courseName: data['courseName'] as String,
          lecturerName: data['lecturerName'] as String,
          room: data['room'] as String,
          roomCode: data['roomCode'] as String,
          presentCutoff: DateTime.now().add(
            Duration(minutes: data['presentMinutes'] as int),
          ),
          lateCutoff: DateTime.now().add(
            Duration(minutes: data['lateMinutes'] as int),
          ),
          lecturerIP: data['lecturerIP'] as String,
          lecturerPort: data['lecturerPort'] as int,
        );

        session = detected;
        confirmed = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Failed to start UDP listener: $e');
    }
  }

  // Tick every second so the countdown in the card stays live
  void _startCountdownTicker() {
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (session != null && !confirmed) notifyListeners();
    });
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  void confirmAttendance() {
    confirmed = true;      // disables the button in home
    navIndex = 1;          // switch to History tab
    notifyListeners();
  }

  void setNavIndex(int i) {
    navIndex = i;
    notifyListeners();
  }

  /// Submit attendance via HTTP
  /// Called from ConfirmationScreen after user confirms
  Future<String> submitAttendance({
    required DetectedSession session,
    required String studentId,
  }) async {
    if (_db == null) {
      print('[StudentHomeController] Database not initialized');
      return 'ERROR';
    }

    try {
      isSubmitting = true;
      submissionError = null;
      notifyListeners();

      final service = AttendanceSubmissionService(_db!);
      final status = await service.submitAttendance(
        session: session,
        studentId: studentId,
      );

      isSubmitting = false;
      attendanceStatus = status;
      notifyListeners();

      return status;
    } catch (e) {
      isSubmitting = false;
      submissionError = e.toString();
      attendanceStatus = 'ERROR';
      notifyListeners();

      print('[StudentHomeController] Submission error: $e');
      return 'ERROR';
    }
  }

  /// Select a discovered session
  void selectSession(DetectedSession detectedSession) {
    session = detectedSession;
    confirmed = false;
    notifyListeners();
  }

  /// Clear current session
  void clearSession() {
    session = null;
    confirmed = false;
    submissionError = null;
    attendanceStatus = null;
    notifyListeners();
  }

  // ── Dispose ──────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    wave1.dispose();
    wave2.dispose();
    _countdownTicker?.cancel();
    super.dispose();
  }
}
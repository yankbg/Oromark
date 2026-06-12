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

  const DetectedSession({
    required this.sessionId,
    required this.courseCode,
    required this.courseName,
    required this.lecturerName,
    required this.room,
    required this.roomCode,
    required this.presentCutoff,
    required this.lateCutoff,
  });

  bool get isLate => DateTime.now().isAfter(presentCutoff);

  Duration get remaining {
    final cutoff = isLate ? lateCutoff : presentCutoff;
    final diff = cutoff.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  bool get isExpired => DateTime.now().isAfter(lateCutoff);
}

// ── Controller ────────────────────────────────────────────────────────────────
class StudentHomeController extends ChangeNotifier {
  StudentHomeController({required TickerProvider vsync}) {
    _initAnimations(vsync);
    _startMockSession(); // [MOCK] — replace with udpService.startListening()
    _startCountdownTicker();
  }

  // ── Public state ────────────────────────────────────────────────────────────
  DetectedSession? session;
  bool confirmed = false;
  int navIndex = 0;

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
  void _startMockSession() {
    Future.delayed(const Duration(seconds: 2), () {
      final now = DateTime.now();
      session = DetectedSession(
        sessionId: 'mock-uuid-001',
        courseCode: 'CS301',
        courseName: 'Software Engineering',
        lecturerName: 'Dr. Henderson',
        room: 'A204',
        roomCode: 'ALPHA7',
        presentCutoff: now.add(const Duration(minutes: 8, seconds: 45)),
        lateCutoff: now.add(const Duration(minutes: 18, seconds: 45)),
      );
      notifyListeners();
    });
  }

  // Tick every second so the countdown in the card stays live
  void _startCountdownTicker() {
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (session != null && !confirmed) notifyListeners();
    });
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  void confirmAttendance() {
    HapticFeedback.mediumImpact();
    confirmed = true;
    _countdownTicker?.cancel();
    // TODO: call ConfirmAttendanceUseCase → HTTP POST → local DB insert
    notifyListeners();
  }

  void setNavIndex(int i) {
    navIndex = i;
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
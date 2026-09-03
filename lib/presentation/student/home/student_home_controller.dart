// lib/presentation/student/home/student_home_controller.dart [UPDATED]
//
// Owns every piece of mutable state for the student home screen.
// The screen itself (student_home_screen.dart) only calls methods and reads
// the exposed fields — no logic lives there.
//
// [UPDATED] Removed _startListening() — the Riverpod provider handles UDP now
// This controller focuses on UI state (selected session, navigation, submission)

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
  final bool isLateFromBroadcast;
  // Whether the lecturer's device managed to start BLE advertising for
  // this session (see ble_service.dart) — false on hardware that can't
  // advertise (peripheral mode). Gates whether ConfirmationScreen requires
  // a BLE proximity match before submitting: it's never required when the
  // lecturer's own device couldn't put it up in the first place.
  final bool bleAvailable;

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
    this.isLateFromBroadcast = false,
    this.bleAvailable = false,
  });

  // Trust the lecturer's broadcast instead of computing this from the
  // present-window cutoff: the lecturer can manually switch to the late
  // window early (session_controller.startLateWindow()), and a locally
  // computed "now > presentCutoff" check has no way to see that early
  // switch — it only flips once the original cutoff time has passed.
  bool get isLate => isLateFromBroadcast;

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
    // required UdpService udpService,
    AppDatabase? database,
  }) : _db = database{
    _initAnimations(vsync);
    // ✅ [UPDATED] Removed _startListening()
    // The discoveredSessionsProvider in lib/providers/ handles UDP listening now
    _startCountdownTicker();
  }

  final AppDatabase? _db;
  // final UdpService _udpService;

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

  // ✅ [REMOVED] _startListening() method
  // The provider (discoveredSessionsProvider) handles UDP broadcast listening
  // instead. This keeps the controller focused on UI state, not networking.

  // When student_home_screen.dart opens the discovery sheet via:
  //   showModalBottomSheet(builder: (_) => SessionDiscoverySheet(...))
  // The sheet's _SessionList calls:
  //   final discoveredSessionsAsync = ref.watch(discoveredSessionsProvider);
  // This automatically starts the UDP listener via Riverpod's lifecycle management

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

  /// Persists a server-confirmed attendance result locally.
  /// Called from ConfirmationScreen after its own POST to the lecturer's
  /// server already succeeded and returned the authoritative status — this
  /// does not make its own network call, it only writes to this device's DB.
  Future<void> recordConfirmedAttendance({
    required DetectedSession session,
    required String studentId,
    required String status,
  }) async {
    if (_db == null) {
      print('[StudentHomeController] Database not initialized');
      attendanceStatus = 'ERROR';
      notifyListeners();
      return;
    }

    try {
      isSubmitting = true;
      submissionError = null;
      notifyListeners();

      await AttendanceSubmissionService(_db!).persistConfirmedAttendance(
        session: session,
        studentId: studentId,
        status: status,
      );

      isSubmitting = false;
      attendanceStatus = status;
      notifyListeners();
    } catch (e) {
      isSubmitting = false;
      submissionError = e.toString();
      attendanceStatus = 'ERROR';
      notifyListeners();

      print('[StudentHomeController] Failed to persist attendance locally: $e');
    }
  }

  /// Select a discovered session.
  /// Re-broadcasts of the same session (new UDP packets keep arriving while
  /// the lecturer's session is active) must not reset `confirmed` — only a
  /// genuinely different session should re-enable the Confirm button.
  void selectSession(DetectedSession detectedSession) {
    final isNewSession = session?.sessionId != detectedSession.sessionId;
    session = detectedSession;
    if (isNewSession) {
      confirmed = false;
    }
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
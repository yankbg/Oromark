  //The most important provider
  import 'package:oromark/core/utils/room_code_generator.dart';
import 'package:oromark/providers/attendance_submission_provider.dart';
  import 'package:uuid/uuid.dart';
  import 'dart:async';

  import '../core/constants/network_constants.dart';
  import '../domain/entities/session_state.dart';
  import '../data/database/app_database.dart';
  import '../providers/app_database_provider.dart';
  import '../providers/http_server_provider.dart';
  import '../providers/udp_service_provider.dart';
  import '../data/services/sync_service.dart';
  import '../providers/ble_service_provider.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';

  part 'session_notifier.g.dart';

  // This provider can auto-dispose (e.g. when the screen watching it
  // unmounts between sessions) — a disposed instance's own timers are
  // cancelled below so a stale one never fires against a later, unrelated
  // session. endSession() does NOT otherwise trust this instance's own
  // in-memory `state` for anything critical: a fresh/reset instance
  // (disposed-and-recreated, or any other cause of lost state) used to
  // make endSession() silently no-op — including never calling
  // stopBroadcasting() — because its state looked idle even though the
  // UDP broadcast (a separate, long-lived singleton) was still genuinely
  // running. endSession() below always stops the real services first,
  // unconditionally, and resolves which session it's ending from the
  // database as a fallback — so that failure mode can't recur regardless
  // of what this instance's own memory of things happens to be.
  @riverpod
  class SessionNotifier extends _$SessionNotifier {
    Timer? _presentIntervalTimer;
    Timer? _lateIntervalTimer;
    @override
    SessionState build() {
      ref.onDispose(() {
        _presentIntervalTimer?.cancel();
        _presentIntervalTimer = null;
        _lateIntervalTimer?.cancel();
        _lateIntervalTimer = null;
      });
      return SessionState.idle();
    }

    /// Starts a new attendance session
    ///
    /// Flow:
    /// 1. Generate session ID, room code, time windows
    /// 2. Start HTTP server (listens for submissions)
    /// 3. Start UDP broadcast (auto-discovers session on students)
    /// 4. Schedule Present → Late window transition
    /// 5. Schedule auto-absent computation at end
    ///
    /// Throws: Exception if WiFi not connected
  
    Future<String> startSession(String courseCode, String courseName, {required String roomCode}) async {
      print('[SESSION_NOTIFIER] startSession called: $courseCode - $courseName, room=$roomCode');
      // ← ADD THESE 5 LINES (cancel old timers)
      _presentIntervalTimer?.cancel();
      _presentIntervalTimer = null;
      _lateIntervalTimer?.cancel();
      _lateIntervalTimer = null;
      print('[SESSION_NOTIFIER] Cleaned up any previous timers');
      // final roomCode = roomCode;
      final sessionId = const Uuid().v4();
      print('[SESSION_NOTIFIER] sessionId generated: $sessionId');
      final now = DateTime.now();
  
      final presentCutoff =
      now.add(Duration(minutes: NetworkConstants.presentMinutes));
      final lateCutoff =
      now.add(Duration(minutes: NetworkConstants.lateMinutes));
  
      try{
        // Start HTTP server before setting state (fail-fast)
        await ref.read(httpServerProvider).startServer(
          sessionId: sessionId,
          roomCode: roomCode,
          presentCutoff: presentCutoff,
          lateCutoff: lateCutoff,
          db: ref.read(appDatabaseProvider),
        );
        final ip = ref.read(httpServerProvider).boundIp;
        if (ip == null || ip == '0.0.0.0') {
          // WiFi is not connected — abort session start
          state = SessionState.idle();
          throw Exception('Not connected to WiFi. Connect and try again.');
        }
        print('[SESSION_NOTIFIER] inserting session into DB...');
        // CRITICAL FIX: Insert session record to database
        final db = ref.read(appDatabaseProvider);
        await db.insertSession(
          SessionsCompanion.insert(
            sessionId: sessionId,
            courseCode: courseCode,
            courseName: courseName,
            roomCode: roomCode,
            startTime: now.millisecondsSinceEpoch,
            endTime: lateCutoff.millisecondsSinceEpoch,
            status: 'ACTIVE',
            createdAt: now.millisecondsSinceEpoch, presentCutoff: '', lateCutoff: '',
          ),
        );
        print('[SESSION_NOTIFIER] session inserted into DB');

        // Update notifier state
        state = SessionState.active(
          sessionId: sessionId,
          courseCode: courseCode,
          roomCode: roomCode,
          presentCutoff: presentCutoff,
          lateCutoff: lateCutoff,
        );

        // BLE proximity gate: advertise a short token derived from the
        // sessionId so students can verify they're actually near this
        // device, not just on the same Wi-Fi subnet. Attempted before the
        // broadcast payload is built so students are only told to require
        // the gate if advertising actually started — not every phone can
        // advertise (peripheral mode), and if it silently failed but the
        // payload still said "required", every student would fail it.
        final bleAvailable = await ref.read(bleServiceProvider).startAdvertising(sessionId);
        print('[SESSION_NOTIFIER] BLE advertising available: $bleAvailable');

        final payload = {
          'sessionId': sessionId,
          'courseCode': courseCode,
          'courseName': courseName,
          'roomCode': roomCode,
          'lecturerIP': ip,
          'lecturerPort': NetworkConstants.httpPort,
          'startTime': now.toIso8601String(),
          'endTime': lateCutoff.toIso8601String(),
          'isLate': false,
          'bleAvailable': bleAvailable,
        };
        print('[LECTURER] broadcast payload: $payload');
        print('[LECTURER] payload keys: ${payload.keys.toList()}');
        print('[LECTURER] port: ${NetworkConstants.udpPort}');

        // Start HTTP server for this session
        print('[SESSION_NOTIFIER] starting HTTP server...');
        await ref.read(localAttendanceServerProvider).start(
          sessionId: sessionId,
          port: NetworkConstants.httpPort,
          db: ref.read(appDatabaseProvider),
          presentCutoff: presentCutoff,
          lateCutoff: lateCutoff,
        );
        print('[SESSION_NOTIFIER] HTTP server started');

        // Start UDP broadcast (students auto-discover)
        print('[SESSION_NOTIFIER] starting UDP broadcast...');
        await ref.read(udpServiceProvider).startBroadcasting(payload);
        print('[SESSION_NOTIFIER] UDP broadcast started');

        // Future.delayed(Duration(minutes: NetworkConstants.presentMinutes), () {
        //   // Correct check inside a Notifier
        //   if (state.isIdle || state.isEnded) return;
        //   ref.read(udpServiceProvider).switchToLateInterval();
        // });
        _presentIntervalTimer = Timer(Duration(minutes: NetworkConstants.presentMinutes), () {
          if (state.isIdle || state.isEnded) return;
          print('[SESSION_NOTIFIER] Present interval timer fired - switching to late interval');
          // ref.read(udpServiceProvider).switchToLateInterval();
          switchToLateInterval();
        });

        // Future.delayed(Duration(minutes: NetworkConstants.lateMinutes), () async {
        //   if (state.isEnded) return;
        //   await endSession();
        // });

        // _lateIntervalTimer = Timer(Duration(minutes: NetworkConstants.lateMinutes), () async {
        //   if (state.isEnded) return;
        //   print('[SESSION_NOTIFIER] Late interval timer fired - auto-ending session');
        //   await endSession();
        // });
        print('[SESSION_NOTIFIER] UDP broadcast started');
        return sessionId;
      }catch(e, st){
        _presentIntervalTimer?.cancel();
        _presentIntervalTimer = null;
        _lateIntervalTimer?.cancel();
        _lateIntervalTimer = null;
        print('[SESSION_NOTIFIER] Cancelled timers due to error');
          // Cleanup on error
          state = SessionState.idle();
          await ref.read(httpServerProvider).stopServer();
          ref.read(udpServiceProvider).stopBroadcasting();
          await ref.read(bleServiceProvider).stopAdvertising();
          print('[SESSION_NOTIFIER] startSession error: $e');
          print('[SESSION_NOTIFIER] stack trace: $st');
          rethrow;

      }
    }
  /// Ends the session and computes absent records
  ///
  /// Flow:
  /// 1. Stop UDP broadcast
  /// 2. Stop HTTP server
  /// 3. Compute absent (LEFT JOIN enrolled vs submitted)
  /// 4. Update session status in database
  /// 5. Set state to ended

  
    Future<void> endSession() async {
      // Stop every live side effect first, unconditionally, before anything
      // else — these calls are all idempotent (a no-op if already stopped)
      // and must never be gated behind this notifier's own in-memory
      // `state`. That state is not a reliable signal of whether a session
      // is actually still broadcasting: it only reflects whatever this
      // notifier *remembers*, and this exact class of bug (a disposed-
      // and-recreated or otherwise-reset instance silently believing
      // nothing is active while UdpService/BleService/the HTTP server —
      // separate, long-lived singletons — keep right on running) is what
      // has twice now left a session broadcasting forever despite "End
      // Session" being tapped. So: always try to stop them, no guard.
      _presentIntervalTimer?.cancel();
      _presentIntervalTimer = null;
      _lateIntervalTimer?.cancel();
      _lateIntervalTimer = null;
      ref.read(udpServiceProvider).stopBroadcasting();
      await ref.read(bleServiceProvider).stopAdvertising();
      await ref.read(httpServerProvider).stopServer();
      await ref.read(localAttendanceServerProvider).stop();
      print('[SESSION_NOTIFIER] Stopped broadcast/advertising/servers unconditionally');

      // Resolve which session we're actually ending. Prefer this
      // notifier's own in-memory state; if that's unavailable for any
      // reason, fall back to the database's own ACTIVE row — written the
      // moment the session started, and a durable source of truth this
      // notifier's memory isn't.
      final db = ref.read(appDatabaseProvider);
      var sessionId = state.sessionId;
      var courseCode = state.courseCode;
      if (sessionId == null || courseCode == null) {
        final active = await db.getActiveSessions();
        if (active.isEmpty) {
          print('[SESSION_NOTIFIER] endSession(): no active session in memory or in the '
              'database — already stopped services defensively above, nothing further to do');
          state = SessionState.ended();
          return;
        }
        // Only ever one session runs at a time on this device; if that
        // were ever violated, ending the most recently started one is the
        // safest default.
        active.sort((a, b) => b.startTime.compareTo(a.startTime));
        sessionId = active.first.sessionId;
        courseCode = active.first.courseCode;
        print('[SESSION_NOTIFIER] endSession(): in-memory state had nothing active — '
            'resolved session $sessionId from the database instead');
      }

      // Ground-truth, DB-backed guard against redoing work for a session
      // that's already been finalized (the explicit button and the
      // auto-expiry ticker can both fire for the same session) — checked
      // against the session's actual stored status, not this notifier's
      // own state, for the same reason the teardown above doesn't trust it.
      final sessionRow = await db.getSessionById(sessionId);
      if (sessionRow != null && sessionRow.status == 'ENDED') {
        print('[SESSION_NOTIFIER] endSession(): session $sessionId is already ENDED in '
            'the database — skipping absent-computation/sync to avoid duplicate records');
        state = SessionState.ended();
        return;
      }

      try {
        // Update session status in database first — this must land
        // regardless of whether absent-computation below succeeds, since
        // it's what the sync below (and the admin dashboard) rely on to
        // know the session is over. A failure in absence-computation used
        // to short-circuit this write, leaving the session ACTIVE forever
        // in Neon/admin even though the lecturer's screen showed it ended.
        await db.updateSessionStatus(sessionId, 'ENDED');

        // Compute and insert absent records. Failure here must not block
        // the status write/sync — an absent-computation error shouldn't
        // leave the session stuck ACTIVE in Neon/admin.
        try {
          await _computeAbsent(sessionId: sessionId, courseCode: courseCode);
        } catch (e) {
          print('[BROADCAST_END] Error computing absences: $e');
        }

        // Back up this session to Neon the moment it's finalized, instead
        // of waiting for the app's next cold start — the lecturer is most
        // likely to still have Wi-Fi right now, and this is the highest-
        // value data to not lose if the phone is lost/wiped before then.
        // Fire-and-forget: never blocks the UI, no-ops if unconfigured or
        // offline (see sync_service.dart).
        unawaited(SyncService(db).syncNow());

        // Mark as ended
        state = SessionState.ended();
      }catch(e){
        print('[BROADCAST_END]Error ending session: $e');
        state = SessionState.ended(); // Mark as ended even if error
        rethrow;
      }

    }
    /// Computes absent records: LEFT JOIN enrolled vs submitted
    ///
    /// Logic:
    /// 1. Get all submissions for this session
    /// 2. Get all enrolled students for this course
    /// 3. Find gap: enrolled but not submitted
    /// 4. Insert ABSENT records for gap
    ///
    /// Side effect: Updates database with ABSENT records
    ///
    /// Takes sessionId/courseCode explicitly instead of reading `state` —
    /// endSession() may have resolved these from the database rather than
    /// from this notifier's own (possibly stale) state, and that resolved
    /// identity is the one that must be used here too.
    Future<void> _computeAbsent({
      required String sessionId,
      required String courseCode,
    }) async {
      final db = ref.read(appDatabaseProvider);
      List<EnrolledStudent> absentStudents;
      try {
        // Get all submitted students for this session
        final submitted = await db.getSessionAttendance(sessionId);
        final submittedIds = submitted.map((r) => r.studentId).toSet();
        // Get all enrolled students for this course
        final enrolled = await db.getEnrolledStudents(courseCode);

        // Find students who didn't submit (absent)
        absentStudents =
            enrolled.where((s) => !submittedIds.contains(s.studentId)).toList();
      } catch (e) {
        print('Error reading submitted/enrolled students for absent computation: $e');
        return;
      }

      // Insert ABSENT records one at a time, each in its own try/catch — a
      // single student's row failing (e.g. a leftover duplicate for a
      // courseCode/sessionId pair) used to throw out of the whole loop,
      // silently zeroing out every other absent student's record for that
      // session too (observed in Neon: sessions with a full roster but
      // zero ABSENT rows at all, even though nobody but one student had
      // actually submitted). Each insert is now independent so one bad
      // row can never cost the rest of the class their attendance record.
      var inserted = 0;
      for (final student in absentStudents) {
        try {
          await db.insertAttendance(
            AttendanceRecordsCompanion.insert(
              sessionId: sessionId,
              studentId: student.studentId,
              status: 'ABSENT',
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          );
          inserted++;
        } catch (e) {
          print('Error recording ABSENT for ${student.studentId}: $e');
        }
      }
      print(
        'Computed absent: $inserted/${absentStudents.length} absent records created '
            'for session $sessionId',
      );
    }
    void switchToLateInterval() {
      final currentState = state;
      if (!currentState.isActive) return;
      if (currentState.isIdle || currentState.isEnded) {
        print('[SESSION_NOTIFIER] Cannot switch to late interval: no active session');
        return;
      }

      // if (currentState.inLateWindow) {
      //   print('[SESSION_NOTIFIER] Already in late interval');
      //   return;
      // }

      // Update state to mark late window
      state = currentState.copyWith(isLate: true);
      // Tell UDP broadcaster to update payload and change interval
      ref.read(udpServiceProvider).switchToLateInterval();
      // Also pull the HTTP server's present cutoff to now, so a submission
      // arriving after this point is graded LATE instead of PRESENT.
      ref.read(localAttendanceServerProvider).markLateNow();

      print('[SESSION_NOTIFIER] Switched to late interval');
    }
  }
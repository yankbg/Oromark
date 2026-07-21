  //The most important provider
  import 'package:oromark/core/utils/room_code_generator.dart';
  import 'package:uuid/uuid.dart';
  
  import '../core/constants/network_constants.dart';
  import '../domain/entities/session_state.dart';
  import '../data/database/app_database.dart';
  import '../providers/app_database_provider.dart';
  import '../providers/http_server_provider.dart';
  import '../providers/udp_service_provider.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';
  
  part 'session_notifier.g.dart';
  
  @riverpod
  
  class SessionNotifier extends _$SessionNotifier {
    @override
    SessionState build() => SessionState.idle();

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
  
    Future<void> startSession(String courseCode, String courseName) async {
      final roomCode = generateRoomCode();
      final sessionId = const Uuid().v4();
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

        // Update notifier state
        state = SessionState.active(
          sessionId: sessionId,
          courseCode: courseCode,
          roomCode: roomCode,
          presentCutoff: presentCutoff,
          lateCutoff: lateCutoff,
        );
        // Start UDP broadcast (students auto-discover)
        await ref.read(udpServiceProvider).startBroadcasting({
          'sessionId': sessionId,
          'courseCode': courseCode,
          'courseName': courseName,
          'roomCode': roomCode,
          'lecturerIP': ip,
          'lecturerPort': NetworkConstants.httpPort,
          'startTime': now.toIso8601String(),
          'endTime': lateCutoff.toIso8601String(),
        });
        Future.delayed(Duration(minutes: NetworkConstants.presentMinutes), () {
          // Correct check inside a Notifier
          if (state.isIdle || state.isEnded) return;
          ref.read(udpServiceProvider).switchToLateInterval();
        });

        Future.delayed(Duration(minutes: NetworkConstants.lateMinutes), () async {
          if (state.isEnded) return;
          await endSession();
        });


      }catch(e){
          // Cleanup on error
          state = SessionState.idle();
          await ref.read(httpServerProvider).stopServer();
          ref.read(udpServiceProvider).stopBroadcasting();
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
      try{
        // Stop advertising new submissions
        ref.read(udpServiceProvider).stopBroadcasting();
        await ref.read(httpServerProvider).stopServer();

        // Compute and insert absent records
        await _computeAbsent();

        // Update session status in database
        final currentState = state;
        if (currentState.sessionId != null) {
          final db = ref.read(appDatabaseProvider);
          await db.updateSessionStatus(currentState.sessionId!, 'ENDED');
        }
        // Mark as ended
        state = SessionState.ended();
      }catch(e){
        print('Error ending session: $e');
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
    Future<void> _computeAbsent() async {
      final currentState = state;
      // Guard: must have valid session
      if (currentState.sessionId == null || currentState.courseCode == null) return;

      final db = ref.read(appDatabaseProvider);
      try{
        // Get all submitted students for this session
        final submitted = await db.getSessionAttendance(
          currentState.sessionId!,
        );
        final submittedIds = submitted.map((r) => r.studentId).toSet();
        // Get all enrolled students for this course
        final enrolled = await db.getEnrolledStudents(
          currentState.courseCode!,
        );

        // Find students who didn't submit (absent)
        final absentStudents =
        enrolled.where((s) => !submittedIds.contains(s.studentId));
        // Insert ABSENT records for each non-submitter
        for (final student in absentStudents) {
          await db.insertAttendance(
            AttendanceRecordsCompanion.insert(
              sessionId: currentState.sessionId!,
              studentId: student.studentId,
              status: 'ABSENT',
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
        print(
          'Computed absent: ${absentStudents.length} absent records created '
              'for session ${currentState.sessionId}',
        );
      }catch(e){
        print('Error computing absent records: $e');
        rethrow;
      }





      // for (final student in enrolled) {
      //   if (!submittedIds.contains(student.studentId)) {
      //     await db.insertAttendance(
      //       AttendanceRecordsCompanion.insert(
      //         sessionId:         currentState.sessionId!,
      //         studentId:         student.studentId,
      //         status:            'ABSENT',
      //         timestamp:         DateTime.now().millisecondsSinceEpoch,
      //       ),
      //     );
      //   }
      // }
    }
  }
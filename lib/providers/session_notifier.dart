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
  
    Future<void> startSession(String courseCode, String courseName) async {
      final roomCode = generateRoomCode();
      final sessionId = const Uuid().v4();
      final now = DateTime.now();
  
      final presentCutoff =
      now.add(Duration(minutes: NetworkConstants.presentMinutes));
      final lateCutoff =
      now.add(Duration(minutes: NetworkConstants.lateMinutes));
  

  
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

      state = SessionState.active(
        sessionId: sessionId,
        courseCode: courseCode,
        roomCode: roomCode,
        presentCutoff: presentCutoff,
        lateCutoff: lateCutoff,
      );
  
      await ref.read(udpServiceProvider).startBroadcasting({
        'sessionId': sessionId,
        'courseCode': courseCode,
        'courseName':  courseName,
        'roomCode': roomCode,
        'lecturerIP': ip,
        'lecturerPort': NetworkConstants.httpPort,
        'endTime':     lateCutoff.toIso8601String(),
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
    }
  
    Future<void> endSession() async {
       ref.read(udpServiceProvider).stopBroadcasting();
      await ref.read(httpServerProvider).stopServer();
      await _computeAbsent();
      state = SessionState.ended();
    }
    Future<void> _computeAbsent() async {
      final currentState = state;
      if (currentState.sessionId == null) return;

      final db = ref.read(appDatabaseProvider);

      final submitted = await db.getSessionAttendance(
        currentState.sessionId!,
      );
      final submittedIds = submitted.map((r) => r.studentId).toSet();

      final enrolled = await db.getEnrolledStudents(
        currentState.courseCode!,
      );

      for (final student in enrolled) {
        if (!submittedIds.contains(student.studentId)) {
          await db.insertAttendance(
            AttendanceRecordsCompanion.insert(
              sessionId:         currentState.sessionId!,
              studentId:         student.studentId,
              status:            'ABSENT',
              timestamp:         DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
      }
    }
  }
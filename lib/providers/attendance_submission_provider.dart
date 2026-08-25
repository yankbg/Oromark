// lib/providers/local_attendance_server_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oromark/data/services/AttendanceSubmissionService.dart';
import 'package:oromark/data/services/attendace_submission_service.dart';
import '../../../data/database/app_database.dart';
import 'app_database_provider.dart';
import '../../../core/constants/network_constants.dart';

final localAttendanceServerProvider = Provider<LocalAttendanceServer>((ref) {
  return LocalAttendanceServer();
});

extension LocalAttendanceServerX on LocalAttendanceServer {
  Future<void> startForSession({
    required Ref ref,
    required String sessionId,
    required DateTime presentCutoff,
    required DateTime lateCutoff,
  }) async {
    final db = ref.read(appDatabaseProvider);
    await start(
      sessionId: sessionId,
      port: NetworkConstants.httpPort,
      db: db,
      presentCutoff: presentCutoff,
      lateCutoff: lateCutoff,
    );
  }
}
import 'dart:convert';
import 'dart:io';
import '../../../data/database/app_database.dart';

class LocalAttendanceServer {
  HttpServer? _server;
  final Map<String, DateTime> _lastRequestAt = {}; // key: '$sessionId:$studentId'

  // CRITICAL FIX: Store cutoff times so we can compute status server-side
  DateTime? _presentCutoff;
  DateTime? _lateCutoff;

  Future<void> start({
    required String sessionId,
    required int port,
    required AppDatabase db,
    // CRITICAL FIX: Accept cutoff times from caller
    required DateTime presentCutoff,
    required DateTime lateCutoff,
  }) async {
    // CRITICAL FIX: Store the cutoff times
    _presentCutoff = presentCutoff;
    _lateCutoff = lateCutoff;

    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    final ip = _server!.address.address;
    print('[HTTP_SERVER] listening on http://$ip:$port');
    print('[HTTP_SERVER] Present cutoff: $_presentCutoff, Late cutoff: $_lateCutoff');

    // Start handling requests in the background; do NOT await this forever-loop here.
    _handleRequests(sessionId, db);
  }

  Future<void> _handleRequests(String sessionId, AppDatabase db) async {

    await for (final request in _server!) {
      if (request.method == 'POST' && request.uri.path == '/attendance') {
        try{
          final body = await utf8.decoder.bind(request).join();
          final data = jsonDecode(body) as Map<String, dynamic>;

          final receivedSessionId = data['sessionId'] as String?;
          final studentId = data['studentId'] as String?;
          // CRITICAL FIX: We no longer trust the status from the client
          // final status    = data['status'] as String?;

          if (receivedSessionId == null || studentId == null) {
            request.response
              ..statusCode = HttpStatus.badRequest
              ..write(jsonEncode({'ok': false, 'error': 'Missing fields'}));
            await request.response.close();
            continue;
          }

          // 1) Ensure sessionId matches current lecturer session
          if (receivedSessionId != sessionId) {
            request.response
              ..statusCode = HttpStatus.badRequest
              ..write(jsonEncode({'ok': false, 'error': 'Wrong sessionId'}));
            await request.response.close();
            continue;
          }

          final key = '$sessionId:$studentId';

          // 2) Simple rate limit: e.g. at most one request per 2 seconds per student
          final now = DateTime.now();
          final last = _lastRequestAt[key];
          if (last != null && now.difference(last) < const Duration(seconds: 2)) {
            request.response
              ..statusCode = HttpStatus.tooManyRequests
              ..write(jsonEncode({'ok': false, 'error': 'Too many requests'}));
            await request.response.close();
            continue;
          }
          _lastRequestAt[key] = now;

          // 3) Duplication check in DB: one attendance row per student/session
          final existing = await db.getAttendanceRecord(
            sessionId: sessionId,
            studentId: studentId,
          );
          if (existing != null) {
            request.response
              ..statusCode = HttpStatus.conflict
              ..write(jsonEncode({'ok': false, 'error': 'Already recorded'}));
            await request.response.close();
            continue;
          }

          // CRITICAL FIX: Compute status server-side based on submission time
          // Do NOT trust the client's status value
          final status = _computeAttendanceStatus(now);

          print('[HTTP_SERVER] Status computation: now=$now, presentCutoff=$_presentCutoff, lateCutoff=$_lateCutoff → status=$status');

          // 4) Insert attendance with SERVER-COMPUTED status
          await db.insertAttendance(
            AttendanceRecordsCompanion.insert(
              sessionId: sessionId,
              studentId: studentId,
              status:    status, // Computed on server, not from client
              timestamp: now.millisecondsSinceEpoch,
            ),
          );
          print('[HTTP_SERVER] attendance recorded: sessionId=$sessionId studentId=$studentId status=$status');

          request.response
            ..statusCode = HttpStatus.ok
            ..write(jsonEncode({
              'ok': true,
              'status': status, // Echo the server-computed status
              'message': status == 'PRESENT'
                  ? 'Attendance recorded as PRESENT'
                  : 'Attendance recorded as LATE'
            }));

          await request.response.close();

        }catch(e){
          print('[HTTP_SERVER] error handling attendance: $e');
          request.response
            ..statusCode = HttpStatus.internalServerError
            ..write(jsonEncode({'ok': false, 'error': '$e'}));
          await request.response.close();
        }

      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not found');
        await request.response.close();
      }
    }
  }

  /// CRITICAL FIX: Compute attendance status based on submission time
  /// Uses server-side cutoff times, not client data
  String _computeAttendanceStatus(DateTime submissionTime) {
    if (_presentCutoff == null || _lateCutoff == null) {
      print('[HTTP_SERVER] WARNING: Cutoff times not set, defaulting to LATE');
      return 'LATE';
    }

    // If submission is before present cutoff → PRESENT
    if (submissionTime.isBefore(_presentCutoff!)) {
      return 'PRESENT';
    }

    // If submission is before late cutoff → LATE
    if (submissionTime.isBefore(_lateCutoff!)) {
      return 'LATE';
    }

    // After late cutoff → session is probably ended, but record as LATE if somehow accepted
    return 'LATE';
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _presentCutoff = null;
    _lateCutoff = null;
    _lastRequestAt.clear();
    print('[HTTP_SERVER] stopped');
  }
}
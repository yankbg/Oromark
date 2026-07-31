import 'dart:convert';
import 'dart:io';
import '../../../data/database/app_database.dart';

class LocalAttendanceServer {
  HttpServer? _server;
  final Map<String, DateTime> _lastRequestAt = {}; // key: '$sessionId:$studentId'

  Future<void> start({
    required String sessionId,
    required int port,
    required AppDatabase db,
  }) async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    final ip = _server!.address.address;
    print('[HTTP_SERVER] listening on http://$ip:$port');

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
          final status    = data['status'] as String?;
          if (receivedSessionId == null || studentId == null || status == null) {
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

          // 4) Insert attendance
          await db.insertAttendance(
            AttendanceRecordsCompanion.insert(
              sessionId: sessionId,
              studentId: studentId,
              status:    status, // 'PRESENT' or 'LATE'
              timestamp: now.millisecondsSinceEpoch,
            ),
          );
          print('[HTTP_SERVER] attendance recorded: sessionId=$sessionId studentId=$studentId status=$status');

          request.response
            ..statusCode = HttpStatus.ok
            ..write(jsonEncode({'ok': true}));
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

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _lastRequestAt.clear();
    _lastRequestAt.clear();
    print('[HTTP_SERVER] stopped');
  }
}
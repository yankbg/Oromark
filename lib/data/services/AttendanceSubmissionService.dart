import 'dart:convert';
import 'dart:io';
import '../../../data/database/app_database.dart';

class LocalAttendanceServer {
  HttpServer? _server;

  Future<void> start(String ip, int port, AppDatabase db) async {
    _server = await HttpServer.bind(ip, port);
    print('[HTTP_SERVER] listening on http://$ip:$port');

    await for (final request in _server!) {
      if (request.method == 'POST' && request.uri.path == '/attendance') {
        final body = await utf8.decoder.bind(request).join();
        final data = jsonDecode(body) as Map<String, dynamic>;

        final sessionId = data['sessionId'] as String;
        final studentId = data['studentId'] as String;
        final status    = data['status'] as String;

        await db.insertAttendance(
          AttendanceRecordsCompanion.insert(
            sessionId: sessionId,
            studentId: studentId,
            status:    status,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );

        request.response
          ..statusCode = HttpStatus.ok
          ..write(jsonEncode({'ok': true}));
        await request.response.close();
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
  }
}
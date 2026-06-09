//The local HTTP server that runs on the lecturer's phone during sessions
import 'dart:io';
import 'package:oromark/core/constants/network_constants.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'dart:convert';

class HttpServerService{
  HttpServer? _server;

  Future<void> startServer(Function(Map<String, dynamic>) onAttendanceReceived) async{
    var handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler((request) async {
      if (request.method == 'POST' && request.url.path == 'attendance') {
        String body = await request.readAsString();
        Map<String, dynamic> data = jsonDecode(body);

        // Validate room code
        // Validate session not expired
        // Store attendance
        onAttendanceReceived(data);

        return Response.ok(jsonEncode({'status': 'recorded'}));
      }
      return Response.notFound('Not found');
    });
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, NetworkConstants.udpPort);
    print('Server running on port 5500');
  }
}
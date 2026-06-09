//The local HTTP server that runs on the lecturer's phone during sessions
import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import '../../core/constants/network_constants.dart';
import '../database/app_database.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';


class HttpServerService {
  HttpServer? _server;
  String? _activeSessionId;
  String? _activeRoomCode;
  DateTime? _presentCutoff;
  DateTime? _lateCutoff;
  AppDatabase? _db;

  // Track submissions per IP to prevent flooding
  final Map<String, int> _requestCount = {};
  // Track already-submitted students to prevent duplicates
  final Set<String> _submittedStudents = {};

  String? _boundIp;
  String? get boundIp => _boundIp;
  bool get isRunning => _server != null;

  Future<void> startServer({
    required String sessionId,
    required String roomCode,
    required DateTime presentCutoff,
    required DateTime lateCutoff,
    required AppDatabase db,
  }) async {
    if (_server != null) {
       await stopServer();
    }
    _activeSessionId = sessionId;
    _activeRoomCode = roomCode;
    _presentCutoff = presentCutoff;
    _lateCutoff = lateCutoff;
    _db = db;
    _requestCount.clear();
    _submittedStudents.clear();

    _boundIp = await _getLocalIp();

    var handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_handleRequest);

    _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        NetworkConstants.udpPort
    );
  }

  Future<Response> _handleRequest(Request request) async {
    if (request.method != 'POST' || request.url.path != 'attendance') {
      return Response.notFound('Not found');
    }

    //  Rate limiting
    final clientIp = request.headers['x-forwarded-for']
        ?? request.context['shelf.io.connection_info']
            .toString();
    _requestCount[clientIp] = (_requestCount[clientIp] ?? 0) + 1;
    if (_requestCount[clientIp]! > 6) {
      return Response(429, body: jsonEncode({
        'error': 'Too many requests'
      }));
    }

    // Safe JSON parsing
    Map<String, dynamic> data;
    try {
      final body = await request.readAsString();
      data = jsonDecode(body);
    } catch (e) {
      return Response(400, body: jsonEncode({
        'error': 'Invalid JSON'
      }));
    }

    // Required fields check
    final requiredFields = [
      'sessionId', 'studentId', 'roomCode',
       'timestamp'
    ];
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        return Response(400, body: jsonEncode({
          'error': 'Missing field: $field'
        }));
      }
    }

    // VALIDATION 1: Session ID
    if (data['sessionId'] != _activeSessionId) {
      return Response(403, body: jsonEncode({
        'error': 'Invalid session'
      }));
    }

    //  VALIDATION 2: Session not expired

    final now = DateTime.now();
    if (now.isAfter(_lateCutoff!)) {
      return Response(403, body: jsonEncode({
        'error': 'Session expired'
      }));
    }

    // VALIDATION 3: Room code
    if (data['roomCode'] != _activeRoomCode) {
      return Response(403, body: jsonEncode({
        'error': 'Wrong room code'
      }));
    }

    //  VALIDATION 4: Duplicate submission
    final studentId = data['studentId'] as String;
    if (_submittedStudents.contains(studentId)) {
      return Response(409, body: jsonEncode({
        'error': 'Already submitted'
      }));
    }

    // ── VALIDATION 5: Device fingerprint ─────────────────────
    // Brief never checks this — defeats the whole security model
    // final registeredFingerprint = await _db!
    //     .getRegisteredFingerprint(studentId);
    // if (registeredFingerprint == null ||
    //     registeredFingerprint != data['deviceFingerprint']) {
    //   return Response(403, body: jsonEncode({
    //     'error': 'Device not registered'
    //   }));
    // }

    //  PRESENT or LATE
    final status = now.isBefore(_presentCutoff!)
        ? 'PRESENT'
        : 'LATE';

    // ── STORE: Brief says "// Store attendance" but never does it
    try {
      await _db!.insertAttendance(
        AttendanceRecordsCompanion.insert(
          sessionId:         data['sessionId'] as String,
          studentId:         studentId,
          status:            status,
          timestamp:         now.millisecondsSinceEpoch,
        ),
      );
    } catch (e) {
      // Database write failed — tell the student to retry
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Failed to save record, please retry'
        }),
      );
    }

    // Mark student as submitted so duplicates are blocked
    _submittedStudents.add(studentId);

    // Return the actual status so the student app can show
    return Response.ok(jsonEncode({
      'status': status,
      'message': status == 'PRESENT'
          ? 'Attendance recorded'
          : 'Marked as late'
    }));
  }

  Future<void> stopServer() async {
    await _server?.close(force: true);
    _server = null;
    _activeSessionId = null;
    _activeRoomCode = null;
    _requestCount.clear();
    _submittedStudents.clear();
  }

  String _extractIp(Request request) {
    final info = request.context['shelf.io.connection_info'];
    if (info is io.HttpConnectionInfo) {
      return info.remoteAddress.address;
    }
    return 'unknown';
  }
  // Finds the phone's actual LAN IP on the campus WiFi
  Future<String> _getLocalIp() async {
    try {
      final interfaces = await io.NetworkInterface.list(
        type: io.InternetAddressType.IPv4,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          // Skip loopback (127.x) and link-local (169.x)
          if (!addr.isLoopback &&
              !addr.address.startsWith('169.254')) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '0.0.0.0';
  }
}
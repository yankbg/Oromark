// OROmark sync server.
//
// Sits between the mobile app and Neon Postgres. Holds the real Postgres
// connection string (NEON_DB_URL, server-side env var only — never shipped
// in the app) and exposes one API-key-guarded endpoint the app calls over
// HTTPS to push whatever local SQLite rows haven't been synced yet.
//
// This is NOT part of the live attendance flow — the lecturer/student UDP
// broadcast + local HTTP handshake stays entirely on the classroom LAN and
// keeps working with zero internet. This server only feeds the (future)
// web admin dashboard, and only after the fact, whenever a phone has real
// internet access.
//
// Run locally:
//   export NEON_DB_URL="postgresql://user:pass@host/db?sslmode=require"
//   export SYNC_API_KEY="pick-a-long-random-string"
//   dart run bin/server.dart

import 'dart:convert';
import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

Future<void> main() async {
  // Local dev convenience: loads server/.env if present. In real deployment
  // (Render/Fly/etc.) these are just set as real environment variables and
  // this load() call is a harmless no-op if no .env file exists.
  final env = DotEnv(includePlatformEnvironment: true)..load();

  final dbUrl = env['NEON_DB_URL'];
  final apiKey = env['SYNC_API_KEY'];

  if (dbUrl == null || dbUrl.isEmpty) {
    stderr.writeln('NEON_DB_URL is not set.');
    exit(1);
  }
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('SYNC_API_KEY is not set.');
    exit(1);
  }

  final pool = _openPool(dbUrl);
  print('Postgres pool ready.');

  final router = Router()
    ..get('/health', (Request req) => Response.ok('ok'))
    ..post('/sync', _handleSync(pool));

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_requireApiKey(apiKey))
      .addHandler(router.call);

  final port = int.tryParse(env['PORT'] ?? '8080') ?? 8080;
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('OROmark sync server listening on :${server.port}');
}

// A pool instead of a single long-lived Connection: Neon closes idle
// connections and Render's free tier cold-starts/sleeps, both of which
// would silently kill a single persistent connection with no way back.
// The pool opens a fresh underlying connection per request as needed.
Pool _openPool(String dbUrl) {
  final uri = Uri.parse(dbUrl);
  final userInfo = uri.userInfo.split(':');
  final endpoint = Endpoint(
    host: uri.host,
    port: uri.hasPort ? uri.port : 5432,
    database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'neondb',
    username: Uri.decodeComponent(userInfo[0]),
    password: Uri.decodeComponent(userInfo[1]),
  );
  return Pool.withEndpoints(
    [endpoint],
    settings: const PoolSettings(sslMode: SslMode.require),
  );
}

Middleware _requireApiKey(String expected) {
  return (Handler inner) {
    return (Request request) async {
      if (request.url.path == 'health') return inner(request);
      if (request.headers['x-api-key'] != expected) {
        return Response.forbidden(jsonEncode({'error': 'Invalid API key'}));
      }
      return inner(request);
    };
  };
}

Handler _handleSync(Session db) {
  return (Request request) async {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (e) {
      return Response(400, body: jsonEncode({'error': 'Invalid JSON: $e'}));
    }

    try {
      final counts = <String, int>{};

      counts['courses'] = await _upsertAll(db, (body['courses'] as List?) ?? [], _upsertCourse);
      counts['lecturers'] = await _upsertAll(db, (body['lecturers'] as List?) ?? [], _upsertLecturer);
      counts['students'] = await _upsertAll(db, (body['students'] as List?) ?? [], _upsertStudent);
      counts['enrolledStudents'] = await _upsertAll(db, (body['enrolledStudents'] as List?) ?? [], _upsertEnrolledStudent);
      counts['sessions'] = await _upsertAll(db, (body['sessions'] as List?) ?? [], _upsertSession);
      counts['attendanceRecords'] = await _upsertAll(db, (body['attendanceRecords'] as List?) ?? [], _upsertAttendanceRecord);

      return Response.ok(jsonEncode({'ok': true, 'synced': counts}));
    } catch (e, st) {
      stderr.writeln('Sync error: $e\n$st');
      return Response.internalServerError(body: jsonEncode({'error': '$e'}));
    }
  };
}

Future<int> _upsertAll(
  Session db,
  List rows,
  Future<void> Function(Session db, Map<String, dynamic> row) upsert,
) async {
  var count = 0;
  for (final row in rows) {
    await upsert(db, row as Map<String, dynamic>);
    count++;
  }
  return count;
}

Future<void> _upsertCourse(Session db, Map<String, dynamic> r) => db.execute(
  Sql.named('''
    insert into courses (course_code, course_name, course_group, enrolled, avg_attendance, lecturer_id)
    values (@courseCode, @courseName, @group, @enrolled, @avgAttendance, @lecturerId)
    on conflict (course_code) do update set
      course_name = excluded.course_name,
      course_group = excluded.course_group,
      enrolled = excluded.enrolled,
      avg_attendance = excluded.avg_attendance,
      lecturer_id = excluded.lecturer_id
  '''),
  parameters: {
    'courseCode': r['courseCode'],
    'courseName': r['courseName'],
    'group': r['group'],
    'enrolled': r['enrolled'] ?? 0,
    'avgAttendance': r['avgAttendance'] ?? 0,
    'lecturerId': r['lecturerId'],
  },
);

Future<void> _upsertLecturer(Session db, Map<String, dynamic> r) => db.execute(
  Sql.named('''
    insert into lecturers (lecturer_id, lecturer_name, lecturer_email, department)
    values (@lecturerId, @lecturerName, @lecturerEmail, @department)
    on conflict (lecturer_id) do update set
      lecturer_name = excluded.lecturer_name,
      lecturer_email = excluded.lecturer_email,
      department = excluded.department
  '''),
  parameters: {
    'lecturerId': r['lecturerId'],
    'lecturerName': r['lecturerName'],
    'lecturerEmail': r['lecturerEmail'],
    'department': r['department'],
  },
);

Future<void> _upsertStudent(Session db, Map<String, dynamic> r) => db.execute(
  Sql.named('''
    insert into students (student_id, student_name, student_email, phone_number, programme, year_of_study, avatar_url)
    values (@studentId, @studentName, @studentEmail, @phoneNumber, @programme, @yearOfStudy, @avatarUrl)
    on conflict (student_id) do update set
      student_name = excluded.student_name,
      student_email = excluded.student_email,
      phone_number = excluded.phone_number,
      programme = excluded.programme,
      year_of_study = excluded.year_of_study,
      avatar_url = excluded.avatar_url
  '''),
  parameters: {
    'studentId': r['studentId'],
    'studentName': r['studentName'],
    'studentEmail': r['studentEmail'],
    'phoneNumber': r['phoneNumber'],
    'programme': r['programme'],
    'yearOfStudy': r['yearOfStudy'],
    'avatarUrl': r['avatarUrl'],
  },
);

Future<void> _upsertEnrolledStudent(Session db, Map<String, dynamic> r) => db.execute(
  Sql.named('''
    insert into enrolled_students (student_id, course_code, full_name)
    values (@studentId, @courseCode, @fullName)
    on conflict (student_id, course_code) do update set
      full_name = excluded.full_name
  '''),
  parameters: {
    'studentId': r['studentId'],
    'courseCode': r['courseCode'],
    'fullName': r['fullName'],
  },
);

Future<void> _upsertSession(Session db, Map<String, dynamic> r) => db.execute(
  Sql.named('''
    insert into sessions (session_id, course_code, course_name, lecturer_name, room_code, start_time, end_time, present_cutoff, late_cutoff, status, created_at)
    values (@sessionId, @courseCode, @courseName, @lecturerName, @roomCode, @startTime, @endTime, @presentCutoff, @lateCutoff, @status, @createdAt)
    on conflict (session_id) do update set
      status = excluded.status,
      end_time = excluded.end_time
  '''),
  parameters: {
    'sessionId': r['sessionId'],
    'courseCode': r['courseCode'],
    'courseName': r['courseName'],
    'lecturerName': r['lecturerName'],
    'roomCode': r['roomCode'],
    'startTime': _msToDateTime(r['startTime']),
    'endTime': _msToDateTime(r['endTime']),
    'presentCutoff': r['presentCutoff'],
    'lateCutoff': r['lateCutoff'],
    'status': r['status'],
    'createdAt': _msToDateTime(r['createdAt']),
  },
);

Future<void> _upsertAttendanceRecord(Session db, Map<String, dynamic> r) => db.execute(
  Sql.named('''
    insert into attendance_records (session_id, student_id, status, "timestamp")
    values (@sessionId, @studentId, @status, @timestamp)
    on conflict (session_id, student_id) do update set
      status = excluded.status,
      "timestamp" = excluded."timestamp"
  '''),
  parameters: {
    'sessionId': r['sessionId'],
    'studentId': r['studentId'],
    'status': r['status'],
    'timestamp': _msToDateTime(r['timestamp']),
  },
);

DateTime _msToDateTime(dynamic ms) =>
    DateTime.fromMillisecondsSinceEpoch((ms as num).toInt(), isUtc: true);

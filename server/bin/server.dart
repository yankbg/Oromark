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
import 'dart:math';
import 'package:bcrypt/bcrypt.dart';
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
    ..post('/sync', _handleSync(pool))
    ..post('/auth/login', _rateLimited(_handleLogin(pool)))
    ..post('/auth/bootstrap-password', _handleBootstrapPassword(pool))
    ..get('/lecturer/courses', _lecturerCourses(pool));

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
      // /health is unauthenticated by design (uptime checks).
      // /auth/login is the end-user login endpoint — it's not the app
      // pushing sync data, so the sync API key doesn't apply there. It's
      // protected instead by its own per-IP/per-account rate limiting
      // (see _rateLimited / _handleLogin below).
      if (request.url.path == 'health') return inner(request);
      if (request.url.path == 'auth/login') return inner(request);
      if (request.headers['x-api-key'] != expected) {
        return Response.forbidden(jsonEncode({'error': 'Invalid API key'}));
      }
      return inner(request);
    };
  };
}

// ─────────────────────────────────────────────────────────────────────────
// Auth: POST /auth/login
//
// Real server-side login backed by Neon, replacing on-device-only SQLite
// auth. Takes a student/lecturer id-or-email + password, checks it against
// the bcrypt hash stored in Neon, and returns the user's profile plus an
// opaque session token on success.
//
// Response shapes:
//   200 {ok:true, role:'student'|'lecturer', profile:{...}, token:'...'}
//   401 {error:'invalid_password'}   — account exists, password is wrong
//   404 {error:'not_found'}          — no such student/lecturer in Neon yet
//                                       (lets the app fall back to local
//                                       SQLite for accounts that predate
//                                       this feature, per the app-side logic)
//   429 {error:'rate_limited'}       — too many attempts, try again later
// ─────────────────────────────────────────────────────────────────────────

// Simple in-memory sliding-window rate limiter, keyed by client IP + the
// identifier being attempted (so one IP can't hammer one account, and
// distributed attempts against many accounts from one IP are also capped).
// This is a single-process server with no shared state store, so in-memory
// is the pragmatic choice here — it resets on redeploy, which is fine for
// brute-force mitigation purposes.
class _RateLimiter {
  final int maxAttempts;
  final Duration window;
  final _hits = <String, List<DateTime>>{};

  _RateLimiter({required this.maxAttempts, required this.window});

  bool allow(String key) {
    final now = DateTime.now();
    final hits = _hits.putIfAbsent(key, () => []);
    hits.removeWhere((t) => now.difference(t) > window);
    if (hits.length >= maxAttempts) return false;
    hits.add(now);
    return true;
  }
}

final _loginRateLimiter = _RateLimiter(
  maxAttempts: 8,
  window: const Duration(minutes: 5),
);

Handler _rateLimited(Handler inner) {
  return (Request request) async {
    final ip = request.headers['x-forwarded-for']?.split(',').first.trim() ??
        (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)
            ?.remoteAddress
            .address ??
        'unknown';

    // Peek at the identifier being attempted without consuming the body
    // twice — read it once here and re-attach it for the real handler.
    final bodyStr = await request.readAsString();
    Map<String, dynamic> body;
    try {
      body = jsonDecode(bodyStr) as Map<String, dynamic>;
    } catch (_) {
      body = {};
    }
    final identifier =
        (body['id'] ?? body['email'] ?? body['studentId'] ?? body['lecturerId'] ?? '')
            .toString()
            .toLowerCase();

    final key = '$ip::$identifier';
    if (!_loginRateLimiter.allow(key) || !_loginRateLimiter.allow(ip)) {
      return Response(
        429,
        body: jsonEncode({'error': 'rate_limited', 'message': 'Too many attempts. Try again later.'}),
      );
    }

    final newRequest = request.change(body: bodyStr);
    return inner(newRequest);
  };
}

Handler _handleLogin(Session db) {
  return (Request request) async {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (e) {
      return Response(400, body: jsonEncode({'error': 'Invalid JSON: $e'}));
    }

    final rawId = (body['id'] ?? body['studentId'] ?? body['lecturerId'] ?? body['email'])?.toString().trim();
    final password = body['password']?.toString();
    final roleHint = body['role']?.toString(); // 'student' | 'lecturer' | null

    if (rawId == null || rawId.isEmpty || password == null || password.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'id and password are required'}));
    }

    try {
      if (roleHint != 'lecturer') {
        final rows = await db.execute(
          Sql.named('''
            select student_id, student_name, student_email, phone_number, programme, year_of_study, avatar_url, password_hash
            from students
            where student_id = @id or student_email = @id
            limit 1
          '''),
          parameters: {'id': rawId},
        );
        if (rows.isNotEmpty) {
          final row = rows.first;
          final hash = row[7] as String?;
          if (hash == null || hash.isEmpty) {
            return Response(404, body: jsonEncode({'error': 'not_found', 'message': 'No password set for this account yet.'}));
          }
          if (!BCrypt.checkpw(password, hash)) {
            return Response(401, body: jsonEncode({'error': 'invalid_password'}));
          }
          final token = _issueToken(role: 'student', id: row[0] as String);
          return Response.ok(jsonEncode({
            'ok': true,
            'role': 'student',
            'profile': {
              'studentId': row[0],
              'studentName': row[1],
              'studentEmail': row[2],
              'phoneNumber': row[3],
              'programme': row[4],
              'yearOfStudy': row[5],
              'avatarUrl': row[6],
            },
            'token': token,
          }));
        }
      }

      if (roleHint != 'student') {
        final rows = await db.execute(
          Sql.named('''
            select lecturer_id, lecturer_name, lecturer_email, department, password_hash
            from lecturers
            where lecturer_id = @id or lecturer_email = @id
            limit 1
          '''),
          parameters: {'id': rawId},
        );
        if (rows.isNotEmpty) {
          final row = rows.first;
          final hash = row[4] as String?;
          if (hash == null || hash.isEmpty) {
            return Response(404, body: jsonEncode({'error': 'not_found', 'message': 'No password set for this account yet.'}));
          }
          if (!BCrypt.checkpw(password, hash)) {
            return Response(401, body: jsonEncode({'error': 'invalid_password'}));
          }
          final token = _issueToken(role: 'lecturer', id: row[0] as String);
          return Response.ok(jsonEncode({
            'ok': true,
            'role': 'lecturer',
            'profile': {
              'lecturerId': row[0],
              'lecturerName': row[1],
              'lecturerEmail': row[2],
              'department': row[3],
            },
            'token': token,
          }));
        }
      }

      return Response(404, body: jsonEncode({'error': 'not_found'}));
    } catch (e, st) {
      stderr.writeln('Login error: $e\n$st');
      return Response.internalServerError(body: jsonEncode({'error': '$e'}));
    }
  };
}

// Opaque session tokens: a random 32-byte hex string held in-memory with
// an expiry. Simpler than wiring up JWT signing/verification for a single
// small server, at the cost of tokens not surviving a redeploy — acceptable
// for this app, where the token is a soft "stay logged in" convenience and
// every screen's actual data access is already gated by local SQLite /
// the LAN-only attendance flow, not by this token.
final _tokens = <String, _TokenInfo>{};
final _rand = Random.secure();

class _TokenInfo {
  final String role;
  final String id;
  final DateTime expiresAt;
  _TokenInfo(this.role, this.id, this.expiresAt);
}

String _issueToken({required String role, required String id}) {
  final bytes = List<int>.generate(32, (_) => _rand.nextInt(256));
  final token = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  _tokens[token] = _TokenInfo(role, id, DateTime.now().add(const Duration(days: 30)));
  return token;
}

// ─────────────────────────────────────────────────────────────────────────
// POST /auth/bootstrap-password
//
// Lets the app push a hash for an existing local-only account (the 4 seeded
// students + 1 lecturer that only ever lived in on-device SQLite, from
// before Neon had a password column at all) the first time that account
// logs in successfully on-device. Guarded by the same X-Api-Key as /sync —
// this is the app talking to its own backend, not an end-user login
// attempt, so the login endpoint's separate rate limiting doesn't apply.
//
// Never overwrites an existing hash (e.g. one an admin set through the
// dashboard) — only fills it in if it's currently null, so this can't be
// used to hijack an account that already has a real password.
// ─────────────────────────────────────────────────────────────────────────
Handler _handleBootstrapPassword(Session db) {
  return (Request request) async {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (e) {
      return Response(400, body: jsonEncode({'error': 'Invalid JSON: $e'}));
    }

    final role = body['role']?.toString();
    final id = body['id']?.toString().trim();
    final password = body['password']?.toString();

    if (role != 'student' && role != 'lecturer') {
      return Response(400, body: jsonEncode({'error': "role must be 'student' or 'lecturer'"}));
    }
    if (id == null || id.isEmpty || password == null || password.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'id and password are required'}));
    }

    final hash = BCrypt.hashpw(password, BCrypt.gensalt());

    try {
      final table = role == 'student' ? 'students' : 'lecturers';
      final idCol = role == 'student' ? 'student_id' : 'lecturer_id';
      final result = await db.execute(
        Sql.named('''
          update $table set password_hash = @hash
          where $idCol = @id and password_hash is null
        '''),
        parameters: {'hash': hash, 'id': id},
      );
      return Response.ok(jsonEncode({'ok': true, 'updated': result.affectedRows}));
    } catch (e, st) {
      stderr.writeln('Bootstrap-password error: $e\n$st');
      return Response.internalServerError(body: jsonEncode({'error': '$e'}));
    }
  };
}

// ─────────────────────────────────────────────────────────────────────────
// GET /lecturer/courses?id=<lecturerId>
//
// Sync so far has only ever pushed device SQLite -> Neon (SyncService,
// POST /sync). Nothing ever came back down, so a course created straight
// in Neon via the admin dashboard was invisible to the lecturer's phone
// forever. This is the other direction: the app calls this right after a
// lecturer logs in over the network, to pull down exactly the courses
// assigned to them (plus each course's enrolled-student roster, since the
// session-start screen needs enrollment counts) and cache them locally.
//
// The lecturer id is a query parameter rather than a path segment (the
// previous /lecturer/<id>/courses shape) because lecturer ids use the
// "IUEA/LEC/NNN" convention — a literal "/" inside a path segment is
// fragile to route match even percent-encoded, and would 404 against
// this exact server/router combination.
Handler _lecturerCourses(Session db) {
  return (Request request) async {
    final id = request.url.queryParameters['id'];
    if (id == null || id.isEmpty) {
      return Response(400, body: jsonEncode({'error': 'id query parameter is required'}));
    }
    try {
      final courseRows = await db.execute(
        Sql.named('''
          select course_code, course_name, course_group, enrolled, avg_attendance, lecturer_id
          from courses
          where lecturer_id = @id
          order by course_code
        '''),
        parameters: {'id': id},
      );

      final courses = courseRows
          .map((r) => {
                'courseCode': r[0],
                'courseName': r[1],
                'group': r[2],
                'enrolled': r[3],
                'avgAttendance': r[4],
                'lecturerId': r[5],
              })
          .toList();

      final courseCodes = courses.map((c) => c['courseCode'] as String).toList();

      List<Map<String, dynamic>> enrolledStudents = [];
      if (courseCodes.isNotEmpty) {
        final rosterRows = await db.execute(
          Sql.named('''
            select student_id, course_code, full_name
            from enrolled_students
            where course_code = any(@codes)
          '''),
          parameters: {'codes': TypedValue(Type.textArray, courseCodes)},
        );
        enrolledStudents = rosterRows
            .map((r) => {
                  'studentId': r[0],
                  'courseCode': r[1],
                  'fullName': r[2],
                })
            .toList();
      }

      return Response.ok(jsonEncode({
        'ok': true,
        'courses': courses,
        'enrolledStudents': enrolledStudents,
      }));
    } catch (e, st) {
      stderr.writeln('Lecturer-courses error: $e\n$st');
      return Response.internalServerError(body: jsonEncode({'error': '$e'}));
    }
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

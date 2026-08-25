import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database/app_database.dart';
import '../data/models/auth_result.dart';
import '../data/services/sync_service.dart';
import 'package:oromark/providers/app_database_provider.dart';

part 'login_provider.g.dart';

/// Login is now network-first, backed by the sync server's POST
/// /auth/login (itself backed by Neon), with on-device SQLite as an
/// offline/degraded fallback — see the docstring on each branch below for
/// exactly when each path is taken. This does NOT touch the live
/// UDP-broadcast / local-HTTP attendance flow, which stays fully offline
/// and unaffected.
@riverpod
class LoginController extends _$LoginController {
  @override
  FutureOr<void> build() {}

  Future<AuthResult> login({
    String? studentId,
    String? email,
    required String password,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final id = (studentId ?? email ?? '').trim();
    final roleHint = studentId != null ? 'student' : null; // email alone is ambiguous (student or lecturer)

    final network = await _tryNetworkLogin(id: id, password: password, roleHint: roleHint);

    switch (network.outcome) {
      case _NetworkOutcome.success:
        final result = network.result!;
        await _cacheLocally(db, result, password);
        return result;

      case _NetworkOutcome.wrongPassword:
        // The account exists in Neon and the server is reachable — Neon is
        // authoritative once an account has a password there, so we do NOT
        // fall back to a (possibly stale/different) local password.
        throw Exception('Invalid credentials');

      case _NetworkOutcome.notFound:
        // Reachable, but this id has no password set in Neon yet — either
        // it's one of the pre-existing local-only accounts that predates
        // the password_hash column, or it genuinely doesn't exist anywhere.
        // Fall back to local SQLite; if that succeeds, opportunistically
        // bootstrap the password to Neon since we know we have internet.
        final local = await db.loginLocal(studentId: studentId, email: email, password: password);
        if (local == null) throw Exception('Invalid credentials');
        unawaited(SyncService(db).pushPasswordBootstrap(
          isLecturer: local.department != null,
          id: local.userId,
          password: password,
        ));
        return local;

      case _NetworkOutcome.unreachable:
        // No internet (or the sync server is down). Degrade gracefully:
        // a device that has logged in before has a cached local row and
        // can keep working offline; a brand-new dashboard-provisioned
        // account has never touched this device and has no local row —
        // for that one, network is genuinely required, and we say so.
        final local = await db.loginLocal(studentId: studentId, email: email, password: password);
        if (local != null) return local;

        final hasLocalAccount = await _hasAnyLocalAccountFor(db, studentId: studentId, email: email);
        if (hasLocalAccount) {
          // Local account exists but this password doesn't match it.
          throw Exception('Invalid credentials');
        }
        throw Exception(
          'No internet connection. This account has never signed in on this '
          'device before, so an internet connection is required for its '
          'first login.',
        );
    }
  }

  Future<bool> _hasAnyLocalAccountFor(AppDatabase db, {String? studentId, String? email}) async {
    if (studentId != null && studentId.isNotEmpty) {
      final s = await db.getStudentProfile(studentId);
      if (s != null) return true;
    }
    if (email != null && email.isNotEmpty) {
      final students = await db.getAllStudents();
      if (students.any((s) => s.studentEmail == email)) return true;
      final lecturers = await db.getAllLecturers();
      if (lecturers.any((l) => l.lecturerEmail == email)) return true;
    }
    return false;
  }

  Future<void> _cacheLocally(AppDatabase db, AuthResult result, String plaintextPassword) async {
    // Cached with the plaintext password the user just typed, matching the
    // existing (pre-existing, out-of-scope-to-fix) local SQLite scheme —
    // this is what makes the offline-fallback path above work for this
    // device on subsequent logins without internet.
    if (result.department != null) {
      await db.upsertLecturerProfile(LecturersCompanion.insert(
        lecturerId: result.userId,
        lecturerName: result.fullname,
        lecturerEmail: result.email,
        department: result.department!,
        password: plaintextPassword,
      ));
    } else {
      await db.upsertStudentProfile(StudentsCompanion.insert(
        studentId: result.userId,
        studentName: result.fullname,
        studentEmail: result.email,
        phoneNumber: '', // not returned by the server profile; left as-is if a local row already had one
        programme: result.program ?? '',
        yearOfStudy: result.yearOfStudy ?? '',
        password: plaintextPassword,
      ));
    }
  }

  Future<_NetworkLoginAttempt> _tryNetworkLogin({
    required String id,
    required String password,
    String? roleHint,
  }) async {
    final apiUrl = dotenv.env['SYNC_API_URL'];
    if (apiUrl == null || apiUrl.isEmpty || id.isEmpty) {
      return const _NetworkLoginAttempt(_NetworkOutcome.unreachable);
    }

    try {
      final response = await http
          .post(
            Uri.parse('$apiUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': id,
              'password': password,
              if (roleHint != null) 'role': roleHint,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final role = body['role'] as String;
        final profile = body['profile'] as Map<String, dynamic>;
        final token = body['token'] as String?;

        final result = role == 'lecturer'
            ? AuthResult.lecturer(
                fullname: profile['lecturerName'] as String,
                userId: profile['lecturerId'] as String,
                email: profile['lecturerEmail'] as String,
                department: profile['department'] as String,
                token: token,
              )
            : AuthResult.student(
                fullname: profile['studentName'] as String,
                userId: profile['studentId'] as String,
                email: profile['studentEmail'] as String,
                program: profile['programme'] as String?,
                yearOfStudy: profile['yearOfStudy'] as String?,
                token: token,
              );
        return _NetworkLoginAttempt(_NetworkOutcome.success, result: result);
      }

      if (response.statusCode == 401) {
        return const _NetworkLoginAttempt(_NetworkOutcome.wrongPassword);
      }
      if (response.statusCode == 404) {
        return const _NetworkLoginAttempt(_NetworkOutcome.notFound);
      }
      // Any other status (429 rate-limited, 500, etc.) — treat like
      // unreachable so the user isn't blocked purely by a server hiccup;
      // local fallback still applies if this device has logged in before.
      return const _NetworkLoginAttempt(_NetworkOutcome.unreachable);
    } catch (e) {
      // No internet, DNS failure, timeout, server down, etc.
      return const _NetworkLoginAttempt(_NetworkOutcome.unreachable);
    }
  }
}

enum _NetworkOutcome { success, wrongPassword, notFound, unreachable }

class _NetworkLoginAttempt {
  final _NetworkOutcome outcome;
  final AuthResult? result;
  const _NetworkLoginAttempt(this.outcome, {this.result});
}

//  ...lib/data/models/auth_result

class AuthResult {
  final String fullname;
  final String userId;
  final String email;
  final String? program;
  final String? yearOfStudy;
  final String? department;

  /// Opaque session token from the sync server's POST /auth/login, when the
  /// login went over the network. Null when this AuthResult came from a
  /// local-only SQLite fallback login (no internet, or a not-yet-bootstrapped
  /// account) — nothing in the app currently requires this to be non-null,
  /// it's just carried along for whenever a future screen needs to call an
  /// authenticated sync-server endpoint on the user's behalf.
  final String? token;

  AuthResult.lecturer({
    required this.fullname,
    required this.userId,
    required this.email,
    required this.department,
    this.token,
  }): program     = null,
      yearOfStudy = null;

  AuthResult.student({
    required this.fullname,
    required this.userId,
    required this.email,
    required this.program,
    required this.yearOfStudy,
    this.token,
  }): department = null;

  bool get isLecturer => department != null;
}

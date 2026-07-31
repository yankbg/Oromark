//  ...lib/data/models/auth_result

class AuthResult {
  final String fullname;
  final String userId;
  final String email;
  final String? program;
  final String? yearOfStudy;
  final String? department;

  AuthResult.lecturer({
    required this.fullname,
    required this.userId,
    required this.email,
    required this.department
  }): program     = null,
      yearOfStudy = null;

  AuthResult.student({
    required this.fullname,
    required this.userId,
    required this.email,
    required this.program,
    required this.yearOfStudy
  }): department = null;
}
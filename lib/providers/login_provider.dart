import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/auth_result.dart';
import 'package:oromark/providers/app_database_provider.dart';

part 'login_provider.g.dart';

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

    final localResult = await db.login(
      studentId: studentId,
      email: email,
      password: password,
    );

    if (localResult != null) {
      return localResult;
    }

    throw Exception('Invalid credentials');
  }
}
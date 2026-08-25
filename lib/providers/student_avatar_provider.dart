// lib/providers/student_avatar_provider.dart
//
// A single reactive source of the logged-in student's profile row, shared
// by the home, history, and profile screens so their header avatars stay
// in sync with each other the moment the picture changes — no manual
// refresh, no passing the URL through navigation arguments.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import 'app_database_provider.dart';
import 'auth_state_provider.dart';

final studentAvatarProvider = StreamProvider.autoDispose<Student?>((ref) {
  final studentId = ref.watch(authStateNotifierProvider).value?.userId;
  if (studentId == null || studentId.isEmpty) {
    return Stream.value(null);
  }
  final db = ref.watch(appDatabaseProvider);
  return db.watchStudentProfile(studentId);
});

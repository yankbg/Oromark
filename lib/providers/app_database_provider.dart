import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  // You might want to keep a single instance for the whole app:
  final db = AppDatabase();
  ref.onDispose(db.close); // optional: close when no longer used
  return db;
});
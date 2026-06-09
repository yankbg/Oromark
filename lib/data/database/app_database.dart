//The database itself. Created once, injected everywhere via Riverpod
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Sessions, AttendanceRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Watch attendance for a session (reactive — updates UI live)
  Stream<List<AttendanceRecord>> watchSessionAttendance(String sessionId) {
    return (select(attendanceRecords)
      ..where((a) => a.sessionId.equals(sessionId)))
        .watch();
  }

  // Get all unsynced records
  Future<List<AttendanceRecord>> getUnsynced() {
    return (select(attendanceRecords)
      ..where((a) => a.synced.equals(false)))
        .get();
  }
  Future<int> insertAttendance(AttendanceRecordsCompanion entry) {
    return into(attendanceRecords).insert(entry);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'oromark.db'));
    return NativeDatabase(file);
  });
}
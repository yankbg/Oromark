//The database itself. Created once, injected everywhere via Riverpod
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Sessions, AttendanceRecords, EnrolledStudents])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // Runs only on fresh install — creates all tables
    onCreate: (m) async {
      await m.createAll();
    },

    // Version 1 → 2: add enrolled_students table
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(enrolledStudents);
      }
    },

    // Runs after every migration — good place for integrity checks
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

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
  // Count only — used for the live number on lecturer dashboard
  Stream<int> watchAttendanceCount(String sessionId) {
    return watchSessionAttendance(sessionId).map(
          (records) => records.length,
    );
  }
  // Separate counts for PRESENT and LATE
  Stream<Map<String, int>> watchStatusCounts(String sessionId) {
    return watchSessionAttendance(sessionId).map((records) {
      return {
        'present': records.where((r) => r.status == 'PRESENT').length,
        'late':    records.where((r) => r.status == 'LATE').length,
        'absent':  records.where((r) => r.status == 'ABSENT').length,
      };
    });
  }
  Future<List<EnrolledStudent>> getEnrolledStudents(
      String courseCode,
      ) async {
    return (select(enrolledStudents)
      ..where((s) => s.courseCode.equals(courseCode)))
        .get();
  }
  // Returns all records for a session — used by _computeAbsent
  Future<List<AttendanceRecord>> getSessionAttendance(
      String sessionId,
      ) async {
    return (select(attendanceRecords)
      ..where((r) => r.sessionId.equals(sessionId)))
        .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'oromark.db'));
    return NativeDatabase(file);
  });
}
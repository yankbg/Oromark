//Defines the shape of your local SQLite tables using drift's Dart classes
import 'package:drift/drift.dart';

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text().unique()();
  TextColumn get courseCode => text()();
  TextColumn get courseName => text()();
  TextColumn get lecturerName => text().nullable()();
  TextColumn get roomCode => text()();
  IntColumn get startTime => integer()();  // unix timestamp
  IntColumn get endTime => integer()();
  TextColumn get presentCutoff => text()();
  TextColumn get lateCutoff => text()();
  TextColumn get status => text()();       // ACTIVE, ENDED
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
}

class AttendanceRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sessionId => text()();
  TextColumn get studentId => text()();
  TextColumn get status => text()();       // PRESENT, LATE, ABSENT
  IntColumn get timestamp => integer()();
  // TextColumn get deviceFingerprint => text()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}
class EnrolledStudents extends Table {
  IntColumn get id                => integer().autoIncrement()();
  TextColumn get studentId        => text()();
  TextColumn get courseCode       => text()();
  TextColumn get fullName         => text()();
  TextColumn get deviceFingerprint => text()();
}

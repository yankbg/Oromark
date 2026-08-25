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
  // TextColumn get deviceFingerprint => text()();
}
class Students extends Table {
  IntColumn get id            => integer().autoIncrement()();
  TextColumn get studentId    => text().unique()(); //eg:23/124/bsc
  TextColumn get studentName  => text()();
  TextColumn get studentEmail => text().unique()();
  TextColumn get phoneNumber  => text()();
  TextColumn get programme    => text()();  //Computer Science, civil engineering,...
  TextColumn get yearOfStudy  => text()();
  TextColumn get password     => text()();
  TextColumn get avatarUrl    => text().nullable()(); // Cloudinary secure_url
}
class Lecturers extends Table {
  IntColumn get id               => integer().autoIncrement()();
  TextColumn get lecturerId     => text().unique()();
  TextColumn get lecturerName    => text()();
  TextColumn get lecturerEmail   => text()();
  TextColumn get department      => text()();
  TextColumn get password        => text()();
}
class Courses extends Table {
  IntColumn get id            => integer().autoIncrement()();
  TextColumn get courseCode   => text().unique()();
  TextColumn get courseName    => text()();
  TextColumn get group        => text().nullable()();
  IntColumn  get enrolled   => integer().withDefault(const Constant(0))();
  IntColumn  get avgAttendance => integer().withDefault(const Constant(0))();
  TextColumn get lecturerId => text().nullable()();
}

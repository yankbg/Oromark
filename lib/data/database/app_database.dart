//The database itself. Created once, injected everywhere via Riverpod
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Sessions, AttendanceRecords, EnrolledStudents, Students, Lecturers, Courses])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // Runs only on fresh install — creates all tables
    onCreate: (m) async {
      await m.createAll();
      await seedDevData();
    },

    // Version 1 → 2: add enrolled_students table
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(enrolledStudents);
      }
      if (from < 3) {
        await m.drop(enrolledStudents);
        await m.createTable(enrolledStudents);
        await m.createTable(students);
        await m.createTable(lecturers);
        await m.createTable(courses);

        await seedDevData();
      }
    },

    // Runs after every migration — good place for integrity checks
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> seedDevData() async {
    await _seedCourses();
    await _seedEnrolledStudents();
    await _seedLecturerProfile();
    await _seedStudentProfile();
  }

  Future<void> _seedCourses() async {
    final existing = await select(courses).get();
    if (existing.isNotEmpty) return; // already seeded

    await batch((b) {
      b.insertAll(courses, [
        CoursesCompanion.insert(
          courseCode:    'CS301',
          courseName:    'Software Engineering',
          group:         const Value('Group A'),
          enrolled:      const Value(60),
          avgAttendance: const Value(87),
          lecturerId:    'IUEA/LEC/001',
        ),
        CoursesCompanion.insert(
          courseCode:    'CS202',
          courseName:    'Database Systems',
          group:         const Value('Group B'),
          enrolled:      const Value(45),
          avgAttendance: const Value(92),
          lecturerId:    'IUEA/LEC/001',
        ),
        CoursesCompanion.insert(
          courseCode:    'CS405',
          courseName:    'Cloud Computing',
          group:         const Value('Final Year'),
          enrolled:      const Value(32),
          avgAttendance: const Value(85),
          lecturerId:    'IUEA/LEC/001',
        ),
        CoursesCompanion.insert(
          courseCode:    'CS312',
          courseName:    'Computer Networks',
          group:         const Value('Group C'),
          enrolled:      const Value(38),
          avgAttendance: const Value(79),
          lecturerId:    'IUEA/LEC/001',
        ),
      ]);
    });
  }

  Future<void> _seedEnrolledStudents() async {
    final existing = await select(enrolledStudents).get();
    if (existing.isNotEmpty) return;

    // 8 sample students per course — enough for the dashboard to feel real.
    // In production these come from Supabase enrollments on login.
    final rows = <EnrolledStudentsCompanion>[];

    void addStudents(String code, List<Map<String, String>> students) {
      for (final s in students) {
        rows.add(EnrolledStudentsCompanion.insert(
          studentId:  s['id']!,
          courseCode: code,
          fullName:   s['name']!,
        ));
      }
    }

    addStudents('CS301', [
      {'id': 'U-2023-8841', 'name': 'Alex Rivera'},
      {'id': 'U-2023-9102', 'name': 'Elena Sofia'},
      {'id': 'U-2023-7443', 'name': 'Jordan Mills'},
      {'id': 'U-2023-1109', 'name': 'Maya Kaur'},
      {'id': 'U-2023-6621', 'name': 'Liam Chen'},
      {'id': 'U-2023-3312', 'name': 'Amara Diallo'},
      {'id': 'U-2023-4471', 'name': 'Tobias Owusu'},
      {'id': 'U-2023-5503', 'name': 'Priya Nair'},
    ]);

    addStudents('CS202', [
      {'id': 'U-2023-2201', 'name': 'Samuel Osei'},
      {'id': 'U-2023-2202', 'name': 'Fatima Bah'},
      {'id': 'U-2023-2203', 'name': 'Kevin Mwangi'},
      {'id': 'U-2023-2204', 'name': 'Grace Nakato'},
      {'id': 'U-2023-2205', 'name': 'Idris Kamara'},
      {'id': 'U-2023-2206', 'name': 'Cynthia Otieno'},
      {'id': 'U-2023-2207', 'name': 'David Mensah'},
      {'id': 'U-2023-2208', 'name': 'Zara Juma'},
    ]);

    addStudents('CS405', [
      {'id': 'U-2023-4501', 'name': 'Brian Nkosi'},
      {'id': 'U-2023-4502', 'name': 'Aisha Conteh'},
      {'id': 'U-2023-4503', 'name': 'Emmanuel Asante'},
      {'id': 'U-2023-4504', 'name': 'Leila Hassan'},
      {'id': 'U-2023-4505', 'name': 'Moses Tetteh'},
      {'id': 'U-2023-4506', 'name': 'Nadira Okeke'},
      {'id': 'U-2023-4507', 'name': 'Peter Dlamini'},
      {'id': 'U-2023-4508', 'name': 'Ruth Abubakar'},
    ]);

    addStudents('CS312', [
      {'id': 'U-2023-3121', 'name': 'James Kimani'},
      {'id': 'U-2023-3122', 'name': 'Olivia Banda'},
      {'id': 'U-2023-3123', 'name': 'Felix Boateng'},
      {'id': 'U-2023-3124', 'name': 'Stella Njoku'},
      {'id': 'U-2023-3125', 'name': 'Patrick Mulisa'},
      {'id': 'U-2023-3126', 'name': 'Diana Achola'},
      {'id': 'U-2023-3127', 'name': 'George Tekeste'},
      {'id': 'U-2023-3128', 'name': 'Hawa Coulibaly'},
    ]);

    await batch((b) => b.insertAll(enrolledStudents, rows));
  }

  // ── Dev seed ──────────────────────────────────────────────────────────────
  // Populates Courses and EnrolledStudents with the canonical OROmark mock
  // data so every screen works without Supabase being connected.
  //
  // Safe to call multiple times — checks existence before inserting.
  // Remove or gate behind a debug flag once Supabase sync is wired.

  Future<void> _seedLecturerProfile() async {
    final existing = await select(lecturers).get();
    if (existing.isNotEmpty) return;

    await into(lecturers).insert(
      LecturersCompanion.insert(
        lecturerId: 'IUEA/LEC/001',
        lecturerName:   'Dr. John Doe',
        lecturerEmail:      'doe@iuea.ac.ug',
        department:       'computer science',
      ),
    );
  }

  Future<void> _seedStudentProfile() async {
    final existing = await select(students).get();
    if (existing.isNotEmpty) return;

    // The logged-in student — matches 'Alex Rivera' in CS301 enrolled list.
    await into(students).insert(
      StudentsCompanion.insert(
        studentId:   'U-2023-8841',
        studentName:    'Alex Rivera',
        studentEmail:   'alex.rivera@iuea.ac.ug',
        phoneNumber:    '+256 790 228 489'
        programme:       'Computer Science',
        yearOfStudey:    '3rd Year'
      ),
    );
  }



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
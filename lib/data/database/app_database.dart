//The database itself. Created once, injected everywhere via Riverpod
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:oromark/data/models/auth_result.dart';
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
          lecturerId:    const Value('IUEA/LEC/001'),
        ),
        CoursesCompanion.insert(
          courseCode:    'CS202',
          courseName:    'Database Systems',
          group:         const Value('Group B'),
          enrolled:      const Value(45),
          avgAttendance: const Value(92),
          lecturerId:    const Value('IUEA/LEC/001'),
        ),
        CoursesCompanion.insert(
          courseCode:    'CS405',
          courseName:    'Cloud Computing',
          group:         const Value('Final Year'),
          enrolled:      const Value(32),
          avgAttendance: const Value(85),
          lecturerId:    const Value('IUEA/LEC/001'),
        ),
        CoursesCompanion.insert(
          courseCode:    'CS312',
          courseName:    'Computer Networks',
          group:         const Value('Group C'),
          enrolled:      const Value(38),
          avgAttendance: const Value(79),
          lecturerId:    const Value('IUEA/LEC/001'),
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
        password:          '4321'
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
        phoneNumber:    '+256 790 228 489',
        programme:       'Computer Science',
        yearOfStudy:    '3rd Year',
          password:      '1234'
      ),
    );
  }
  static EnrolledStudentsCompanion _buildStudent(
      String studentId,
      String courseCode,
      String studentName,
      ) {
    return EnrolledStudentsCompanion.insert(
      studentId: studentId,
      courseCode: courseCode,
      fullName: studentName,
    );
  }
  // ── Course helpers ────────────────────────────────────────────────────────

  Future<List<Course>> getAllCourses() => select(courses).get();

  Stream<List<Course>> watchAllCourses() => select(courses).watch();

  Future<Course?> getCourseByCode(String code) {
    return (select(courses)..where((c) => c.courseCode.equals(code)))
        .getSingleOrNull();
  }

  /// Called after a session ends to refresh the cached avgAttendance value.
  Future<void> updateCourseAttendance(
      String courseCode,
      int newAvgAttendance,
      ) async {
    await (update(courses)
      ..where((c) => c.courseCode.equals(courseCode)))
        .write(CoursesCompanion(
      avgAttendance: Value(newAvgAttendance),
    ));
  }
  Future<List<EnrolledStudent>> getEnrolledStudents(String courseCode) {
    return (select(enrolledStudents)
      ..where((s) => s.courseCode.equals(courseCode)))
        .get();
  }
  // Get enrolled count for a course
  Future<int> getEnrolledCount(String courseCode) async {
    final result = await (select(enrolledStudents)
      ..where((e) => e.courseCode.equals(courseCode)))
        .get();
    return result.length;
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
  // Returns all records for a session — used by _computeAbsent
  Future<List<AttendanceRecord>> getSessionAttendance(
      String sessionId,
      ) async {
    return (select(attendanceRecords)
      ..where((r) => r.sessionId.equals(sessionId)))
        .get();
  }
  /// All records for the logged-in student — drives HistoryController.
  Future<List<AttendanceRecord>> getStudentHistory(String studentId) {
    return (select(attendanceRecords)
      ..where((r) => r.studentId.equals(studentId))
      ..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
        .get();
  }
  Future<void> markSynced(List<int> ids) async {
    await (update(attendanceRecords)
      ..where((a) => a.id.isIn(ids)))
        .write(const AttendanceRecordsCompanion(synced: Value(true)));
  }
  // ── Sessions helpers ──────────────────────────────────────────────────────

  Future<int> insertSession(SessionsCompanion entry) =>
      into(sessions).insert(entry);

  Future<Session?> getSessionById(String sessionId) {
    return (select(sessions)
      ..where((s) => s.sessionId.equals(sessionId)))
        .getSingleOrNull();
  }
  /// Called when session ends to record final status
  Future<void> updateSessionStatus(String sessionId, String newStatus) async {
    await (update(sessions)
      ..where((s) => s.sessionId.equals(sessionId)))
        .write(SessionsCompanion(
      status: Value(newStatus),
    ));
  }
  /// Returns the profile row for the currently logged-in student.
  /// [studentId] will come from Supabase auth once that is wired;
  /// for now the mock student id '2023/CS/001' is used directly.
  Future<Student?> getStudentProfile(String studentId) {
    return (select(students)
      ..where((p) => p.studentId.equals(studentId)))
        .getSingleOrNull();
  }

  /// Reactive version — rebuilds the Profile screen whenever the row changes
  /// (e.g. after a Supabase sync updates the avatar URL).
  Stream<Student?> watchStudentProfile(String studentId) {
    return (select(students)
      ..where((p) => p.studentId.equals(studentId)))
        .watchSingleOrNull();
  }

  /// Upsert a profile row — called after a successful Supabase sync.
  Future<void> upsertStudentProfile(StudentsCompanion entry) {
    return into(students).insertOnConflictUpdate(entry);
  }

  /// Returns all courses the student is enrolled in.
  Future<List<EnrolledStudent>> getCoursesForStudent(String studentId) {
    return (select(enrolledStudents)
      ..where((s) => s.studentId.equals(studentId)))
        .get();
  }


  /// All sessions for a course, newest first — drives CourseDetailScreen.
  Future<List<Session>> getSessionsForCourse(String courseCode) {
    return (select(sessions)
      ..where((s) => s.courseCode.equals(courseCode))
      ..orderBy([(s) => OrderingTerm.desc(s.startTime)]))
        .get();
  }
  Future<AuthResult?> login({
    String? studentId,
    String? email,
    required String password,

}) async{
    // 1) Try student by studentId + password
    if (studentId != null && studentId.isNotEmpty) {
      final studentQuery = select(students)
        ..where((tbl) => tbl.studentId.equals(studentId))
        ..where((tbl) => tbl.password.equals(password));

      final student = await studentQuery.getSingleOrNull();
      if (student != null) {
        return AuthResult.student(
          fullname: student.studentName,
          userId: student.studentId,
          email: student.studentEmail,
          program: student.programme,
          yearOfStudy: student.yearOfStudy
        );
      }
    }
    // 2) Try student by email + password
    if (email != null && email.isNotEmpty) {
      final studentQuery = select(students)
        ..where((tbl) => tbl.studentEmail.equals(email))
        ..where((tbl) => tbl.password.equals(password));

      final student = await studentQuery.getSingleOrNull();
      if (student != null) {
        return AuthResult.student(
            fullname: student.studentName,
            userId: student.studentId,
            email: student.studentEmail,
            program: student.programme,
            yearOfStudy: student.yearOfStudy
        );
      }
    }
    // 3) Try lecturer by email + password
    if (email != null && email.isNotEmpty) {
      final lecturerQuery = select(lecturers)
        ..where((tbl) => tbl.lecturerEmail.equals(email))
        ..where((tbl) => tbl.password.equals(password));

      final lecturer = await lecturerQuery.getSingleOrNull();
      if (lecturer != null) {
        return AuthResult.lecturer(
          fullname: lecturer.lecturerName,
          userId: lecturer.lecturerId,
          email: lecturer.lecturerEmail,
          department: lecturer.department
        );
      }
    }

    // 4) No match found
    return null;
  }

}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'oromark.db'));
    return NativeDatabase(file);
  });
}
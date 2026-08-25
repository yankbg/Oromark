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
  int get schemaVersion => 4;

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
      if (from < 4) {
        await m.addColumn(students, students.avatarUrl);
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
    await batch((b) {
      b.insertAll(students, [
      StudentsCompanion.insert(
        studentId:   'U-2023-8841',
        studentName:    'Alex Rivera',
        studentEmail:   'alex.rivera@iuea.ac.ug',
        phoneNumber:    '+256 790 228 489',
        programme:       'Computer Science',
        yearOfStudy:    '3rd Year',
          password:      '1234'
      ),
      StudentsCompanion.insert(
        studentId: 'U-2023-9102',
        studentName: 'Elena Sofia',
        studentEmail: 'elena.sofia@iuea.ac.ug',
        phoneNumber: '+256 790 228 490',
        programme: 'Computer Science',
        yearOfStudy: '3rd Year',
        password: '5678',
      ),

      StudentsCompanion.insert(
        studentId: 'U-2023-7443',
        studentName: 'Jordan Mills',
        studentEmail: 'jordan.mills@iuea.ac.ug',
        phoneNumber: '+256 790 228 491',
        programme: 'Computer Science',
        yearOfStudy: '3rd Year',
        password: '9123',
      ),

      StudentsCompanion.insert(
        studentId: 'U-2023-1109',
        studentName: 'Maya Kaur',
        studentEmail: 'maya.kaur@iuea.ac.ug',
        phoneNumber: '+256 790 228 492',
        programme: 'Computer Science',
        yearOfStudy: '3rd Year',
        password: '4567',
      ),

      ]);
    });
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

  Future<List<Course>> getCoursesForLecturer(String lecturerId) {
    return (select(courses)..where((c) => c.lecturerId.equals(lecturerId)))
        .get();
  }

  /// Upserts a course pulled from Neon (courseCode is unique locally, so
  /// this matches the existing row if one exists).
  ///
  /// Must target courseCode explicitly: courses.id is a meaningless local
  /// autoincrement PK never supplied here, so insertOnConflictUpdate's
  /// default (conflict on the PK) never fires — it would try to INSERT a
  /// new row every time and crash with a UNIQUE constraint violation on
  /// course_code whenever this course already exists locally (e.g. one of
  /// the seeded demo courses).
  Future<void> upsertCourse(CoursesCompanion entry) {
    return into(courses).insert(
      entry,
      onConflict: DoUpdate((_) => entry, target: [courses.courseCode]),
    );
  }

  /// Replaces the local roster for [courseCode] with [roster] pulled from
  /// Neon. EnrolledStudents has no local uniqueness constraint to upsert
  /// against, so — since Neon is authoritative for who's enrolled — the
  /// simplest correct approach is to clear this course's local rows first,
  /// then insert the fresh set, inside one transaction.
  Future<void> replaceEnrolledStudents(
    String courseCode,
    List<EnrolledStudentsCompanion> roster,
  ) async {
    await transaction(() async {
      await (delete(enrolledStudents)
            ..where((e) => e.courseCode.equals(courseCode)))
          .go();
      if (roster.isNotEmpty) {
        await batch((b) => b.insertAll(enrolledStudents, roster));
      }
    });
  }

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

  // ── Cloud sync helpers (SyncService → Neon Postgres) ────────────────────

  Future<List<Session>> getUnsyncedSessions() {
    return (select(sessions)..where((s) => s.synced.equals(false))).get();
  }

  Future<void> markSessionsSynced(List<String> sessionIds) async {
    await (update(sessions)..where((s) => s.sessionId.isIn(sessionIds)))
        .write(const SessionsCompanion(synced: Value(true)));
  }

  Future<List<Lecturer>> getAllLecturers() => select(lecturers).get();

  Future<List<Student>> getAllStudents() => select(students).get();

  Future<List<EnrolledStudent>> getAllEnrolledStudents() =>
      select(enrolledStudents).get();

  // ── Sessions helpers ──────────────────────────────────────────────────────

  Future<int> insertSession(SessionsCompanion entry) =>
      into(sessions).insert(entry);

  /// Caches a session's basic metadata (course, timing) locally on the
  /// student's device. The lecturer's Sessions row lives on the lecturer's
  /// own device and is never transmitted — a student only ever learns a
  /// session's details from the UDP broadcast — so this is called right
  /// after a successful attendance submission to make the course name/date
  /// available to that student's own history screen.
  Future<void> upsertSessionMeta(SessionsCompanion entry) {
    return into(sessions).insertOnConflictUpdate(entry);
  }

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
  ///
  /// Must target studentId explicitly: students.id is a meaningless local
  /// autoincrement PK never supplied here, so insertOnConflictUpdate's
  /// default (conflict on the PK) never fires — it would try to INSERT a
  /// new row every time and crash with a UNIQUE constraint violation on
  /// student_id/student_email whenever this student already has a local
  /// row (e.g. one of the seeded demo students, or a prior login).
  Future<void> upsertStudentProfile(StudentsCompanion entry) {
    return into(students).insert(
      entry,
      onConflict: DoUpdate((_) => entry, target: [students.studentId]),
    );
  }

  /// Returns the profile row for a lecturer, by lecturerId.
  Future<Lecturer?> getLecturerProfile(String lecturerId) {
    return (select(lecturers)
      ..where((l) => l.lecturerId.equals(lecturerId)))
        .getSingleOrNull();
  }

  /// Upsert a lecturer profile row — called after a successful network
  /// login, so the profile is cached locally for offline-fallback logins
  /// and for the rest of the app's offline-capable screens.
  ///
  /// Must target lecturerId explicitly: lecturers.id is a meaningless local
  /// autoincrement PK never supplied here, so insertOnConflictUpdate's
  /// default (conflict on the PK) never fires — it would try to INSERT a
  /// new row every time and crash with a UNIQUE constraint violation on
  /// lecturer_id whenever this lecturer already has a local row (e.g. the
  /// seeded demo lecturer, or a prior login).
  Future<void> upsertLecturerProfile(LecturersCompanion entry) {
    return into(lecturers).insert(
      entry,
      onConflict: DoUpdate((_) => entry, target: [lecturers.lecturerId]),
    );
  }

  /// Saves the Cloudinary URL of a student's profile picture. Any screen
  /// watching watchStudentProfile() for this studentId picks up the change
  /// automatically — that's what keeps the avatar in sync across the
  /// profile, home, and history screens.
  Future<void> updateStudentAvatar(String studentId, String avatarUrl) {
    return (update(students)..where((s) => s.studentId.equals(studentId)))
        .write(StudentsCompanion(avatarUrl: Value(avatarUrl)));
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
  /// Insert attendance record after HTTP success
  Future<void> insertAttendanceRecord({
    required String sessionId,
    required String studentId,
    required String status,
    required int submittedAt,
  }) async {
    await into(attendanceRecords).insert(
      AttendanceRecordsCompanion.insert(
        sessionId: sessionId,
        studentId: studentId,
        status: status,
        timestamp: submittedAt,
      ),
      onConflict: DoUpdate(
            (old) => AttendanceRecordsCompanion(
          status: Value(status),
              timestamp: Value(submittedAt),
        ),
      ),
    );
  }

  /// Get attendance for a student in a session
  Future<AttendanceRecord?> getAttendanceRecord({
    required String sessionId,
    required String studentId,
  }) async {
    return (select(attendanceRecords)
      ..where((tbl) =>
      tbl.sessionId.equals(sessionId) &
      tbl.studentId.equals(studentId)))
        .getSingleOrNull();
  }


    /// On-device-only login check against local SQLite. This is the
    /// degraded-but-functional fallback path used by [LoginController] when
    /// the network call to the sync server's POST /auth/login can't be
    /// made (no internet) or when the network endpoint doesn't yet know
    /// about this account (a pre-existing local-only account that hasn't
    /// been bootstrapped to Neon yet). Kept under its original name-free
    /// signature so existing behavior is unchanged; renamed to loginLocal
    /// to make the network-first flow in LoginController read clearly.
    Future<AuthResult?> loginLocal({
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
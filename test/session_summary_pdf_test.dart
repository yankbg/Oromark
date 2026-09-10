// Smoke test for the session summary PDF generator.

import 'package:flutter_test/flutter_test.dart';
import 'package:oromark/presentation/lecturer/session/session_controller.dart';
import 'package:oromark/presentation/lecturer/session/session_summary_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final state = SessionSummaryState(
    sessionId: 'sess-1',
    courseCode: 'CS301',
    courseName: 'Operating Systems',
    startedAt: DateTime(2026, 10, 24, 10, 0),
    endedAt: DateTime(2026, 10, 24, 11, 15),
    presentCount: 2,
    lateCount: 1,
    enrolled: 4,
    absentStudents: const [
      StudentEntry(
        name: 'Jordan Mills',
        studentId: 'U-2023-7443',
        status: CheckInStatus.notCheckedIn,
      ),
    ],
  );

  final roster = <StudentEntry>[
    StudentEntry(
      name: 'Alex Rivera',
      studentId: 'U-2023-8841',
      checkInTime: DateTime(2026, 10, 24, 10, 3),
      status: CheckInStatus.present,
    ),
    StudentEntry(
      name: 'Maya Kaur',
      studentId: 'U-2023-1109',
      checkInTime: DateTime(2026, 10, 24, 10, 2),
      status: CheckInStatus.present,
    ),
    StudentEntry(
      name: 'Elena Sofia',
      studentId: 'U-2023-9102',
      checkInTime: DateTime(2026, 10, 24, 10, 12),
      status: CheckInStatus.late,
    ),
    const StudentEntry(
      name: 'Jordan Mills',
      studentId: 'U-2023-7443',
      status: CheckInStatus.notCheckedIn,
    ),
  ];

  test('produces a non-empty PDF document', () async {
    final bytes = await buildSessionSummaryPdf(state, roster);

    expect(bytes.length, greaterThan(1000));
    // %PDF magic header
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('handles an empty roster without throwing', () async {
    final bytes = await buildSessionSummaryPdf(state, const []);

    expect(bytes.length, greaterThan(1000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}

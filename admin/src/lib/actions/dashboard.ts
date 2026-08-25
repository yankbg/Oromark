import "server-only";
import { sql } from "@/lib/db";

export interface DashboardStats {
  studentCount: number;
  lecturerCount: number;
  courseCount: number;
  sessionCount: number;
  liveSessionCount: number;
  attendanceRecordCount: number;
  avgAttendance: number | null;
}

export async function getDashboardStats(): Promise<DashboardStats> {
  const [row] = await sql<
    {
      student_count: string;
      lecturer_count: string;
      course_count: string;
      session_count: string;
      live_session_count: string;
      attendance_count: string;
      avg_attendance: string | null;
    }[]
  >`
    select
      (select count(*) from students)::text as student_count,
      (select count(*) from lecturers)::text as lecturer_count,
      (select count(*) from courses)::text as course_count,
      (select count(*) from sessions)::text as session_count,
      (select count(*) from sessions where lower(status) in ('live', 'active'))::text as live_session_count,
      (select count(*) from attendance_records)::text as attendance_count,
      (select avg(avg_attendance) from courses)::text as avg_attendance
  `;

  return {
    studentCount: Number(row.student_count),
    lecturerCount: Number(row.lecturer_count),
    courseCount: Number(row.course_count),
    sessionCount: Number(row.session_count),
    liveSessionCount: Number(row.live_session_count),
    attendanceRecordCount: Number(row.attendance_count),
    avgAttendance: row.avg_attendance ? Math.round(Number(row.avg_attendance)) : null,
  };
}

export interface AttendanceTrendPoint {
  date: string;
  present: number;
  late: number;
  absent: number;
}

/** Daily present/late/absent counts for the last [days], zero-filled so the
 * line chart always has a continuous axis even on days with no activity. */
export async function getAttendanceTrend(days = 14): Promise<AttendanceTrendPoint[]> {
  const rows = await sql<{ day: string; present: string; late: string; absent: string }[]>`
    select
      to_char(d.day, 'YYYY-MM-DD') as day,
      coalesce(sum(case when lower(a.status) = 'present' then 1 else 0 end), 0)::text as present,
      coalesce(sum(case when lower(a.status) = 'late' then 1 else 0 end), 0)::text as late,
      coalesce(sum(case when lower(a.status) = 'absent' then 1 else 0 end), 0)::text as absent
    from generate_series(
      date_trunc('day', now()) - make_interval(days => ${days - 1}),
      date_trunc('day', now()),
      interval '1 day'
    ) as d(day)
    left join attendance_records a on date_trunc('day', a."timestamp") = d.day
    group by d.day
    order by d.day
  `;

  return rows.map((r) => ({
    date: r.day,
    present: Number(r.present),
    late: Number(r.late),
    absent: Number(r.absent),
  }));
}

export interface AttendanceBreakdown {
  present: number;
  late: number;
  absent: number;
}

/** All-time present/late/absent totals across every synced attendance record. */
export async function getAttendanceBreakdown(): Promise<AttendanceBreakdown> {
  const [row] = await sql<{ present: string; late: string; absent: string }[]>`
    select
      coalesce(sum(case when lower(status) = 'present' then 1 else 0 end), 0)::text as present,
      coalesce(sum(case when lower(status) = 'late' then 1 else 0 end), 0)::text as late,
      coalesce(sum(case when lower(status) = 'absent' then 1 else 0 end), 0)::text as absent
    from attendance_records
  `;

  return { present: Number(row.present), late: Number(row.late), absent: Number(row.absent) };
}

export interface TopCourse {
  courseCode: string;
  courseName: string;
  avgAttendance: number;
  enrolled: number;
}

/** Courses ranked by their cached avg_attendance (kept in sync by the mobile
 * app after each session ends), for the "top courses" bar chart. */
export async function getTopCourses(limit = 6): Promise<TopCourse[]> {
  const rows = await sql<
    { course_code: string; course_name: string; avg_attendance: number; enrolled: number }[]
  >`
    select course_code, course_name, avg_attendance, enrolled
    from courses
    order by avg_attendance desc, enrolled desc
    limit ${limit}
  `;

  return rows.map((r) => ({
    courseCode: r.course_code,
    courseName: r.course_name,
    avgAttendance: r.avg_attendance,
    enrolled: r.enrolled,
  }));
}

export interface RecentSession {
  session_id: string;
  course_code: string;
  course_name: string;
  lecturer_name: string | null;
  status: string;
  start_time: string;
  present: number;
  late: number;
  absent: number;
}

export async function getRecentSessions(limit = 8): Promise<RecentSession[]> {
  return sql<RecentSession[]>`
    select
      s.session_id, s.course_code, s.course_name, s.lecturer_name, s.status, s.start_time,
      coalesce(sum(case when lower(a.status) = 'present' then 1 else 0 end), 0)::int as present,
      coalesce(sum(case when lower(a.status) = 'late' then 1 else 0 end), 0)::int as late,
      coalesce(sum(case when lower(a.status) = 'absent' then 1 else 0 end), 0)::int as absent
    from sessions s
    left join attendance_records a on a.session_id = s.session_id
    group by s.session_id, s.course_code, s.course_name, s.lecturer_name, s.status, s.start_time
    order by s.start_time desc
    limit ${limit}
  `;
}

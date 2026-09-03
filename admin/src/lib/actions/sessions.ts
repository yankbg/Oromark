"use server";

import { sql } from "@/lib/db";
import type { Session } from "@/lib/types";

export interface SessionWithCounts extends Session {
  present: number;
  late: number;
  absent: number;
}

/** Every synced session, newest first, with attendance counts rolled up —
 * this is the data lecturers' phones push after each session ends (and
 * periodically thereafter) via server/'s /sync endpoint; see
 * sync_service.dart and session_notifier.dart's endSession() on the mobile
 * side. Optional [query] matches course code/name, room code, or lecturer
 * name. */
export async function listSessions(query?: string): Promise<SessionWithCounts[]> {
  if (query && query.trim()) {
    const like = `%${query.trim()}%`;
    return sql<SessionWithCounts[]>`
      select
        s.*,
        coalesce(sum(case when lower(a.status) = 'present' then 1 else 0 end), 0)::int as present,
        coalesce(sum(case when lower(a.status) = 'late' then 1 else 0 end), 0)::int as late,
        coalesce(sum(case when lower(a.status) = 'absent' then 1 else 0 end), 0)::int as absent
      from sessions s
      left join attendance_records a on a.session_id = s.session_id
      where s.course_code ilike ${like}
         or s.course_name ilike ${like}
         or s.room_code ilike ${like}
         or s.lecturer_name ilike ${like}
      group by s.session_id
      order by s.start_time desc
    `;
  }
  return sql<SessionWithCounts[]>`
    select
      s.*,
      coalesce(sum(case when lower(a.status) = 'present' then 1 else 0 end), 0)::int as present,
      coalesce(sum(case when lower(a.status) = 'late' then 1 else 0 end), 0)::int as late,
      coalesce(sum(case when lower(a.status) = 'absent' then 1 else 0 end), 0)::int as absent
    from sessions s
    left join attendance_records a on a.session_id = s.session_id
    group by s.session_id
    order by s.start_time desc
  `;
}

/** A single course's sessions, newest first — same shape as [listSessions]
 * but scoped by an exact course_code match, for the course detail page's
 * drill-down (Courses → this course's sessions → session detail). */
export async function getSessionsForCourse(courseCode: string): Promise<SessionWithCounts[]> {
  return sql<SessionWithCounts[]>`
    select
      s.*,
      coalesce(sum(case when lower(a.status) = 'present' then 1 else 0 end), 0)::int as present,
      coalesce(sum(case when lower(a.status) = 'late' then 1 else 0 end), 0)::int as late,
      coalesce(sum(case when lower(a.status) = 'absent' then 1 else 0 end), 0)::int as absent
    from sessions s
    left join attendance_records a on a.session_id = s.session_id
    where s.course_code = ${courseCode}
    group by s.session_id
    order by s.start_time desc
  `;
}

export interface SessionAttendanceRow {
  student_id: string;
  student_name: string | null;
  status: string;
  timestamp: string;
}

export interface SessionDetail {
  session: Session;
  attendance: SessionAttendanceRow[];
}

/** A single session plus its full attendance roster (present, late, and
 * absent alike — _computeAbsent() on the mobile side inserts ABSENT rows
 * too, so this is the complete enrolled-student picture, not just who
 * showed up). Student names come from a left join so a record for a
 * student not present in the students table still shows up by ID. */
export async function getSessionDetail(sessionId: string): Promise<SessionDetail | null> {
  const sessionRows = await sql<Session[]>`
    select * from sessions where session_id = ${sessionId} limit 1
  `;
  const session = sessionRows[0];
  if (!session) return null;

  const attendance = await sql<SessionAttendanceRow[]>`
    select ar.student_id, st.student_name, ar.status, ar."timestamp"
    from attendance_records ar
    left join students st on st.student_id = ar.student_id
    where ar.session_id = ${sessionId}
    order by ar."timestamp" asc
  `;

  return { session, attendance };
}

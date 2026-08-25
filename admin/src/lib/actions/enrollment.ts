"use server";

import { sql } from "@/lib/db";
import { revalidatePath } from "next/cache";
import type { EnrolledStudent, Student } from "@/lib/types";

export async function listEnrolledStudents(courseCode: string): Promise<EnrolledStudent[]> {
  return sql<EnrolledStudent[]>`
    select * from enrolled_students
    where course_code = ${courseCode}
    order by full_name asc
  `;
}

/** Students not yet enrolled in this course, for the "add student" picker. */
export async function listEnrollableStudents(courseCode: string): Promise<Student[]> {
  return sql<Student[]>`
    select s.* from students s
    where not exists (
      select 1 from enrolled_students e
      where e.course_code = ${courseCode} and e.student_id = s.student_id
    )
    order by s.student_name asc
  `;
}

export type EnrollFormState = { error?: string; success?: boolean };

export async function enrollStudent(
  courseCode: string,
  _prevState: EnrollFormState,
  formData: FormData
): Promise<EnrollFormState> {
  const studentId = String(formData.get("student_id") ?? "").trim();
  if (!studentId) return { error: "Choose a student to enroll." };

  const student = await sql<Pick<Student, "student_name">[]>`
    select student_name from students where student_id = ${studentId} limit 1
  `;
  if (student.length === 0) return { error: "That student no longer exists." };

  try {
    await sql`
      insert into enrolled_students (student_id, course_code, full_name)
      values (${studentId}, ${courseCode}, ${student[0].student_name})
      on conflict (student_id, course_code) do nothing
    `;
    await sql`
      update courses set enrolled = (
        select count(*) from enrolled_students where course_code = ${courseCode}
      ) where course_code = ${courseCode}
    `;
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    return { error: `Couldn't enroll this student. ${message}` };
  }

  revalidatePath(`/courses/${encodeURIComponent(courseCode)}`);
  revalidatePath("/courses");
  return { success: true };
}

export async function unenrollStudent(courseCode: string, studentId: string) {
  await sql`
    delete from enrolled_students where course_code = ${courseCode} and student_id = ${studentId}
  `;
  await sql`
    update courses set enrolled = (
      select count(*) from enrolled_students where course_code = ${courseCode}
    ) where course_code = ${courseCode}
  `;
  revalidatePath(`/courses/${encodeURIComponent(courseCode)}`);
  revalidatePath("/courses");
}

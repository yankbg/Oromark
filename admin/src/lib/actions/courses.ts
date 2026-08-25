"use server";

import { sql } from "@/lib/db";
import { revalidatePath } from "next/cache";
import type { CourseWithLecturer } from "@/lib/types";

export async function listCourses(query?: string): Promise<CourseWithLecturer[]> {
  if (query && query.trim()) {
    const like = `%${query.trim()}%`;
    return sql<CourseWithLecturer[]>`
      select c.*, l.lecturer_name
      from courses c
      left join lecturers l on l.lecturer_id = c.lecturer_id
      where c.course_name ilike ${like}
         or c.course_code ilike ${like}
         or c.course_group ilike ${like}
      order by c.course_code asc
    `;
  }
  return sql<CourseWithLecturer[]>`
    select c.*, l.lecturer_name
    from courses c
    left join lecturers l on l.lecturer_id = c.lecturer_id
    order by c.course_code asc
  `;
}

export async function getCourse(courseCode: string): Promise<CourseWithLecturer | null> {
  const rows = await sql<CourseWithLecturer[]>`
    select c.*, l.lecturer_name
    from courses c
    left join lecturers l on l.lecturer_id = c.lecturer_id
    where c.course_code = ${courseCode}
    limit 1
  `;
  return rows[0] ?? null;
}

export type CourseFormState = { error?: string; success?: boolean };

function readCourseForm(formData: FormData) {
  const lecturerRaw = String(formData.get("lecturer_id") ?? "").trim();
  return {
    course_code: String(formData.get("course_code") ?? "").trim(),
    course_name: String(formData.get("course_name") ?? "").trim(),
    course_group: String(formData.get("course_group") ?? "").trim() || null,
    lecturer_id: lecturerRaw === "__none__" || lecturerRaw === "" ? null : lecturerRaw,
  };
}

function validateCourse(data: ReturnType<typeof readCourseForm>): string | null {
  if (!data.course_code) return "Course code is required.";
  if (!data.course_name) return "Course name is required.";
  return null;
}

export async function createCourse(
  _prevState: CourseFormState,
  formData: FormData
): Promise<CourseFormState> {
  const data = readCourseForm(formData);
  const error = validateCourse(data);
  if (error) return { error };

  try {
    await sql`
      insert into courses (course_code, course_name, course_group, lecturer_id)
      values (${data.course_code}, ${data.course_name}, ${data.course_group}, ${data.lecturer_id})
    `;
  } catch (err) {
    return { error: dbErrorMessage(err) };
  }

  revalidatePath("/courses");
  return { success: true };
}

export async function updateCourse(
  originalCourseCode: string,
  _prevState: CourseFormState,
  formData: FormData
): Promise<CourseFormState> {
  const data = readCourseForm(formData);
  const error = validateCourse(data);
  if (error) return { error };

  try {
    await sql`
      update courses set
        course_code = ${data.course_code},
        course_name = ${data.course_name},
        course_group = ${data.course_group},
        lecturer_id = ${data.lecturer_id}
      where course_code = ${originalCourseCode}
    `;
  } catch (err) {
    return { error: dbErrorMessage(err) };
  }

  revalidatePath("/courses");
  revalidatePath(`/courses/${encodeURIComponent(data.course_code)}`);
  return { success: true };
}

export async function deleteCourse(courseCode: string) {
  await sql`delete from courses where course_code = ${courseCode}`;
  revalidatePath("/courses");
}

/** Assign (or clear) the lecturer for a course from the course detail page. */
export async function assignLecturer(courseCode: string, lecturerId: string | null) {
  await sql`update courses set lecturer_id = ${lecturerId} where course_code = ${courseCode}`;
  revalidatePath("/courses");
  revalidatePath(`/courses/${encodeURIComponent(courseCode)}`);
}

function dbErrorMessage(err: unknown): string {
  const message = err instanceof Error ? err.message : String(err);
  if (message.includes("duplicate key")) {
    return "A course with that code already exists.";
  }
  return `Couldn't save this course. ${message}`;
}

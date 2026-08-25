"use server";

import { sql } from "@/lib/db";
import { revalidatePath } from "next/cache";
import type { Lecturer } from "@/lib/types";

export async function listLecturers(query?: string): Promise<Lecturer[]> {
  if (query && query.trim()) {
    const like = `%${query.trim()}%`;
    return sql<Lecturer[]>`
      select * from lecturers
      where lecturer_name ilike ${like}
         or lecturer_id ilike ${like}
         or lecturer_email ilike ${like}
         or department ilike ${like}
      order by lecturer_name asc
    `;
  }
  return sql<Lecturer[]>`select * from lecturers order by lecturer_name asc`;
}

export async function getLecturer(lecturerId: string): Promise<Lecturer | null> {
  const rows = await sql<Lecturer[]>`
    select * from lecturers where lecturer_id = ${lecturerId} limit 1
  `;
  return rows[0] ?? null;
}

/** For selects: id + display name, cheap and always fresh. */
export async function listLecturerOptions(): Promise<Pick<Lecturer, "lecturer_id" | "lecturer_name">[]> {
  return sql<Pick<Lecturer, "lecturer_id" | "lecturer_name">[]>`
    select lecturer_id, lecturer_name from lecturers order by lecturer_name asc
  `;
}

export type LecturerFormState = { error?: string; success?: boolean };

function readLecturerForm(formData: FormData) {
  return {
    lecturer_id: String(formData.get("lecturer_id") ?? "").trim(),
    lecturer_name: String(formData.get("lecturer_name") ?? "").trim(),
    lecturer_email: String(formData.get("lecturer_email") ?? "").trim(),
    department: String(formData.get("department") ?? "").trim(),
  };
}

function validateLecturer(data: ReturnType<typeof readLecturerForm>): string | null {
  if (!data.lecturer_id) return "Lecturer ID is required.";
  if (!data.lecturer_name) return "Name is required.";
  if (!data.lecturer_email || !data.lecturer_email.includes("@"))
    return "A valid email is required.";
  if (!data.department) return "Department is required.";
  return null;
}

export async function createLecturer(
  _prevState: LecturerFormState,
  formData: FormData
): Promise<LecturerFormState> {
  const data = readLecturerForm(formData);
  const error = validateLecturer(data);
  if (error) return { error };

  try {
    await sql`
      insert into lecturers (lecturer_id, lecturer_name, lecturer_email, department)
      values (${data.lecturer_id}, ${data.lecturer_name}, ${data.lecturer_email}, ${data.department})
    `;
  } catch (err) {
    return { error: dbErrorMessage(err) };
  }

  revalidatePath("/lecturers");
  revalidatePath("/courses");
  return { success: true };
}

export async function updateLecturer(
  originalLecturerId: string,
  _prevState: LecturerFormState,
  formData: FormData
): Promise<LecturerFormState> {
  const data = readLecturerForm(formData);
  const error = validateLecturer(data);
  if (error) return { error };

  try {
    await sql.begin(async (tx) => {
      await tx`
        update lecturers set
          lecturer_id = ${data.lecturer_id},
          lecturer_name = ${data.lecturer_name},
          lecturer_email = ${data.lecturer_email},
          department = ${data.department}
        where lecturer_id = ${originalLecturerId}
      `;
      if (originalLecturerId !== data.lecturer_id) {
        await tx`
          update courses set lecturer_id = ${data.lecturer_id}
          where lecturer_id = ${originalLecturerId}
        `;
      }
    });
  } catch (err) {
    return { error: dbErrorMessage(err) };
  }

  revalidatePath("/lecturers");
  revalidatePath(`/lecturers/${encodeURIComponent(data.lecturer_id)}`);
  revalidatePath("/courses");
  return { success: true };
}

export async function deleteLecturer(lecturerId: string) {
  await sql`delete from lecturers where lecturer_id = ${lecturerId}`;
  revalidatePath("/lecturers");
  revalidatePath("/courses");
}

function dbErrorMessage(err: unknown): string {
  const message = err instanceof Error ? err.message : String(err);
  if (message.includes("duplicate key")) {
    return "A lecturer with that ID already exists.";
  }
  return `Couldn't save this lecturer. ${message}`;
}

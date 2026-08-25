"use server";

import { sql } from "@/lib/db";
import { revalidatePath } from "next/cache";
import bcrypt from "bcryptjs";
import type { Student } from "@/lib/types";

export async function listStudents(query?: string): Promise<Student[]> {
  if (query && query.trim()) {
    const like = `%${query.trim()}%`;
    return sql<Student[]>`
      select * from students
      where student_name ilike ${like}
         or student_id ilike ${like}
         or student_email ilike ${like}
         or programme ilike ${like}
      order by student_name asc
    `;
  }
  return sql<Student[]>`select * from students order by student_name asc`;
}

export async function getStudent(studentId: string): Promise<Student | null> {
  const rows = await sql<Student[]>`
    select * from students where student_id = ${studentId} limit 1
  `;
  return rows[0] ?? null;
}

export type StudentFormState = { error?: string; success?: boolean };

function readStudentForm(formData: FormData) {
  return {
    student_id: String(formData.get("student_id") ?? "").trim(),
    student_name: String(formData.get("student_name") ?? "").trim(),
    student_email: String(formData.get("student_email") ?? "").trim(),
    phone_number: String(formData.get("phone_number") ?? "").trim(),
    programme: String(formData.get("programme") ?? "").trim(),
    year_of_study: String(formData.get("year_of_study") ?? "").trim(),
    password: String(formData.get("password") ?? ""),
  };
}

function validateStudent(
  data: ReturnType<typeof readStudentForm>,
  { requirePassword }: { requirePassword: boolean }
): string | null {
  if (!data.student_id) return "Student ID is required.";
  if (!data.student_name) return "Name is required.";
  if (!data.student_email || !data.student_email.includes("@"))
    return "A valid email is required.";
  if (!data.phone_number) return "Phone number is required.";
  if (!data.programme) return "Programme is required.";
  if (!data.year_of_study) return "Year of study is required.";
  if (requirePassword && !data.password) return "Password is required.";
  if (data.password && data.password.length < 4) return "Password must be at least 4 characters.";
  return null;
}

export async function createStudent(
  _prevState: StudentFormState,
  formData: FormData
): Promise<StudentFormState> {
  const data = readStudentForm(formData);
  const error = validateStudent(data, { requirePassword: true });
  if (error) return { error };

  // Hashed with bcrypt before it ever touches the database — the mobile
  // app's sync server checks this same hash on POST /auth/login, so a
  // dashboard-created student can log in on their phone immediately.
  const passwordHash = await bcrypt.hash(data.password, 10);

  try {
    await sql`
      insert into students (student_id, student_name, student_email, phone_number, programme, year_of_study, password_hash)
      values (${data.student_id}, ${data.student_name}, ${data.student_email}, ${data.phone_number}, ${data.programme}, ${data.year_of_study}, ${passwordHash})
    `;
  } catch (err) {
    return { error: dbErrorMessage(err, "student") };
  }

  revalidatePath("/students");
  return { success: true };
}

export async function updateStudent(
  originalStudentId: string,
  _prevState: StudentFormState,
  formData: FormData
): Promise<StudentFormState> {
  const data = readStudentForm(formData);
  const error = validateStudent(data, { requirePassword: false });
  if (error) return { error };

  try {
    if (data.password) {
      const passwordHash = await bcrypt.hash(data.password, 10);
      await sql`
        update students set
          student_id = ${data.student_id},
          student_name = ${data.student_name},
          student_email = ${data.student_email},
          phone_number = ${data.phone_number},
          programme = ${data.programme},
          year_of_study = ${data.year_of_study},
          password_hash = ${passwordHash}
        where student_id = ${originalStudentId}
      `;
    } else {
      // Leave the existing password hash untouched when the field is left
      // blank — the admin isn't required to reset a password on every edit.
      await sql`
        update students set
          student_id = ${data.student_id},
          student_name = ${data.student_name},
          student_email = ${data.student_email},
          phone_number = ${data.phone_number},
          programme = ${data.programme},
          year_of_study = ${data.year_of_study}
        where student_id = ${originalStudentId}
      `;
    }
  } catch (err) {
    return { error: dbErrorMessage(err, "student") };
  }

  revalidatePath("/students");
  revalidatePath(`/students/${encodeURIComponent(data.student_id)}`);
  return { success: true };
}

export async function deleteStudent(studentId: string) {
  await sql`delete from students where student_id = ${studentId}`;
  revalidatePath("/students");
}

function dbErrorMessage(err: unknown, entity: string): string {
  const message = err instanceof Error ? err.message : String(err);
  if (message.includes("duplicate key")) {
    return `A ${entity} with that ID or email already exists.`;
  }
  return `Couldn't save this ${entity}. ${message}`;
}

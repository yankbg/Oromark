"use client";

import { useActionState } from "react";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { Student } from "@/lib/types";
import type { StudentFormState } from "@/lib/actions/students";

export function StudentForm({
  student,
  action,
  submitLabel,
}: {
  student?: Student;
  action: (state: StudentFormState, formData: FormData) => Promise<StudentFormState>;
  submitLabel: string;
}) {
  const router = useRouter();
  const [state, formAction, pending] = useActionState(action, {});

  useEffect(() => {
    if (state.success) {
      toast.success(student ? "Student updated" : "Student added");
      router.push("/students");
    }
  }, [state.success, router, student]);

  return (
    <form action={formAction} className="flex flex-col gap-5">
      <div className="grid gap-5 sm:grid-cols-2">
        <Field label="Student ID" name="student_id" defaultValue={student?.student_id} required />
        <Field label="Full name" name="student_name" defaultValue={student?.student_name} required />
        <Field
          label="Email"
          name="student_email"
          type="email"
          defaultValue={student?.student_email}
          required
        />
        <Field
          label="Phone number"
          name="phone_number"
          defaultValue={student?.phone_number}
          required
        />
        <Field label="Programme" name="programme" defaultValue={student?.programme} required />
        <Field
          label="Year of study"
          name="year_of_study"
          defaultValue={student?.year_of_study}
          required
        />
        <Field
          label={student ? "Password (leave blank to keep current)" : "Password"}
          name="password"
          type="password"
          required={!student}
        />
      </div>

      {student?.avatar_url ? (
        <p className="text-xs text-muted-foreground">
          Avatar is set from the mobile app and can&apos;t be edited here.
        </p>
      ) : null}

      {state.error ? (
        <p role="alert" className="text-sm text-destructive">
          {state.error}
        </p>
      ) : null}

      <div className="flex gap-2">
        <Button type="submit" disabled={pending}>
          {pending ? "Saving…" : submitLabel}
        </Button>
        <Button type="button" variant="outline" onClick={() => router.back()}>
          Cancel
        </Button>
      </div>
    </form>
  );
}

function Field({
  label,
  name,
  defaultValue,
  type = "text",
  required,
}: {
  label: string;
  name: string;
  defaultValue?: string;
  type?: string;
  required?: boolean;
}) {
  return (
    <div className="flex flex-col gap-2">
      <Label htmlFor={name}>{label}</Label>
      <Input id={name} name={name} type={type} defaultValue={defaultValue} required={required} />
    </div>
  );
}

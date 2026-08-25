"use client";

import { useActionState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { Lecturer } from "@/lib/types";
import type { LecturerFormState } from "@/lib/actions/lecturers";

export function LecturerForm({
  lecturer,
  action,
  submitLabel,
}: {
  lecturer?: Lecturer;
  action: (state: LecturerFormState, formData: FormData) => Promise<LecturerFormState>;
  submitLabel: string;
}) {
  const router = useRouter();
  const [state, formAction, pending] = useActionState(action, {});

  useEffect(() => {
    if (state.success) {
      toast.success(lecturer ? "Lecturer updated" : "Lecturer added");
      router.push("/lecturers");
    }
  }, [state.success, router, lecturer]);

  return (
    <div className="rounded-xl border border-border bg-card p-6">
      <form action={formAction} className="flex flex-col gap-5">
        <div className="grid gap-5 sm:grid-cols-2">
          <Field label="Lecturer ID" name="lecturer_id" defaultValue={lecturer?.lecturer_id} required />
          <Field label="Full name" name="lecturer_name" defaultValue={lecturer?.lecturer_name} required />
          <Field
            label="Email"
            name="lecturer_email"
            type="email"
            defaultValue={lecturer?.lecturer_email}
            required
          />
          <Field label="Department" name="department" defaultValue={lecturer?.department} required />
        </div>

        {state.error ? (
          <p role="alert" className="text-sm text-destructive">
            {state.error}
          </p>
        ) : null}

        <div className="flex gap-2 border-t border-border pt-5">
          <Button type="submit" disabled={pending}>
            {pending ? "Saving…" : submitLabel}
          </Button>
          <Button type="button" variant="outline" onClick={() => router.back()}>
            Cancel
          </Button>
        </div>
      </form>
    </div>
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

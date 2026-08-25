"use client";

import { useActionState, useEffect, useState, useTransition } from "react";
import { UserPlus, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type { EnrolledStudent, Student } from "@/lib/types";
import type { EnrollFormState } from "@/lib/actions/enrollment";

export function EnrollmentManager({
  courseCode,
  enrolled,
  enrollable,
  enrollAction,
  unenrollAction,
}: {
  courseCode: string;
  enrolled: EnrolledStudent[];
  enrollable: Student[];
  enrollAction: (state: EnrollFormState, formData: FormData) => Promise<EnrollFormState>;
  unenrollAction: (studentId: string) => Promise<void>;
}) {
  const [state, formAction, pending] = useActionState(enrollAction, {});
  const [selected, setSelected] = useState<string>("");
  const [removing, startRemoving] = useTransition();

  useEffect(() => {
    if (state.success) {
      toast.success("Student enrolled");
      // Reacting to a completed server action, not mirroring render output.
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setSelected("");
    }
  }, [state.success]);

  return (
    <div className="rounded-lg border border-border bg-card">
      <div className="flex flex-col gap-3 border-b border-border p-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h2 className="font-display text-base font-semibold text-foreground">
            Enrolled students
          </h2>
          <p className="text-sm text-muted-foreground">
            {enrolled.length} student{enrolled.length === 1 ? "" : "s"} enrolled in {courseCode}
          </p>
        </div>
        {enrollable.length > 0 ? (
          <form action={formAction} className="flex items-center gap-2">
            <Select name="student_id" value={selected} onValueChange={setSelected}>
              <SelectTrigger className="w-56">
                <SelectValue placeholder="Choose a student" />
              </SelectTrigger>
              <SelectContent>
                {enrollable.map((s) => (
                  <SelectItem key={s.student_id} value={s.student_id}>
                    {s.student_name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            <Button type="submit" disabled={!selected || pending} size="sm">
              <UserPlus />
              Enroll
            </Button>
          </form>
        ) : null}
      </div>

      {state.error ? (
        <p role="alert" className="px-4 pt-3 text-sm text-destructive">
          {state.error}
        </p>
      ) : null}

      {enrolled.length === 0 ? (
        <p className="px-4 py-10 text-center text-sm text-muted-foreground">
          No students enrolled yet.
        </p>
      ) : (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Student ID</TableHead>
              <TableHead className="w-12" />
            </TableRow>
          </TableHeader>
          <TableBody>
            {enrolled.map((e) => (
              <TableRow key={e.student_id}>
                <TableCell className="font-medium text-foreground">{e.full_name}</TableCell>
                <TableCell className="font-mono text-xs text-muted-foreground">
                  {e.student_id}
                </TableCell>
                <TableCell>
                  <Button
                    variant="ghost"
                    size="icon-sm"
                    disabled={removing}
                    aria-label={`Remove ${e.full_name} from ${courseCode}`}
                    onClick={() =>
                      startRemoving(async () => {
                        await unenrollAction(e.student_id);
                        toast.success(`Removed ${e.full_name}`);
                      })
                    }
                  >
                    <X />
                  </Button>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}
    </div>
  );
}

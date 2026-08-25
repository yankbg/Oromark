"use client";

import { useActionState, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { CourseWithLecturer } from "@/lib/types";
import type { CourseFormState } from "@/lib/actions/courses";

export function CourseForm({
  course,
  lecturerOptions,
  action,
  submitLabel,
}: {
  course?: CourseWithLecturer;
  lecturerOptions: { lecturer_id: string; lecturer_name: string }[];
  action: (state: CourseFormState, formData: FormData) => Promise<CourseFormState>;
  submitLabel: string;
}) {
  const router = useRouter();
  const [state, formAction, pending] = useActionState(action, {});
  const [lecturerId, setLecturerId] = useState(course?.lecturer_id ?? "__none__");

  useEffect(() => {
    if (state.success) {
      toast.success(course ? "Course updated" : "Course added");
      router.push("/courses");
    }
  }, [state.success, router, course]);

  return (
    <form action={formAction} className="flex flex-col gap-5">
      <div className="grid gap-5 sm:grid-cols-2">
        <div className="flex flex-col gap-2">
          <Label htmlFor="course_code">Course code</Label>
          <Input id="course_code" name="course_code" defaultValue={course?.course_code} required />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="course_name">Course name</Label>
          <Input id="course_name" name="course_name" defaultValue={course?.course_name} required />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="course_group">Group / cohort</Label>
          <Input
            id="course_group"
            name="course_group"
            defaultValue={course?.course_group ?? ""}
            placeholder="Optional"
          />
        </div>
        <div className="flex flex-col gap-2">
          <Label htmlFor="lecturer_id">Lecturer</Label>
          <Select name="lecturer_id" value={lecturerId} onValueChange={setLecturerId}>
            <SelectTrigger id="lecturer_id" className="w-full">
              <SelectValue placeholder="Unassigned" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="__none__">Unassigned</SelectItem>
              {lecturerOptions.map((l) => (
                <SelectItem key={l.lecturer_id} value={l.lecturer_id}>
                  {l.lecturer_name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
      </div>

      {course ? (
        <div className="grid grid-cols-2 gap-5 rounded-lg border border-border bg-muted/40 px-4 py-3 text-sm sm:max-w-sm">
          <div>
            <p className="text-muted-foreground">Enrolled</p>
            <p className="font-mono font-medium text-foreground">{course.enrolled}</p>
          </div>
          <div>
            <p className="text-muted-foreground">Avg. attendance</p>
            <p className="font-mono font-medium text-foreground">{course.avg_attendance}%</p>
          </div>
        </div>
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

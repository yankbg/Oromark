import { notFound } from "next/navigation";
import { PageHeader } from "@/components/page-header";
import { CourseForm } from "@/components/course-form";
import { EnrollmentManager } from "@/components/enrollment-manager";
import { SessionsTable } from "@/components/sessions-table";
import { CourseDeleteButton } from "./course-delete-button";
import { getCourse, updateCourse, deleteCourse } from "@/lib/actions/courses";
import { listLecturerOptions } from "@/lib/actions/lecturers";
import {
  listEnrolledStudents,
  listEnrollableStudents,
  enrollStudent,
  unenrollStudent,
} from "@/lib/actions/enrollment";
import { getSessionsForCourse } from "@/lib/actions/sessions";
import { safeFetch } from "@/lib/safe-fetch";

export default async function CourseDetailPage({
  params,
}: {
  params: Promise<{ code: string }>;
}) {
  const { code } = await params;
  const courseCode = decodeURIComponent(code);

  const [course, lecturerOptions, enrolled, enrollable] = await Promise.all([
    getCourse(courseCode),
    listLecturerOptions(),
    listEnrolledStudents(courseCode),
    listEnrollableStudents(courseCode),
  ]);

  if (!course) notFound();

  // Fetched after the notFound() check (only makes sense for a real
  // course) and independently from the Promise.all above, so a sessions
  // query failure degrades to an empty list instead of taking the whole
  // page down.
  const { data: sessions, failed: sessionsFailed } = await safeFetch(
    () => getSessionsForCourse(course.course_code),
    []
  );

  const boundUpdate = updateCourse.bind(null, course.course_code);
  const boundDelete = deleteCourse.bind(null, course.course_code);
  const boundEnroll = enrollStudent.bind(null, course.course_code);
  const boundUnenroll = unenrollStudent.bind(null, course.course_code);

  return (
    <div className="flex flex-col gap-8">
      <div className="max-w-2xl">
        <PageHeader
          title={course.course_name}
          back={{ href: "/courses", label: "Courses" }}
          actions={<CourseDeleteButton action={boundDelete} />}
        />
        <CourseForm
          course={course}
          lecturerOptions={lecturerOptions}
          action={boundUpdate}
          submitLabel="Save changes"
        />
      </div>

      <EnrollmentManager
        courseCode={course.course_code}
        enrolled={enrolled}
        enrollable={enrollable}
        enrollAction={boundEnroll}
        unenrollAction={boundUnenroll}
      />

      <div>
        <h2 className="mb-3 text-lg font-semibold text-foreground">
          Sessions ({sessions.length})
        </h2>
        {sessionsFailed ? (
          <div className="mb-4 rounded-lg border border-[var(--oro-warning)]/30 bg-[var(--oro-warning)]/10 px-4 py-2.5 text-sm text-[var(--oro-warning)]">
            Couldn&apos;t load sessions just now — refresh to retry.
          </div>
        ) : null}
        <SessionsTable
          sessions={sessions}
          showCourse={false}
          emptyTitle="No sessions yet"
          emptyHint="Sessions appear here once a lecturer teaching this course ends a class and their phone syncs."
        />
      </div>
    </div>
  );
}

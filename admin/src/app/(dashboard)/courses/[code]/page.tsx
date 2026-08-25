import { notFound } from "next/navigation";
import { PageHeader } from "@/components/page-header";
import { CourseForm } from "@/components/course-form";
import { EnrollmentManager } from "@/components/enrollment-manager";
import { CourseDeleteButton } from "./course-delete-button";
import { getCourse, updateCourse, deleteCourse } from "@/lib/actions/courses";
import { listLecturerOptions } from "@/lib/actions/lecturers";
import {
  listEnrolledStudents,
  listEnrollableStudents,
  enrollStudent,
  unenrollStudent,
} from "@/lib/actions/enrollment";

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
    </div>
  );
}

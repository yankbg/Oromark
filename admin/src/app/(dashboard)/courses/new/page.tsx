import { PageHeader } from "@/components/page-header";
import { CourseForm } from "@/components/course-form";
import { createCourse } from "@/lib/actions/courses";
import { listLecturerOptions } from "@/lib/actions/lecturers";

export default async function NewCoursePage() {
  const lecturerOptions = await listLecturerOptions();

  return (
    <div className="max-w-2xl">
      <PageHeader title="Add course" back={{ href: "/courses", label: "Courses" }} />
      <CourseForm action={createCourse} lecturerOptions={lecturerOptions} submitLabel="Add course" />
    </div>
  );
}

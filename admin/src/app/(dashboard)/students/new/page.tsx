import { PageHeader } from "@/components/page-header";
import { StudentForm } from "@/components/student-form";
import { createStudent } from "@/lib/actions/students";

export default function NewStudentPage() {
  return (
    <div className="max-w-2xl">
      <PageHeader
        title="Add student"
        back={{ href: "/students", label: "Students" }}
      />
      <StudentForm action={createStudent} submitLabel="Add student" />
    </div>
  );
}

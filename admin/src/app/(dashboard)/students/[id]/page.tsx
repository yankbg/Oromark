import { notFound } from "next/navigation";
import { PageHeader } from "@/components/page-header";
import { StudentForm } from "@/components/student-form";
import { StudentDeleteButton } from "./student-delete-button";
import { getStudent, updateStudent, deleteStudent } from "@/lib/actions/students";

export default async function EditStudentPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const student = await getStudent(decodeURIComponent(id));
  if (!student) notFound();

  const boundUpdate = updateStudent.bind(null, student.student_id);
  const boundDelete = deleteStudent.bind(null, student.student_id);

  return (
    <div className="max-w-2xl">
      <PageHeader
        title={student.student_name}
        back={{ href: "/students", label: "Students" }}
        actions={<StudentDeleteButton action={boundDelete} />}
      />
      <StudentForm student={student} action={boundUpdate} submitLabel="Save changes" />
    </div>
  );
}

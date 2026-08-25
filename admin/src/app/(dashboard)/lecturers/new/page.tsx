import { PageHeader } from "@/components/page-header";
import { LecturerForm } from "@/components/lecturer-form";
import { createLecturer } from "@/lib/actions/lecturers";

export default function NewLecturerPage() {
  return (
    <div className="max-w-2xl">
      <PageHeader title="Add lecturer" back={{ href: "/lecturers", label: "Lecturers" }} />
      <LecturerForm action={createLecturer} submitLabel="Add lecturer" />
    </div>
  );
}

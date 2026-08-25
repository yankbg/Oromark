import { notFound } from "next/navigation";
import { PageHeader } from "@/components/page-header";
import { LecturerForm } from "@/components/lecturer-form";
import { LecturerDeleteButton } from "./lecturer-delete-button";
import { getLecturer, updateLecturer, deleteLecturer } from "@/lib/actions/lecturers";

export default async function EditLecturerPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const lecturer = await getLecturer(decodeURIComponent(id));
  if (!lecturer) notFound();

  const boundUpdate = updateLecturer.bind(null, lecturer.lecturer_id);
  const boundDelete = deleteLecturer.bind(null, lecturer.lecturer_id);

  return (
    <div className="max-w-2xl">
      <PageHeader
        title={lecturer.lecturer_name}
        back={{ href: "/lecturers", label: "Lecturers" }}
        actions={<LecturerDeleteButton action={boundDelete} />}
      />
      <LecturerForm lecturer={lecturer} action={boundUpdate} submitLabel="Save changes" />
    </div>
  );
}

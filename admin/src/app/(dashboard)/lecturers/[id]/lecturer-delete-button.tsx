"use client";

import { useRouter } from "next/navigation";
import { DeleteButton } from "@/components/delete-button";

export function LecturerDeleteButton({ action }: { action: () => Promise<void> }) {
  const router = useRouter();
  return (
    <DeleteButton
      action={action}
      itemLabel="lecturer"
      onDone={() => router.push("/lecturers")}
    />
  );
}

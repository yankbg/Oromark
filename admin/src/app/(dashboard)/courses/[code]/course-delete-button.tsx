"use client";

import { useRouter } from "next/navigation";
import { DeleteButton } from "@/components/delete-button";

export function CourseDeleteButton({ action }: { action: () => Promise<void> }) {
  const router = useRouter();
  return (
    <DeleteButton action={action} itemLabel="course" onDone={() => router.push("/courses")} />
  );
}

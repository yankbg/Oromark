"use client";

import { useRouter } from "next/navigation";
import { DeleteButton } from "@/components/delete-button";

export function StudentDeleteButton({ action }: { action: () => Promise<void> }) {
  const router = useRouter();
  return (
    <DeleteButton action={action} itemLabel="student" onDone={() => router.push("/students")} />
  );
}

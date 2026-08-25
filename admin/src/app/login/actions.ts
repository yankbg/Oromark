"use server";

import { redirect } from "next/navigation";
import { checkPassword, createSession } from "@/lib/auth";

export async function login(_prevState: { error?: string } | undefined, formData: FormData) {
  const password = String(formData.get("password") ?? "");
  const from = String(formData.get("from") ?? "/");

  if (!checkPassword(password)) {
    return { error: "That password isn't right. Try again." };
  }

  await createSession();
  redirect(from.startsWith("/") ? from : "/");
}

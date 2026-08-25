import "server-only";
import { cookies } from "next/headers";
import crypto from "crypto";

const SESSION_COOKIE = "oromark_admin_session";

// The session cookie's value is an HMAC of a fixed marker, keyed by
// ADMIN_PASSWORD, so it can't be forged without knowing the password, and it
// carries no user-identifiable data (there is only one admin).
function sign(): string {
  const secret = process.env.ADMIN_PASSWORD;
  if (!secret) throw new Error("ADMIN_PASSWORD is not set.");
  return crypto.createHmac("sha256", secret).update("oromark-admin").digest("hex");
}

export async function createSession() {
  const store = await cookies();
  store.set(SESSION_COOKIE, sign(), {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: 60 * 60 * 24 * 14, // 14 days
  });
}

export async function destroySession() {
  const store = await cookies();
  store.delete(SESSION_COOKIE);
}

export async function isAuthenticated(): Promise<boolean> {
  const store = await cookies();
  const value = store.get(SESSION_COOKIE)?.value;
  if (!value) return false;
  try {
    return crypto.timingSafeEqual(Buffer.from(value), Buffer.from(sign()));
  } catch {
    return false;
  }
}

export function checkPassword(candidate: string): boolean {
  const expected = process.env.ADMIN_PASSWORD;
  if (!expected) return false;
  const a = Buffer.from(candidate);
  const b = Buffer.from(expected);
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}

export { SESSION_COOKIE };

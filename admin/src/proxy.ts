import { NextRequest, NextResponse } from "next/server";
import crypto from "crypto";

// Proxy (formerly "Middleware" pre-Next.js 16) runs on the Node.js runtime by
// default, so node:crypto is available here — verifies the signed session
// cookie the same way src/lib/auth.ts issues it.
export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|oromark.*\\.(?:jpg|png)).*)"],
};

const SESSION_COOKIE = "oromark_admin_session";

function expectedValue(): string | null {
  const secret = process.env.ADMIN_PASSWORD;
  if (!secret) return null;
  return crypto.createHmac("sha256", secret).update("oromark-admin").digest("hex");
}

export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  if (pathname === "/login") {
    return NextResponse.next();
  }

  const expected = expectedValue();
  const cookieValue = request.cookies.get(SESSION_COOKIE)?.value;

  const authenticated =
    !!expected &&
    !!cookieValue &&
    cookieValue.length === expected.length &&
    crypto.timingSafeEqual(Buffer.from(cookieValue), Buffer.from(expected));

  if (!authenticated) {
    const loginUrl = new URL("/login", request.url);
    loginUrl.searchParams.set("from", pathname);
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

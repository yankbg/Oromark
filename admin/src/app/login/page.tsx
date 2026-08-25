import { LoginForm } from "./login-form";

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ from?: string }>;
}) {
  const { from } = await searchParams;

  return (
    <div className="relative flex min-h-dvh items-center justify-center overflow-hidden bg-[var(--oro-tertiary)] px-4">
      {/* Signature: concentric broadcast rings — a quiet nod to the UDP
          session signal this dashboard mirrors data from. */}
      <div
        aria-hidden
        className="pointer-events-none absolute -right-32 -top-32 size-[560px] rounded-full border border-white/[0.06]"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute -right-32 -top-32 size-[420px] rounded-full border border-white/[0.08]"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute -right-32 -top-32 size-[280px] rounded-full border border-white/[0.1]"
      />
      <div
        aria-hidden
        className="pointer-events-none absolute -bottom-40 -left-24 size-[420px] rounded-full border border-white/[0.06]"
      />

      <div className="relative w-full max-w-sm">
        <LoginForm from={from ?? "/"} />
      </div>
    </div>
  );
}

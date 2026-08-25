"use client";

import { useActionState } from "react";
import Image from "next/image";
import { Lock } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { login } from "./actions";

export function LoginForm({ from }: { from: string }) {
  const [state, formAction, pending] = useActionState(login, undefined);

  return (
    <div className="rounded-xl border border-white/10 bg-[var(--oro-bg-primary)] p-8 shadow-[0_24px_60px_-20px_rgb(0_0_0_/_0.45)]">
      <div className="mb-7 flex flex-col items-center text-center">
        <Image
          src="/oromark-wordmark.png"
          alt="OROmark"
          width={168}
          height={32}
          className="mb-5 h-8 w-auto"
          priority
        />
        <h1 className="font-display text-xl font-semibold tracking-tight text-foreground">
          OROmark Admin
        </h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Sign in to manage students, lecturers, and courses.
        </p>
      </div>

      <form action={formAction} className="flex flex-col gap-4">
        <input type="hidden" name="from" value={from} />
        <div className="flex flex-col gap-2">
          <Label htmlFor="password">Admin password</Label>
          <div className="relative">
            <Lock className="pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              id="password"
              name="password"
              type="password"
              autoComplete="current-password"
              autoFocus
              required
              className="pl-8"
              aria-invalid={!!state?.error}
            />
          </div>
          {state?.error ? (
            <p role="alert" className="text-sm text-destructive">
              {state.error}
            </p>
          ) : null}
        </div>

        <Button type="submit" className="mt-1 w-full" disabled={pending}>
          {pending ? "Signing in…" : "Sign in"}
        </Button>
      </form>
    </div>
  );
}

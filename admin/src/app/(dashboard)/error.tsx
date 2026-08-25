"use client";

import { useEffect } from "react";
import { DatabaseZap } from "lucide-react";
import { Button } from "@/components/ui/button";

// Neon's pooler can go through an extended rough patch (well beyond what
// the retry wrapper in lib/db.ts can transparently absorb — see its
// comment) where every connection attempt fails for a stretch of minutes.
// When that happens, show something a non-technical admin can act on
// instead of Next.js's raw stack-trace crash screen.
export default function DashboardError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center gap-4 px-6 text-center">
      <div className="flex size-12 items-center justify-center rounded-2xl bg-destructive/10 text-destructive">
        <DatabaseZap className="size-6" />
      </div>
      <div className="max-w-sm">
        <h1 className="font-display text-xl font-semibold tracking-tight text-foreground">
          Couldn&apos;t reach the database
        </h1>
        <p className="mt-2 text-sm text-muted-foreground">
          This usually clears up within a few seconds. Try again in a moment.
        </p>
      </div>
      <Button onClick={() => reset()}>Try again</Button>
    </div>
  );
}

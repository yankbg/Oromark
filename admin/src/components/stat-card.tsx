import type { LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";

export function StatCard({
  label,
  value,
  icon: Icon,
  hint,
  hintTone = "neutral",
  accent = "primary",
}: {
  label: string;
  value: string | number;
  icon: LucideIcon;
  hint?: string;
  hintTone?: "neutral" | "positive";
  accent?: "primary" | "accent" | "success" | "secondary";
}) {
  const accentClasses: Record<string, string> = {
    primary: "bg-primary/10 text-primary",
    accent: "bg-[var(--oro-accent)]/10 text-[var(--oro-accent)]",
    success: "bg-[var(--oro-success)]/10 text-[var(--oro-success)]",
    secondary: "bg-[var(--oro-secondary)]/10 text-[var(--oro-secondary)]",
  };

  return (
    <div className="rounded-xl border border-border bg-card p-5">
      <div className="flex items-start justify-between gap-3">
        <div className={cn("flex size-9 items-center justify-center rounded-lg", accentClasses[accent])}>
          <Icon className="size-4.5" />
        </div>
      </div>
      <p className="mt-4 font-mono text-[1.75rem] leading-none font-medium tracking-tight text-foreground">
        {value}
      </p>
      <p className="mt-2 text-sm text-muted-foreground">{label}</p>
      {hint ? (
        <p
          className={cn(
            "mt-2 inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium",
            hintTone === "positive"
              ? "bg-[var(--oro-success)]/10 text-[var(--oro-success)]"
              : "bg-muted text-muted-foreground"
          )}
        >
          {hint}
        </p>
      ) : null}
    </div>
  );
}

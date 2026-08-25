import type { LucideIcon } from "lucide-react";
import { cn } from "@/lib/utils";

export function StatCard({
  label,
  value,
  icon: Icon,
  hint,
  accent = "primary",
}: {
  label: string;
  value: string | number;
  icon: LucideIcon;
  hint?: string;
  accent?: "primary" | "accent" | "success" | "secondary";
}) {
  const accentClasses: Record<string, string> = {
    primary: "bg-primary/10 text-primary",
    accent: "bg-[var(--oro-accent)]/10 text-[var(--oro-accent)]",
    success: "bg-[var(--oro-success)]/10 text-[var(--oro-success)]",
    secondary: "bg-[var(--oro-secondary)]/10 text-[var(--oro-secondary)]",
  };

  return (
    <div className="rounded-lg border border-border bg-card p-5">
      <div className="flex items-start justify-between">
        <p className="text-sm text-muted-foreground">{label}</p>
        <div className={cn("flex size-8 items-center justify-center rounded-md", accentClasses[accent])}>
          <Icon className="size-4" />
        </div>
      </div>
      <p className="mt-3 font-mono text-3xl font-medium tracking-tight text-foreground">{value}</p>
      {hint ? <p className="mt-1 text-xs text-muted-foreground">{hint}</p> : null}
    </div>
  );
}

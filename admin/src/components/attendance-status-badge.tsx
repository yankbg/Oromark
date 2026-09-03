const STYLES: Record<string, string> = {
  present: "bg-[var(--oro-live-bg)] text-[var(--oro-live-text)]",
  late: "bg-[var(--oro-warning)]/15 text-[var(--oro-warning)]",
  absent: "bg-[var(--oro-error)]/15 text-[var(--oro-error)]",
};

export function AttendanceStatusBadge({ status }: { status: string }) {
  const key = status.toLowerCase();
  const style = STYLES[key] ?? "bg-muted text-muted-foreground";
  return (
    <span
      className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium capitalize ${style}`}
    >
      {key}
    </span>
  );
}

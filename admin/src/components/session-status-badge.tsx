const LIVE_STATUSES = new Set(["live", "active", "scheduled"]);

const STYLES: Record<string, string> = {
  live: "bg-[var(--oro-live-bg)] text-[var(--oro-live-text)]",
  active: "bg-[var(--oro-live-bg)] text-[var(--oro-live-text)]",
  scheduled: "bg-[var(--oro-live-bg)] text-[var(--oro-live-text)]",
  ended: "bg-muted text-muted-foreground",
};

export function SessionStatusBadge({ status }: { status: string }) {
  const key = status.toLowerCase();
  const style = STYLES[key] ?? "bg-muted text-muted-foreground";
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-xs font-medium capitalize ${style}`}
    >
      {LIVE_STATUSES.has(key) ? (
        <span className="size-1.5 rounded-full bg-[var(--oro-live-text)] animate-pulse" />
      ) : null}
      {status.toLowerCase()}
    </span>
  );
}

import Link from "next/link";
import { Search, CalendarX2 } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Input } from "@/components/ui/input";
import { SessionStatusBadge } from "@/components/session-status-badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { listSessions } from "@/lib/actions/sessions";
import { safeFetch } from "@/lib/safe-fetch";

function formatDateTime(iso: string) {
  return new Date(iso).toLocaleString(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  });
}

export default async function SessionsPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q } = await searchParams;
  const { data: sessions, failed } = await safeFetch(() => listSessions(q), []);

  return (
    <div>
      <PageHeader
        title="Sessions"
        description={`${sessions.length} session${sessions.length === 1 ? "" : "s"} synced from lecturers' phones`}
      />

      {failed ? (
        <div className="mb-4 rounded-lg border border-[var(--oro-warning)]/30 bg-[var(--oro-warning)]/10 px-4 py-2.5 text-sm text-[var(--oro-warning)]">
          Couldn&apos;t load sessions just now — refresh to retry.
        </div>
      ) : null}

      <form className="mb-4 max-w-sm">
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            name="q"
            placeholder="Search by course, room, or lecturer"
            defaultValue={q}
            className="pl-9"
          />
        </div>
      </form>

      <div className="overflow-hidden rounded-xl border border-border bg-card">
        {sessions.length === 0 ? (
          <div className="flex flex-col items-center gap-2 px-6 py-16 text-center">
            <CalendarX2 className="size-8 text-muted-foreground/50" />
            <p className="text-sm font-medium text-foreground">
              {q ? "No sessions match that search" : "No sessions yet"}
            </p>
            <p className="text-sm text-muted-foreground">
              {q
                ? "Try a different course, room, or lecturer."
                : "Sessions appear here once a lecturer ends a class and their phone syncs."}
            </p>
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Course</TableHead>
                <TableHead>Room</TableHead>
                <TableHead className="hidden md:table-cell">Lecturer</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="hidden sm:table-cell">Started</TableHead>
                <TableHead className="text-right">Present</TableHead>
                <TableHead className="text-right">Late</TableHead>
                <TableHead className="text-right">Absent</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {sessions.map((s) => (
                <TableRow key={s.session_id} className="cursor-pointer">
                  <TableCell className="p-0">
                    <Link
                      href={`/sessions/${encodeURIComponent(s.session_id)}`}
                      className="flex flex-col gap-0.5 px-4 py-3"
                    >
                      <span className="font-medium text-foreground">{s.course_code}</span>
                      <span className="text-xs text-muted-foreground">{s.course_name}</span>
                    </Link>
                  </TableCell>
                  <TableCell className="font-mono text-xs text-muted-foreground">
                    {s.room_code}
                  </TableCell>
                  <TableCell className="hidden text-muted-foreground md:table-cell">
                    {s.lecturer_name ?? "—"}
                  </TableCell>
                  <TableCell>
                    <SessionStatusBadge status={s.status} />
                  </TableCell>
                  <TableCell className="hidden text-muted-foreground sm:table-cell">
                    {formatDateTime(s.start_time)}
                  </TableCell>
                  <TableCell className="text-right text-foreground">{s.present}</TableCell>
                  <TableCell className="text-right text-foreground">{s.late}</TableCell>
                  <TableCell className="text-right text-foreground">{s.absent}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </div>
    </div>
  );
}

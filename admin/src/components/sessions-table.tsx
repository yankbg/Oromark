import Link from "next/link";
import { CalendarX2 } from "lucide-react";
import { SessionStatusBadge } from "@/components/session-status-badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import type { SessionWithCounts } from "@/lib/actions/sessions";

function formatDateTime(iso: string) {
  return new Date(iso).toLocaleString(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  });
}

/** Shared by the all-courses /sessions list and a single course's session
 * history on its detail page — [showCourse] hides the redundant Course
 * column when the table is already scoped to one course. */
export function SessionsTable({
  sessions,
  showCourse = true,
  emptyTitle = "No sessions yet",
  emptyHint = "Sessions appear here once a lecturer ends a class and their phone syncs.",
}: {
  sessions: SessionWithCounts[];
  showCourse?: boolean;
  emptyTitle?: string;
  emptyHint?: string;
}) {
  if (sessions.length === 0) {
    return (
      <div className="flex flex-col items-center gap-2 rounded-xl border border-border bg-card px-6 py-16 text-center">
        <CalendarX2 className="size-8 text-muted-foreground/50" />
        <p className="text-sm font-medium text-foreground">{emptyTitle}</p>
        <p className="text-sm text-muted-foreground">{emptyHint}</p>
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-xl border border-border bg-card">
      <Table>
        <TableHeader>
          <TableRow>
            {showCourse ? <TableHead>Course</TableHead> : null}
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
              {showCourse ? (
                <TableCell className="p-0">
                  <Link
                    href={`/sessions/${encodeURIComponent(s.session_id)}`}
                    className="flex flex-col gap-0.5 px-4 py-3"
                  >
                    <span className="font-medium text-foreground">{s.course_code}</span>
                    <span className="text-xs text-muted-foreground">{s.course_name}</span>
                  </Link>
                </TableCell>
              ) : (
                <TableCell className="p-0">
                  <Link
                    href={`/sessions/${encodeURIComponent(s.session_id)}`}
                    className="block px-4 py-3 font-mono text-xs text-muted-foreground"
                  >
                    {s.room_code}
                  </Link>
                </TableCell>
              )}
              {showCourse ? (
                <TableCell className="font-mono text-xs text-muted-foreground">
                  {s.room_code}
                </TableCell>
              ) : null}
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
    </div>
  );
}

import { notFound } from "next/navigation";
import { Users2, CheckCircle2, Clock3, XCircle, Users } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { SessionStatusBadge } from "@/components/session-status-badge";
import { AttendanceStatusBadge } from "@/components/attendance-status-badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { StatCard } from "@/components/stat-card";
import { getSessionDetail } from "@/lib/actions/sessions";

function formatDateTime(iso: string) {
  return new Date(iso).toLocaleString(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  });
}

export default async function SessionDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const sessionId = decodeURIComponent(id);

  const detail = await getSessionDetail(sessionId);
  if (!detail) notFound();

  const { session, attendance } = detail;
  const present = attendance.filter((a) => a.status.toLowerCase() === "present").length;
  const late = attendance.filter((a) => a.status.toLowerCase() === "late").length;
  const absent = attendance.filter((a) => a.status.toLowerCase() === "absent").length;

  return (
    <div className="flex flex-col gap-8">
      <div>
        <PageHeader
          title={`${session.course_code} — ${session.room_code}`}
          description={session.course_name}
          back={{ href: "/sessions", label: "Sessions" }}
          actions={<SessionStatusBadge status={session.status} />}
        />

        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          <StatCard label="Present" value={present} icon={CheckCircle2} accent="success" />
          <StatCard label="Late" value={late} icon={Clock3} accent="secondary" />
          <StatCard label="Absent" value={absent} icon={XCircle} accent="accent" />
          <StatCard label="Enrolled" value={attendance.length} icon={Users} accent="primary" />
        </div>

        <dl className="mt-6 grid grid-cols-1 gap-x-8 gap-y-3 rounded-xl border border-border bg-card p-4 text-sm sm:grid-cols-2 lg:grid-cols-3">
          <div>
            <dt className="text-muted-foreground">Lecturer</dt>
            <dd className="font-medium text-foreground">{session.lecturer_name ?? "—"}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Room code</dt>
            <dd className="font-mono font-medium text-foreground">{session.room_code}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Started</dt>
            <dd className="font-medium text-foreground">{formatDateTime(session.start_time)}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Ended</dt>
            <dd className="font-medium text-foreground">{formatDateTime(session.end_time)}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Session ID</dt>
            <dd className="font-mono text-xs text-foreground">{session.session_id}</dd>
          </div>
          <div>
            <dt className="text-muted-foreground">Synced</dt>
            <dd className="font-medium text-foreground">{formatDateTime(session.synced_at)}</dd>
          </div>
        </dl>
      </div>

      <div>
        <h2 className="mb-3 text-lg font-semibold text-foreground">Attendance</h2>
        <div className="overflow-hidden rounded-xl border border-border bg-card">
          {attendance.length === 0 ? (
            <div className="flex flex-col items-center gap-2 px-6 py-16 text-center">
              <Users2 className="size-8 text-muted-foreground/50" />
              <p className="text-sm font-medium text-foreground">No attendance records</p>
              <p className="text-sm text-muted-foreground">
                Nothing has synced for this session yet.
              </p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Student</TableHead>
                  <TableHead>Student ID</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Recorded at</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {attendance.map((a) => (
                  <TableRow key={a.student_id}>
                    <TableCell className="font-medium text-foreground">
                      {a.student_name ?? "—"}
                    </TableCell>
                    <TableCell className="font-mono text-xs text-muted-foreground">
                      {a.student_id}
                    </TableCell>
                    <TableCell>
                      <AttendanceStatusBadge status={a.status} />
                    </TableCell>
                    <TableCell className="text-right text-muted-foreground">
                      {formatDateTime(a.timestamp)}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </div>
      </div>
    </div>
  );
}

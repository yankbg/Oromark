import Link from "next/link";
import { GraduationCap, UsersRound, BookOpen, Radio, TrendingUp } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { SessionStatusBadge } from "@/components/session-status-badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { getDashboardStats, getRecentSessions } from "@/lib/actions/dashboard";

function formatDate(iso: string) {
  return new Intl.DateTimeFormat("en-GB", {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(iso));
}

export default async function OverviewPage() {
  const [stats, sessions] = await Promise.all([getDashboardStats(), getRecentSessions()]);

  return (
    <div>
      <PageHeader
        title="Overview"
        description="What's synced from the field right now."
      />

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Students" value={stats.studentCount} icon={GraduationCap} accent="primary" />
        <StatCard label="Lecturers" value={stats.lecturerCount} icon={UsersRound} accent="secondary" />
        <StatCard label="Courses" value={stats.courseCount} icon={BookOpen} accent="accent" />
        <StatCard
          label="Live sessions"
          value={stats.liveSessionCount}
          icon={Radio}
          accent={stats.liveSessionCount > 0 ? "success" : "primary"}
          hint={`${stats.sessionCount} total synced`}
          hintTone={stats.liveSessionCount > 0 ? "positive" : "neutral"}
        />
      </div>

      <div className="mt-8 flex items-end justify-between">
        <h2 className="font-display text-base font-semibold tracking-tight text-foreground">
          Recent sessions
        </h2>
        {stats.avgAttendance !== null ? (
          <p className="flex items-center gap-1.5 text-sm text-muted-foreground">
            <TrendingUp className="size-3.5 text-[var(--oro-success)]" />
            {stats.avgAttendance}% avg. attendance across courses
          </p>
        ) : null}
      </div>

      <div className="mt-3 overflow-hidden rounded-xl border border-border bg-card">
        {sessions.length === 0 ? (
          <div className="flex flex-col items-center gap-2 px-6 py-16 text-center">
            <Radio className="size-8 text-muted-foreground/50" />
            <p className="text-sm font-medium text-foreground">No sessions synced yet</p>
            <p className="text-sm text-muted-foreground">
              Sessions appear here once a lecturer&apos;s phone syncs after class.
            </p>
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Course</TableHead>
                <TableHead>Lecturer</TableHead>
                <TableHead>Started</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Present</TableHead>
                <TableHead className="text-right">Late</TableHead>
                <TableHead className="text-right">Absent</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {sessions.map((s) => (
                <TableRow key={s.session_id}>
                  <TableCell className="p-0">
                    <Link
                      href={`/courses/${encodeURIComponent(s.course_code)}`}
                      className="block px-4 py-3.5 font-medium text-foreground"
                    >
                      {s.course_name}
                    </Link>
                  </TableCell>
                  <TableCell className="text-muted-foreground">{s.lecturer_name ?? "—"}</TableCell>
                  <TableCell className="text-muted-foreground">{formatDate(s.start_time)}</TableCell>
                  <TableCell>
                    <SessionStatusBadge status={s.status} />
                  </TableCell>
                  <TableCell className="text-right font-mono text-[var(--oro-present-text)]">
                    {s.present}
                  </TableCell>
                  <TableCell className="text-right font-mono text-[var(--oro-late-text)]">
                    {s.late}
                  </TableCell>
                  <TableCell className="text-right font-mono text-[var(--oro-absent-text)]">
                    {s.absent}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </div>
    </div>
  );
}

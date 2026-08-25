import Link from "next/link";
import {
  AcademicCapIcon,
  UserGroupIcon,
  BookOpenIcon,
  SignalIcon,
  ChartBarIcon,
  ChartPieIcon,
  TrophyIcon,
  ClockIcon,
} from "@heroicons/react/24/outline";
import { PageHeader } from "@/components/page-header";
import { StatCard } from "@/components/stat-card";
import { SessionStatusBadge } from "@/components/session-status-badge";
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { AttendanceTrendChart } from "@/components/charts/attendance-trend-chart";
import { AttendanceBreakdownChart } from "@/components/charts/attendance-breakdown-chart";
import { TopCoursesChart } from "@/components/charts/top-courses-chart";
import {
  getDashboardStats,
  getRecentSessions,
  getAttendanceTrend,
  getAttendanceBreakdown,
  getTopCourses,
} from "@/lib/actions/dashboard";

function formatDate(iso: string) {
  return new Intl.DateTimeFormat("en-GB", {
    day: "2-digit",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(iso));
}

export default async function OverviewPage() {
  const [stats, sessions, trend, breakdown, topCourses] = await Promise.all([
    getDashboardStats(),
    getRecentSessions(),
    getAttendanceTrend(14),
    getAttendanceBreakdown(),
    getTopCourses(6),
  ]);

  return (
    <div>
      <PageHeader
        title="Overview"
        description="What's synced from the field right now."
      />

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Students" value={stats.studentCount} icon={AcademicCapIcon} accent="primary" />
        <StatCard label="Lecturers" value={stats.lecturerCount} icon={UserGroupIcon} accent="secondary" />
        <StatCard label="Courses" value={stats.courseCount} icon={BookOpenIcon} accent="accent" />
        <StatCard
          label="Live sessions"
          value={stats.liveSessionCount}
          icon={SignalIcon}
          accent={stats.liveSessionCount > 0 ? "success" : "primary"}
          hint={`${stats.sessionCount} total synced`}
          hintTone={stats.liveSessionCount > 0 ? "positive" : "neutral"}
        />
      </div>

      <div className="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader className="flex flex-row items-center justify-between space-y-0">
            <div className="flex items-center gap-2">
              <ChartBarIcon className="size-4.5 text-muted-foreground" />
              <div>
                <CardTitle>Attendance trend</CardTitle>
                <CardDescription>Last 14 days, synced records</CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <AttendanceTrendChart data={trend} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center gap-2 space-y-0">
            <ChartPieIcon className="size-4.5 text-muted-foreground" />
            <div>
              <CardTitle>Attendance breakdown</CardTitle>
              <CardDescription>All-time, synced records</CardDescription>
            </div>
          </CardHeader>
          <CardContent>
            <AttendanceBreakdownChart
              present={breakdown.present}
              late={breakdown.late}
              absent={breakdown.absent}
            />
          </CardContent>
        </Card>
      </div>

      <div className="mt-4 grid grid-cols-1 gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader className="flex flex-row items-center gap-2 space-y-0">
            <TrophyIcon className="size-4.5 text-muted-foreground" />
            <div>
              <CardTitle>Top courses by attendance</CardTitle>
              <CardDescription>Cached average across sessions</CardDescription>
            </div>
          </CardHeader>
          <CardContent>
            <TopCoursesChart courses={topCourses} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center gap-2 space-y-0">
            <ClockIcon className="size-4.5 text-muted-foreground" />
            <div>
              <CardTitle>At a glance</CardTitle>
              <CardDescription>Synced totals</CardDescription>
            </div>
          </CardHeader>
          <CardContent className="grid gap-3">
            <div className="flex items-center justify-between rounded-lg bg-muted/50 px-3 py-2.5">
              <span className="text-sm text-muted-foreground">Total sessions synced</span>
              <span className="font-mono text-sm font-medium tabular-nums text-foreground">
                {stats.sessionCount}
              </span>
            </div>
            <div className="flex items-center justify-between rounded-lg bg-muted/50 px-3 py-2.5">
              <span className="text-sm text-muted-foreground">Attendance records</span>
              <span className="font-mono text-sm font-medium tabular-nums text-foreground">
                {stats.attendanceRecordCount}
              </span>
            </div>
            <div className="flex items-center justify-between rounded-lg bg-muted/50 px-3 py-2.5">
              <span className="text-sm text-muted-foreground">Avg. attendance</span>
              <span className="font-mono text-sm font-medium tabular-nums text-[var(--oro-success)]">
                {stats.avgAttendance !== null ? `${stats.avgAttendance}%` : "—"}
              </span>
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="mt-8 flex items-end justify-between">
        <h2 className="font-display text-lg font-semibold tracking-tight text-foreground">
          Recent sessions
        </h2>
      </div>

      <div className="mt-3 overflow-hidden rounded-xl border border-border bg-card">
        {sessions.length === 0 ? (
          <div className="flex flex-col items-center gap-2 px-6 py-16 text-center">
            <SignalIcon className="size-8 text-muted-foreground/50" />
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

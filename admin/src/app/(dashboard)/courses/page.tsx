import Link from "next/link";
import { Plus, Search, BookOpen } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { listCourses } from "@/lib/actions/courses";
import { safeFetch } from "@/lib/safe-fetch";

export default async function CoursesPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q } = await searchParams;
  const { data: courses, failed } = await safeFetch(() => listCourses(q), []);

  return (
    <div>
      <PageHeader
        title="Courses"
        description={`${courses.length} course${courses.length === 1 ? "" : "s"} on record`}
        actions={
          <Button asChild>
            <Link href="/courses/new">
              <Plus />
              Add course
            </Link>
          </Button>
        }
      />

      {failed ? (
        <div className="mb-4 rounded-lg border border-[var(--oro-warning)]/30 bg-[var(--oro-warning)]/10 px-4 py-2.5 text-sm text-[var(--oro-warning)]">
          Couldn&apos;t load courses just now — refresh to retry.
        </div>
      ) : null}

      <form className="mb-4 max-w-sm">
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            name="q"
            placeholder="Search by code, name, or group"
            defaultValue={q}
            className="pl-9"
          />
        </div>
      </form>

      <div className="overflow-hidden rounded-xl border border-border bg-card">
        {courses.length === 0 ? (
          <div className="flex flex-col items-center gap-2 px-6 py-16 text-center">
            <BookOpen className="size-8 text-muted-foreground/50" />
            <p className="text-sm font-medium text-foreground">
              {q ? "No courses match that search" : "No courses yet"}
            </p>
            <p className="text-sm text-muted-foreground">
              {q ? "Try a different code or name." : "Add a course, then assign a lecturer and enroll students."}
            </p>
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Course</TableHead>
                <TableHead>Code</TableHead>
                <TableHead>Lecturer</TableHead>
                <TableHead>Enrolled</TableHead>
                <TableHead>Avg. attendance</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {courses.map((c) => (
                <TableRow key={c.course_code}>
                  <TableCell className="p-0">
                    <Link
                      href={`/courses/${encodeURIComponent(c.course_code)}`}
                      className="block px-4 py-3.5 font-medium text-foreground"
                    >
                      {c.course_name}
                      {c.course_group ? (
                        <span className="ml-2 text-xs font-normal text-muted-foreground">
                          {c.course_group}
                        </span>
                      ) : null}
                    </Link>
                  </TableCell>
                  <TableCell className="font-mono text-xs text-muted-foreground">
                    {c.course_code}
                  </TableCell>
                  <TableCell>
                    {c.lecturer_name ? (
                      c.lecturer_name
                    ) : (
                      <Badge variant="outline" className="text-muted-foreground">
                        Unassigned
                      </Badge>
                    )}
                  </TableCell>
                  <TableCell className="font-mono">{c.enrolled}</TableCell>
                  <TableCell className="font-mono">{c.avg_attendance}%</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </div>
    </div>
  );
}

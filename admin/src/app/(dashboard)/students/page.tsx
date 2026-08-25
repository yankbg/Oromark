import Link from "next/link";
import { Plus, Search, GraduationCap } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { listStudents } from "@/lib/actions/students";

function initials(name: string) {
  return name
    .split(" ")
    .map((p) => p[0])
    .filter(Boolean)
    .slice(0, 2)
    .join("")
    .toUpperCase();
}

export default async function StudentsPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q } = await searchParams;
  const students = await listStudents(q);

  return (
    <div>
      <PageHeader
        title="Students"
        description={`${students.length} student${students.length === 1 ? "" : "s"} on record`}
        actions={
          <Button asChild>
            <Link href="/students/new">
              <Plus />
              Add student
            </Link>
          </Button>
        }
      />

      <form className="mb-4 max-w-sm">
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            name="q"
            placeholder="Search by name, ID, email, or programme"
            defaultValue={q}
            className="pl-9"
          />
        </div>
      </form>

      <div className="overflow-hidden rounded-xl border border-border bg-card">
        {students.length === 0 ? (
          <div className="flex flex-col items-center gap-2 px-6 py-16 text-center">
            <GraduationCap className="size-8 text-muted-foreground/50" />
            <p className="text-sm font-medium text-foreground">
              {q ? "No students match that search" : "No students yet"}
            </p>
            <p className="text-sm text-muted-foreground">
              {q
                ? "Try a different name, ID, or email."
                : "Students appear here once a lecturer's phone syncs enrollment data, or you can add one directly."}
            </p>
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Student</TableHead>
                <TableHead>Student ID</TableHead>
                <TableHead>Programme</TableHead>
                <TableHead>Year</TableHead>
                <TableHead className="hidden md:table-cell">Email</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {students.map((s) => (
                <TableRow key={s.student_id} className="cursor-pointer">
                  <TableCell className="p-0">
                    <Link
                      href={`/students/${encodeURIComponent(s.student_id)}`}
                      className="flex items-center gap-3 px-4 py-3"
                    >
                      <Avatar className="size-8">
                        <AvatarImage src={s.avatar_url ?? undefined} alt="" />
                        <AvatarFallback className="bg-primary/10 text-xs font-medium text-primary">
                          {initials(s.student_name)}
                        </AvatarFallback>
                      </Avatar>
                      <span className="font-medium text-foreground">{s.student_name}</span>
                    </Link>
                  </TableCell>
                  <TableCell className="font-mono text-xs text-muted-foreground">
                    {s.student_id}
                  </TableCell>
                  <TableCell>{s.programme}</TableCell>
                  <TableCell>{s.year_of_study}</TableCell>
                  <TableCell className="hidden text-muted-foreground md:table-cell">
                    {s.student_email}
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

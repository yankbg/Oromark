import Link from "next/link";
import { Plus, Search, UsersRound } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { listLecturers } from "@/lib/actions/lecturers";

export default async function LecturersPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q } = await searchParams;
  const lecturers = await listLecturers(q);

  return (
    <div>
      <PageHeader
        title="Lecturers"
        description={`${lecturers.length} lecturer${lecturers.length === 1 ? "" : "s"} on record`}
        actions={
          <Button asChild>
            <Link href="/lecturers/new">
              <Plus />
              Add lecturer
            </Link>
          </Button>
        }
      />

      <form className="mb-4 max-w-sm">
        <div className="relative">
          <Search className="pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            name="q"
            placeholder="Search by name, ID, email, or department"
            defaultValue={q}
            className="pl-8"
          />
        </div>
      </form>

      <div className="overflow-hidden rounded-lg border border-border bg-card">
        {lecturers.length === 0 ? (
          <div className="flex flex-col items-center gap-2 px-6 py-16 text-center">
            <UsersRound className="size-8 text-muted-foreground/50" />
            <p className="text-sm font-medium text-foreground">
              {q ? "No lecturers match that search" : "No lecturers yet"}
            </p>
            <p className="text-sm text-muted-foreground">
              {q ? "Try a different name, ID, or email." : "Add a lecturer to assign them to courses."}
            </p>
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Lecturer ID</TableHead>
                <TableHead>Department</TableHead>
                <TableHead className="hidden md:table-cell">Email</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {lecturers.map((l) => (
                <TableRow key={l.lecturer_id}>
                  <TableCell className="p-0">
                    <Link
                      href={`/lecturers/${encodeURIComponent(l.lecturer_id)}`}
                      className="block px-4 py-3 font-medium text-foreground"
                    >
                      {l.lecturer_name}
                    </Link>
                  </TableCell>
                  <TableCell className="font-mono text-xs text-muted-foreground">
                    {l.lecturer_id}
                  </TableCell>
                  <TableCell>{l.department}</TableCell>
                  <TableCell className="hidden text-muted-foreground md:table-cell">
                    {l.lecturer_email}
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

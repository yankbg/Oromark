import Link from "next/link";
import { Plus, Search, UsersRound } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { listLecturers } from "@/lib/actions/lecturers";
import { safeFetch } from "@/lib/safe-fetch";

function initials(name: string) {
  return name
    .split(" ")
    .map((p) => p[0])
    .filter(Boolean)
    .slice(0, 2)
    .join("")
    .toUpperCase();
}

export default async function LecturersPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q } = await searchParams;
  const { data: lecturers, failed } = await safeFetch(() => listLecturers(q), []);

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

      {failed ? (
        <div className="mb-4 rounded-lg border border-[var(--oro-warning)]/30 bg-[var(--oro-warning)]/10 px-4 py-2.5 text-sm text-[var(--oro-warning)]">
          Couldn&apos;t load lecturers just now — refresh to retry.
        </div>
      ) : null}

      <form className="mb-4 max-w-sm">
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            name="q"
            placeholder="Search by name, ID, email, or department"
            defaultValue={q}
            className="pl-9"
          />
        </div>
      </form>

      <div className="overflow-hidden rounded-xl border border-border bg-card">
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
                      className="flex items-center gap-3 px-4 py-3"
                    >
                      <Avatar className="size-8">
                        <AvatarFallback className="bg-[var(--oro-secondary)]/10 text-xs font-medium text-[var(--oro-secondary)]">
                          {initials(l.lecturer_name)}
                        </AvatarFallback>
                      </Avatar>
                      <span className="font-medium text-foreground">{l.lecturer_name}</span>
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

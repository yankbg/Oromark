import { Search } from "lucide-react";
import { PageHeader } from "@/components/page-header";
import { Input } from "@/components/ui/input";
import { SessionsTable } from "@/components/sessions-table";
import { listSessions } from "@/lib/actions/sessions";
import { safeFetch } from "@/lib/safe-fetch";

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

      <SessionsTable
        sessions={sessions}
        emptyTitle={q ? "No sessions match that search" : "No sessions yet"}
        emptyHint={
          q
            ? "Try a different course, room, or lecturer."
            : "Sessions appear here once a lecturer ends a class and their phone syncs."
        }
      />
    </div>
  );
}

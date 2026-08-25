import "server-only";
import dns from "dns";
import postgres from "postgres";

// Some IPv6-flaky networks resolve Neon's pooler hostname to an IPv6
// address and then fail with EAI_AGAIN/ENETUNREACH instead of falling back
// to IPv4. Preferring IPv4 results avoids that on hosts where IPv6 routing
// is broken or absent (harmless everywhere else).
dns.setDefaultResultOrder("ipv4first");

// Server-only Postgres client. Never import this from a Client Component —
// the "server-only" import above makes that a build error if attempted.
declare global {
  var __oromarkSql: ReturnType<typeof postgres> | undefined;
}

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error(
    "DATABASE_URL is not set. Copy admin/.env.local.example to admin/.env.local and fill it in."
  );
}

// Reuse the connection pool across hot reloads in dev.
export const sql =
  global.__oromarkSql ??
  postgres(connectionString, {
    ssl: "require",
    max: 10,
    idle_timeout: 20,
    connect_timeout: 10,
  });

if (process.env.NODE_ENV !== "production") {
  global.__oromarkSql = sql;
}

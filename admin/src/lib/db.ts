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
const rawSql =
  global.__oromarkSql ??
  postgres(connectionString, {
    ssl: "require",
    max: 10,
    idle_timeout: 20,
    connect_timeout: 6,
  });

if (process.env.NODE_ENV !== "production") {
  global.__oromarkSql = rawSql;
}

// Neon's pooler occasionally drops a fresh connection attempt outright
// (write CONNECT_TIMEOUT) rather than just being slow to answer — a longer
// connect_timeout wouldn't help since a retried attempt from scratch
// typically succeeds within a second or two. Transparently retry plain
// `sql\`...\`` calls (every call site in this app) up to twice on a
// connection-level failure before giving up; anything else (a real query
// error) throws immediately, unretried.
const CONNECTION_ERROR = /CONNECT_TIMEOUT|ECONNREFUSED|ETIMEDOUT|ENETUNREACH|ECONNRESET|EAI_AGAIN/;

async function withConnectionRetry<T>(run: () => Promise<T>, attempts = 5): Promise<T> {
  for (let attempt = 1; attempt <= attempts; attempt++) {
    try {
      return await run();
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      if (attempt === attempts || !CONNECTION_ERROR.test(message)) throw err;
      await new Promise((resolve) => setTimeout(resolve, 1500 * attempt));
    }
  }
  throw new Error("unreachable");
}

export const sql = new Proxy(rawSql, {
  apply(target, thisArg, args: Parameters<typeof rawSql>) {
    return withConnectionRetry(() => Reflect.apply(target, thisArg, args));
  },
}) as typeof rawSql;

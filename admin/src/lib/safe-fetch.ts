import "server-only";

/** Awaits a single Neon query for a page that only needs one (list pages
 * that don't have multiple widgets to degrade independently, unlike the
 * Overview page's own settle() helper). On failure, returns the fallback
 * instead of throwing, so the page still renders — the connection-retry
 * wrapper in lib/db.ts already tried its own retries first, so a failure
 * here means that was exhausted, not a fluke worth crashing the page over. */
export async function safeFetch<T>(
  run: () => Promise<T>,
  fallback: T
): Promise<{ data: T; failed: boolean }> {
  try {
    return { data: await run(), failed: false };
  } catch (err) {
    console.warn("[safeFetch] query failed, showing a fallback:", err);
    return { data: fallback, failed: true };
  }
}

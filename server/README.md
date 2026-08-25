# OROmark sync server

Sits between the mobile app and Neon Postgres. Holds the real Postgres
connection string server-side — it is never embedded in the Flutter app.
The app only ever calls this server's public HTTPS URL with a shared API
key (`SYNC_API_URL` / `SYNC_API_KEY` in the app's `.env`).

This is **not** part of the live attendance flow. The lecturer/student UDP
broadcast + local HTTP handshake stays entirely on the classroom LAN and
keeps working with zero internet. This server only mirrors data into
Postgres afterward, for the future web admin dashboard, whenever a phone
happens to have real internet.

## Local development

```bash
cd server
dart pub get
cp .env.example .env   # fill in NEON_DB_URL and pick a SYNC_API_KEY
dart run bin/server.dart
```

Then point the app's `.env` at it:

```
SYNC_API_URL=http://<your-machine-ip>:8080
SYNC_API_KEY=<same value as server/.env>
```

(`localhost` won't work from a phone — use your machine's LAN IP, and note
this is a *different* network concern than the classroom LAN used for
attendance broadcasts.)

## Deploying

Any host that can run a long-lived Dart process works (Render, Fly.io, a
small VPS, etc.). Set `NEON_DB_URL`, `SYNC_API_KEY`, and `PORT` as real
environment variables on the host — `server/.env` is a local-dev
convenience only and is gitignored. Once deployed, update the app's
`.env`: `SYNC_API_URL=https://<your-deployed-host>`.

## API

- `GET /health` — liveness check, no API key required.
- `POST /sync` — requires header `X-Api-Key: <SYNC_API_KEY>`. Body is a
  JSON object with any of `courses`, `lecturers`, `students`,
  `enrolledStudents`, `sessions`, `attendanceRecords` as arrays; each is
  upserted into the matching Postgres table. See `bin/server.dart` for the
  exact shape each array's objects are expected to have — it mirrors the
  Drift table columns in `../lib/data/database/tables.dart`.
- `POST /auth/login` — **no API key required** (this is the end-user login
  endpoint, not the app pushing sync data). Body: `{"id": "<studentId or
  email, or lecturerId or email>", "password": "...", "role": "student" |
  "lecturer" (optional hint, tried both if omitted)}`. Checks the bcrypt
  hash stored in `students.password_hash` / `lecturers.password_hash`.
  - `200 {ok:true, role, profile:{...}, token}` — success, `token` is an
    opaque session token (in-memory, 30-day expiry; not a JWT — see the
    comment above `_issueToken` in `bin/server.dart` for why).
  - `401 {error:"invalid_password"}` — account exists, wrong password.
  - `404 {error:"not_found"}` — no such account, or the account exists but
    has no password set in Neon yet (lets the app fall back to on-device
    SQLite for accounts that predate this endpoint).
  - `429 {error:"rate_limited"}` — too many attempts from this IP or
    against this account (8 attempts / 5 minutes, per `_RateLimiter`).
- `POST /auth/bootstrap-password` — requires `X-Api-Key`. Body:
  `{"role": "student"|"lecturer", "id": "...", "password": "..."}`. Hashes
  and stores the password, but **only if the account doesn't already have
  one** (`where password_hash is null`) — used by the app to opportunistically
  migrate the handful of pre-existing local-only accounts (seeded before
  Neon had a password column) the first time they log in successfully
  on-device with internet available. Never overwrites a hash an admin set
  via the dashboard.

## Schema

`../db/schema.sql` — run once against a fresh Neon database:

```bash
psql "$NEON_DB_URL" -f ../db/schema.sql
```

Applying just the auth migration to an existing database:

```bash
psql "$NEON_DB_URL" -c "alter table students add column if not exists password_hash text;"
psql "$NEON_DB_URL" -c "alter table lecturers add column if not exists password_hash text;"
```

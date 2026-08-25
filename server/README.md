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
  Drift table columns in `../lib/data/database/tables.dart`, minus any
  password fields (this database is never a credential store).

## Schema

`../db/schema.sql` — run once against a fresh Neon database:

```bash
psql "$NEON_DB_URL" -f ../db/schema.sql
```

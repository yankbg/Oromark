# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Oromark is a LAN-based classroom attendance system with three parts in this one repo:

- **Flutter mobile app** (repo root, `lib/`) — student and lecturer portals. The live attendance flow (lecturer broadcasts over UDP/BLE, student confirms via local HTTP) runs entirely on the classroom LAN with zero internet dependency. This is the product's core guarantee — never make it depend on connectivity.
- **`server/`** — a small Dart (shelf) sync server that mirrors on-device SQLite into Neon Postgres for the admin dashboard. Holds the real Postgres credentials; the app never does.
- **`admin/`** — a Next.js dashboard (staff-facing: manage students/lecturers/courses, view attendance analytics) that reads/writes Neon directly. See `admin/PRODUCT.md` for its design brief (Operate-mode, teal/amber/blue brand, type-hierarchy-first).

## Commands

**Flutter app** (root):
```bash
flutter pub get                 # install deps
flutter run                     # run on a connected/wireless-debug device
flutter run -d <device-id>      # target a specific device (adb devices -l to list)
flutter test                    # run tests in test/
flutter test test/widget_test.dart   # run a single test file
flutter analyze                 # static analysis
```
`flutter config --jdk-dir=<path>` may be needed if Android Studio's bundled JBR is newer than the project's Gradle supports (Gradle 8.14 needs Java ≤~23; point at a system JDK 17 if builds fail with a Java/Gradle version error).

**Sync server** (`server/`):
```bash
cd server
dart pub get
cp .env.example .env            # fill in NEON_DB_URL and SYNC_API_KEY
dart run bin/server.dart
```
Deploys to Render (`render.yaml`) on push to `main` — auto-deploy is on, no manual trigger needed. See `server/README.md` for the full API (`/sync`, `/auth/login`, `/lecturer/courses`, `/student/history`).

**Admin dashboard** (`admin/`):
```bash
cd admin
npm install
cp .env.local.example .env.local   # fill in DATABASE_URL (same Neon DB as server/) and ADMIN_PASSWORD
npm run dev      # localhost:3000
npm run build
npm run lint
```

## Architecture

### The live attendance flow is fully offline — protect this invariant
Lecturer starts a session → `UdpService` broadcasts session info (course, room, cutoffs) over LAN UDP every few seconds, plus BLE advertising as a secondary proximity signal, plus a local `LocalAttendanceServer` (HTTP, `lib/data/services/AttendanceSubmissionService.dart`) listening on the lecturer's phone. Students' phones discover the broadcast (`lib/providers/session_discovery_provider.dart`), the student confirms, and the app POSTs straight to the lecturer's phone over the LAN. **The lecturer's phone — not the client — computes the authoritative PRESENT/LATE status**, from submission timestamp vs. the session's cutoffs; the client's claimed status is explicitly ignored. None of this touches the internet or Neon. Everything below is a separate, best-effort layer on top.

### Local-first, sync is one-directional-mostly, after the fact
Each device's own Drift/SQLite (`lib/data/database/app_database.dart`) is the source of truth for what that device itself did. `SyncService` (`lib/data/services/sync_service.dart`) pushes unsynced local rows to the server's `POST /sync`, best-effort, whenever there's internet — never required for the live flow. Two exceptions pull data the other way:
- `pullLecturerData` — a lecturer's courses/roster, since those can be created straight in Neon via the admin dashboard and would otherwise never reach the lecturer's phone.
- `pullStudentData` — a student's full attendance history (present **and absent**), since a student's own device only ever learns a session happened by taking part in its broadcast. A session they were marked absent for is computed on the *lecturer's* device (`_computeAbsent()` in `lib/providers/session_notifier.dart`) and never reaches the absent student's phone any other way. Both pulls run once at login and (for students) again on the History screen's pull-to-refresh.

### A session only finalizes through `SessionNotifier.endSession()`
There are two session-ending code paths and it matters which one actually runs: the explicit "End Session" button, and the automatic window-expiry ticker in `lib/presentation/lecturer/session/session_controller.dart`. Both must call the real `sessionNotifierProvider.notifier.endSession()` (computes absences, writes `status: 'ENDED'` locally, stops the UDP broadcast with an explicit "ended" packet, syncs to Neon). The ticker used to only flip an in-memory display flag without calling it — a lecturer who let time run out instead of tapping the button left that session `ACTIVE` forever, both locally and on the admin dashboard, and kept silently re-broadcasting if the app process stayed alive. `endSession()` now guards against being called twice (button + auto-expiry) via `state.isIdle || state.isEnded`.

### Drift upsert gotcha: `onConflict` without an explicit `target` is a trap
`insertOnConflictUpdate()` / `DoUpdate(...)` with no `target:` resolves against the table's **primary key** (the autoincrement `id`, never supplied on insert) — not whatever column you actually meant as the logical identity (e.g. `sessionId`, or `(sessionId, studentId)`). This silently either does a no-op bare insert (if the PK never conflicts) or throws, depending on whether a real unique index exists on the intended columns. Always pass `target: [table.column, ...]` explicitly when upserting — and only if a real unique index exists on those columns; if it doesn't (e.g. `AttendanceRecords` has none on `(sessionId, studentId)`), do an explicit existence-check-then-update instead of relying on `onConflict` at all (see `insertAttendanceRecord` / `mergeStudentAttendanceFromCloud` for the pattern).

### Design tokens
`lib/core/theme/app_colors.dart`'s `AppColors` is the only source of color in the Flutter app — no raw hex outside it (an exception some lecturer screens had drifted into; watch for new code reintroducing Material-3 default hexes with comments like `// primary-container`). Present/late/absent has one fixed trio (`presentText`/`lateText`/`absentText` + matching `*Bg` tints) reused everywhere that concept appears — reach for those specifically, not the generic `primary`/`secondary`/`error` triad, whenever the thing being colored *is* a present/late/absent indicator.

## Known environment constraint

Flutter is installed as a classic-confinement snap on the primary dev machine. Running `flutter`/`dart` from inside a sandboxed agent shell fails with `snap-confine has elevated permissions and is not confined but should be` — a mismatch between snap's confinement model and the sandbox, not fixable via permissions. `flutter run`, `flutter test`, etc. must be run by the user in their own terminal; builds/test results have to be reported back by them, not executed directly by the agent.

## Open investigations (as of the session that wrote this)

Three things were reported and are not yet resolved — don't re-start from zero, pick up from here:

1. **"Mark Manually" button missing for the last remaining absent student**, on the session summary screen (`AbsentStudentsSection`/`_AbsentStudentRow` in `lib/presentation/lecturer/session/session_summary_stats.dart`). Read the current source in full twice — there is no conditional anywhere that treats the last row differently; every row unconditionally gets the button. User confirmed via screenshot the button is genuinely not visible/tappable, not just a "confirm does nothing" issue. Next step handed to the user: do a full rebuild (not hot reload — converting several widgets `StatelessWidget` → `ConsumerWidget` earlier this session is a known hot-reload footgun) and recheck before assuming it's a real code bug.
2. **Stale/ghost sessions shown as "detected" on the student home screen** (e.g. two unrelated courses both showing as live when neither is). Most likely explained by the pre-fix version of the "session ending" bug above: a session whose countdown expired without the explicit button being tapped never sent the UDP "ended" packet or stopped broadcasting, so a lecturer phone whose process stayed alive in the background could keep silently re-broadcasting an old session indefinitely. The ticker fix should prevent *new* occurrences; anything already stuck broadcasting from before the fix won't self-correct until that lecturer's app is restarted. Not yet verified live after the fix. A proposed (not yet approved) additional safeguard: a sane max-session-age prune on the student/discovery side, independent of whatever the lecturer's phone claims.
3. **Student history "only works for 2 accounts."** Checked Neon directly — attendance data exists for 6 different students, not 2; nothing in `pullStudentData`/`/student/history`/the merge logic is account-specific. Working theory: only 2 students have actually logged in/refreshed since the server-side fix shipped, so only their phones have pulled the corrected data — not a code restriction. Unconfirmed whether the user actually observed a live failure on a 3rd account or is inferring from "nobody else tested it yet."

## Git conventions

Commit messages in this repo do not carry a Claude/Anthropic attribution line — omit it even if a default attribution reminder suggests otherwise, unless the user asks for it back.

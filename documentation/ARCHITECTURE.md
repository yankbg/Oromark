# OROmark — Architecture Report

*System architecture, data flow, and engineering rationale — prepared for project defense.*

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem & Objectives](#2-problem--objectives)
3. [System at a Glance](#3-system-at-a-glance)
4. [Components](#4-components)
5. [Data Flows](#5-data-flows)
6. [Security Model](#6-security-model)
7. [Why Offline-First](#7-why-offline-first)
8. [Deployment Topology](#8-deployment-topology)
9. [Engineering Case Studies](#9-engineering-case-studies)
10. [Technology Stack](#10-technology-stack)
11. [Defense Q&A](#11-defense-qa)

---

## 1. Executive Summary

Classroom Wi-Fi is unreliable, but attendance still has to work. That single constraint is why OROmark's core attendance flow does not touch the internet at all: the lecturer's phone broadcasts a live session over the local network, a student's phone detects it and submits attendance directly to the lecturer's device, and the record is written before either phone has to ask anything outside the room for permission. A second, independent check — a short-range Bluetooth Low Energy signal the lecturer's phone advertises — ties that submission to the room itself, not just to being on the same Wi-Fi network.

Everything else in the system exists to make that offline core *visible and manageable* from outside the room. A PostgreSQL database gives the institution a durable, queryable record. A small Dart sync server gives the mobile app a narrow, authenticated door into that database, without ever shipping database credentials inside an app that anyone can decompile. A Next.js admin dashboard gives staff a normal web interface to provision students, lecturers, and courses. The mobile app reconciles with all of it opportunistically — whenever it happens to have real internet — and never blocks the classroom flow on that reconciliation succeeding.

The result is four independently deployable pieces, each doing exactly one job, talking to each other over narrow interfaces: a phone-to-phone protocol for the live event, and an authenticated HTTPS API for everything that can wait.

---

## 2. Problem & Objectives

Paper attendance sheets are slow to take, trivial to falsify by proxy, and give a lecturer or administrator no picture of who is present until long after the fact. Most digital replacements fix the falsification problem but quietly introduce a new dependency: they assume the classroom has working internet, which — on many campuses, IUEA included — is not a safe assumption for every room, every session.

**Design objectives:**

- **Presence, not proximity to a router.** Mark attendance because a student's phone is physically near the lecturer's, without requiring either device to reach the public internet.
- **Live visibility during the session.** The lecturer sees who has checked in, in real time, while the class is still happening — not after a batch upload.
- **Central administration.** Staff manage the roster — students, lecturers, courses, enrollment — from one dashboard, without touching individual phones.
- **Eventual, non-blocking reconciliation.** Whatever happened offline reaches the central database automatically once a device has internet, without ever making the live flow wait on that.
- **Credentials that survive scrutiny.** Passwords are hashed at rest and never embedded in a distributable binary.

---

## 3. System at a Glance

The clearest way to read the system is by where each connection has to happen — inside the classroom's own local network, or out on the internet — because that boundary is what the whole design is organized around.

```
┌─────────────────────────────────────┐        ┌──────────────────────────────────────────────┐
│   CLASSROOM LAN — no internet needed │        │              INTERNET / CLOUD                 │
│                                       │        │                                                │
│   ┌───────────────┐                  │        │   ┌────────────────┐    ┌───────────────────┐  │
│   │  Lecturer's    │  UDP · :5501    │        │   │  Sync Server    │    │  Admin Dashboard   │  │
│   │  Phone         │ ───────────────►│        │   │  Dart · Shelf   │    │  Next.js · Vercel  │  │
│   │  (broadcaster  │                  │  HTTPS │   │  Render         │    │  staff CRUD         │  │
│   │  + local HTTP) │◄─────────────────┼────────┼──►│  API-key gated  │    │                     │  │
│   │                │  HTTP POST       │opport- │   └────────┬───────┘    └─────────┬───────────┘  │
│   │                │  /attendance     │unistic │            │ SQL/TLS              │ SQL/TLS       │
│   └───────▲────────┘                  │        │            └──────────┬───────────┘               │
│           │                           │        │                       ▼                            │
│   ┌───────┴────────┐                  │        │              ┌──────────────────┐                  │
│   │  Student's      │                 │        │              │   PostgreSQL      │                  │
│   │  Phone          │                 │        │              │   Render          │                  │
│   │  (discovery     │                 │        │              │   sslmode=require │                  │
│   │  listener)      │                 │        │              └──────────────────┘                  │
│   └────────────────┘                  │        │                                                │
└─────────────────────────────────────┘        └──────────────────────────────────────────────┘
```

The live attendance protocol (left) never crosses into the cloud zone (right). The dashed HTTPS line is the only bridge between the two — a best-effort sync that runs whenever a phone happens to have internet, never a requirement for class to proceed. Both cloud apps read/write the same database; the mobile app only ever reaches it through the sync server.

---

## 4. Components

### 4.1 — Mobile App

**Flutter / Dart**, one binary serving both student and lecturer roles. State is managed with Riverpod; on-device persistence uses Drift over SQLite. This is the only component that runs both the UDP broadcaster/listener *and* a lightweight local HTTP server — because it's the only component physically present in the room where the event it's recording actually happens. It also runs a connectionless BLE advertiser (lecturer) and scanner (student) — see 5.1.1 — as a second, independent proximity signal alongside Wi-Fi. During a live session, the on-device SQLite database — not Postgres — is the real source of truth.

`riverpod` · `drift/sqlite` · `shelf` · `flutter_ble_peripheral` · `flutter_blue_plus` · `flutter_dotenv` · `bcrypt (via server)`

### 4.2 — Sync Server

**Dart, Shelf, deployed on Render as a Docker service.** A deliberately narrow API standing between the mobile app and Postgres — five routes total: `/auth/login`, `/auth/bootstrap-password`, `/sync`, `/lecturer/courses`, `/health`. It exists so the mobile app *never* holds a direct database connection string, which a decompiled APK would expose in minutes. Every route except login is gated by a shared API key; login is separately rate-limited instead.

`shelf_router` · `postgres (dart)` · `bcrypt` · `Docker` · `Render`

### 4.3 — Admin Dashboard

**Next.js 16 (App Router, Turbopack), React 19, TypeScript, deployed on Vercel.** The CRUD surface for staff: create and edit students, lecturers, courses, and enrollment; reset a password. It also gives staff read-only visibility into synced session history — browsable across every course, or drilled into from a single course — down to the full per-student attendance breakdown for any one session. Server Actions talk to Postgres directly — a trusted server context, so the connection string never reaches a browser. A single shared password gates the whole dashboard, appropriate for a small, known set of administrative staff.

`server actions` · `postgres.js` · `bcryptjs` · `zod` · `Vercel`

### 4.4 — Database

**PostgreSQL, hosted on Render.** Six tables: `students`, `lecturers`, `courses`, `enrolled_students`, `sessions`, `attendance_records` — a cloud mirror of the on-device schema, written to only by the sync server, after the fact. It is deliberately *not* on the live attendance path: nothing in the classroom flow waits on a query to this database succeeding.

`bcrypt hashes only` · `sslmode=require` · `pgcrypto`

---

## 5. Data Flows

Four flows cover everything the system does. The first is the one the whole architecture is built around; the other three exist to keep it fed and manageable from outside the room.

### 5.1 — Live Attendance (offline, LAN-only)

This is the flagship flow: from "start session" to a written record, no internet access is used at any point.

1. **Lecturer starts a session.** A session ID, room code, and two cutoff times are generated: a 20-minute *present* window, followed by a 10-minute *late* window — 30 minutes total (`presentMinutes: 20`, `lateMinutes: 30`).
2. **The phone starts broadcasting.** A UDP packet — session ID, course code and name, room code, the lecturer's local IP, start/end time, a late-window flag — goes out on the LAN broadcast address every 6 seconds (every 20s once the late window starts), on **port 5501**.
3. **Nearby students detect it.** Every student's phone on the same Wi-Fi listens on that same port. On a match it decodes the session and shows "Signal Detected" — no pairing, no QR code, no manual entry of a room name.
4. **Student confirms attendance.** Before the request goes out, the app runs one more check: it scans for a few seconds for a short Bluetooth Low Energy token the lecturer's phone is separately, independently advertising (see 5.1.1). Only a genuine match lets the request proceed — the app then sends the student's ID as an HTTP `POST /attendance` straight to the lecturer's phone, not to any cloud endpoint. The lecturer's device rate-limits the request per IP, checks it against the present/late cutoff, and writes the record into its own local SQLite database.
5. **Lecturer ends the session.** The broadcast doesn't just stop — a short burst of `ENDED` packets goes out first, so listening students drop the session immediately. As a backstop for a dropped packet, every student device also independently forgets any session it hasn't heard from in 60 seconds. The lecturer's app then computes absentees — anyone enrolled who never submitted — and closes the local server.

> **Why this matters:** discovery, submission, and absentee computation all complete with the Wi-Fi radio as the only requirement. If the building's internet uplink is down, this flow doesn't notice.

#### 5.1.1 — Proximity Verification: Why BLE, Not Just Wi-Fi

UDP discovery and the room code alone have a gap: a Wi-Fi subnet frequently spans a whole building, sometimes more, so "same subnet, knows the room code" doesn't actually prove a student is in the room — only that they're somewhere on the same network and someone told them the code. A student at the building's main gate, or in the room next door, could otherwise submit attendance without ever being present.

BLE closes that gap because its physical range is short and attenuates sharply through walls and doors, unlike a Wi-Fi broadcast — so a BLE match ties the check to something close to the room itself rather than the network's topology. The implementation is deliberately **advertise/scan only — no Bluetooth GATT connection is ever made.** Android phones reliably support only around 4–7 simultaneous BLE peripheral (GATT) connections, a tighter and less documented ceiling than the Wi-Fi router-capacity problem this system already has to live with; passive advertising and scanning have no such limit, since nothing is actually connecting. The lecturer's phone advertises a short token — the first bytes of a SHA-256 hash of the session ID — on a fixed, app-scoped service UUID; the student's phone filters its scan to that UUID and checks for an exact token match.

The gate fails closed, not open. Not every phone can advertise (peripheral mode is a chipset capability, not universal), so a session only requires the check if the lecturer's device actually confirmed advertising started — communicated to students in the broadcast payload itself, so a lecturer on unsupported hardware doesn't strand an entire class. But once a session does require it, every other outcome blocks: no match, Bluetooth off, denied permission, or unsupported hardware on the *student's* end all refuse the submission with an explicit reason, rather than silently letting it through. That mattered concretely — an earlier version treated "Bluetooth off" and "no BLE hardware" identically, both falling through as a soft pass, which meant a student could dodge the entire check just by switching Bluetooth off before confirming. The fix checks the adapter state explicitly and, if it's off, triggers Android's own system "Turn on Bluetooth?" dialog — the same interaction pattern Maps uses for "turn on Location" — so only a genuine decline blocks the student, not a fixable oversight. The one case that still can't be helped, a phone with no BLE hardware at all, blocks too; the lecturer's existing manual-override screen (6, below) is the intended, auditable path for that legitimate edge case, not a bypass built into the client.

Geofencing (GPS-based) was considered and rejected for the same problem. Indoor GPS accuracy — typically 10–50 metres, worse in concrete or multi-storey buildings — is often *larger* than the very distance being distinguished, "in this room" versus "in the hallway outside it," so its error margin exceeds the signal it would need to measure. It also needs either a per-room coordinate surveyed and maintained by an admin, or one captured live from the lecturer's own (equally noisy) GPS reading, and it requires `ACCESS_FINE_LOCATION` plus literally recording device coordinates. BLE, declared with Android 12+'s `neverForLocation` flag, needs no location permission at all and records no coordinate anywhere in the protocol — a tighter proximity guarantee with no configuration burden and a smaller privacy footprint.

### 5.2 — Cloud Sync (opportunistic, best-effort)

Sync runs on three triggers: once at app cold start, immediately when a lecturer ends a session — the moment they're most likely to still have Wi-Fi — and every 10 minutes for as long as the app process stays alive. The extra triggers close a real gap the cold-start-only version had: anything that happened between one app launch and the next stayed local-only until the next lucky relaunch with internet, which is a genuine data-loss risk if the device is lost, wiped, or a lecturer's access is revoked before that ever fires again. Each push sends whatever's currently marked unsynced — sessions, attendance records, and (idempotently) the full roster — to the sync server over HTTPS, API-key authenticated, which writes it into Postgres. The same channel runs in reverse for rosters: on every successful network login, a lecturer's app pulls `/lecturer/courses` fresh, so a course or enrollment change made in the admin dashboard reaches the phone. Sync is one-directional per data type at write time, silently retried on failure, and never blocks the live flow above it.

Getting the "unsynced" bookkeeping right mattered more than it looked — see Case 05 in Section 9.

### 5.3 — Authentication (network-first, offline-tolerant)

Login always tries the network first, but is built to keep working when the network can't be reached — and to reconcile the two worlds automatically along the way.

1. **Try the sync server first.** A `POST /auth/login` checks the typed password against the bcrypt hash stored in Postgres.
2. **200 — success.** The profile is cached on-device (so this device can log this account in later, even offline), and a lecturer's courses are pulled immediately.
3. **401 — wrong password.** Postgres is authoritative once an account has a password there, so the app does *not* fall back to a possibly-stale local password. It fails, on purpose.
4. **404 — no password set yet.** True for accounts that predate the `password_hash` column. The app falls back to the on-device SQLite login; if that succeeds, it opportunistically pushes ("bootstraps") that password's hash up to Postgres — never overwriting an existing hash. From then on the account logs in over the network like any other.
5. **Server unreachable.** Falls back to local SQLite. A device that has logged this account in before keeps working fully offline. A brand-new, dashboard-provisioned account with no history on this device is told plainly that it needs internet for its first login.

### 5.4 — Admin Management

Staff sign in with a single shared password; the session cookie is an HMAC-SHA256 signature keyed by that password, so it can't be forged without knowing it. Every create or update goes straight to Postgres through a Server Action, hashing any password with bcrypt before it's written. Because the dashboard and the sync server point at the same database, a student created here — or a password reset — is visible to the mobile app the next time that account logs in over the network.

---

## 6. Security Model

| Measure | Why |
|---|---|
| Passwords hashed, never plaintext server-side | Every stored credential is bcrypt. The database only ever holds a hash — not the admin dashboard, not the sync server, not a log line. |
| DB credentials never leave the server | Only the sync server's environment and the admin dashboard's Server Actions hold a Postgres connection string. The distributed mobile app never does. |
| API-key-gated sync routes | `/sync`, `/lecturer/courses`, and `/auth/bootstrap-password` reject any request without the shared key — the app's own backend, not an open write API. |
| Rate-limited login | `/auth/login` is separately throttled instead of key-gated (a login endpoint can't require a secret the user hasn't proven yet), blunting credential-stuffing. |
| Opaque session tokens | Mobile sessions are random 32-byte tokens held server-side in memory, 30-day expiry — nothing encoded in the token itself to decode or tamper with. |
| Signed, httpOnly admin cookie | The admin session cookie is `httpOnly` and `secure` in production, and its value is an HMAC — invisible to client JS, unforgeable without the password. |
| BLE proximity token match | A student's submission must be preceded by detecting a short-range Bluetooth advertisement, derived from the session ID, from the lecturer's own device (5.1.1). Closes the gap where same-subnet Wi-Fi plus a leaked room code let someone submit attendance from outside the room. Blocks — never silently passes — on every failure mode, including unsupported hardware. |
| Manual override scoped to absent students only | The lecturer's after-the-fact correction screen — including its search — can only ever select from that session's already-absent students; a present or late student is never reachable from it. |

> **A documented trade-off:** a device that has logged in before caches its password locally in plaintext, scoped to that one device, purely to make offline login possible for that account going forward. This isn't an oversight — it's the same on-device model the app always had, kept intentionally so pre-cloud accounts keep working exactly as before.

---

## 7. Why Offline-First

Most mobile apps treat the internet as always-there and the local network as an occasional convenience. OROmark inverts that: the local network is the one thing the live flow can actually depend on inside a specific room at a specific time, and the internet is treated as best-effort infrastructure that shows up *eventually*.

That inversion drives three concrete engineering choices. UDP broadcast was chosen for discovery because it needs zero setup — no pairing, no shared cloud session, nothing beyond both phones being on the same Wi-Fi. A phone-hosted HTTP server was chosen over a cloud API for the actual attendance write, because the write only has to reach a device three metres away, not a data centre. And on-device SQLite — not Postgres — was kept as the true source of truth during class, with Postgres demoted to an eventually-consistent mirror fed after the fact. On a campus where classroom connectivity genuinely varies room to room, that ordering is the whole point.

---

## 8. Deployment Topology

| Component | Host | Notes |
|---|---|---|
| Mobile App | Android device (APK) | Ships a bundled `.env` with the sync server's URL and API key — never a database credential. BLE advertising (peripheral mode) isn't supported on every Android chipset; a session on unsupported hardware simply runs without the BLE gate, communicated to students via the broadcast payload rather than failing the session. |
| Sync Server | Render (Docker, free tier) | Declared as infrastructure-as-code in `render.yaml`; health-checked at `/health`; redeploys automatically on env-var change. |
| Admin Dashboard | Vercel | Connects to Postgres directly over TLS from Server Actions; gated by a single shared password. |
| Database | Render PostgreSQL | `sslmode=require` enforced on every connection, from both the sync server and the admin dashboard. |

---

## 9. Engineering Case Studies

These weren't hypothetical edge cases — they were found and fixed on physical devices during integration testing. Each is a small lesson in what "offline-first" and "network-first" actually cost when you build them for real.

### Case 01 — Cleartext networking blocked by Android itself

- **Symptom:** A student created via the admin dashboard got "invalid credentials" on their very first phone login — even with real internet available.
- **Root cause:** Android 9+ blocks plaintext HTTP by default. The sync request never left the device; the app correctly, if confusingly, reported that as "offline."
- **Fix:** Scoped `usesCleartextTraffic` in the Android manifest — appropriate here since the LAN attendance protocol itself is plaintext HTTP by design.

### Case 02 — Stale password hashes blocking otherwise-correct logins

- **Symptom:** After fixing Case 01, several seeded accounts that "worked" before suddenly failed to log in.
- **Root cause:** Those Postgres rows already held an unrelated password hash from earlier seeding. The network-authoritative rule (Section 5.3, step 3) correctly rejected the real password instead of ever reaching the offline fallback that would have accepted it.
- **Fix:** Not a code change — a data fix. Clearing those specific stale hashes let the app's own bootstrap mechanism, already built for exactly this migration, set them correctly on next login.

### Case 03 — A session that outlived its own ending

- **Symptom:** A student's "searching for session" screen kept showing a session minutes after the lecturer ended it — even across a logout and a fresh login.
- **Root cause:** Two layered bugs: the "session ended" signal is a single best-effort UDP burst that can be dropped with nothing left to clean it up; and even when the underlying data *did* clear correctly, the home screen only ever reacted to a session appearing — never to the list going empty — so an already-written `clearSession()` method was simply never called.
- **Fix:** A 60-second no-broadcast-heard timeout as a backstop for dropped packets, plus wiring the empty-list case to the existing clear method. Verified live across two physical devices, lecturer and student.

### Case 04 — Turning Bluetooth off was a working bypass of the proximity gate

- **Symptom:** Not a field report — found by walking through the BLE gate's own failure modes during design review. If a student's phone couldn't scan for any reason, the gate let the submission through.
- **Root cause:** `scanForToken()` treated "no BLE hardware at all" and "Bluetooth is currently off" as the same outcome, and both fell through as a silent pass — a deliberate choice to avoid stranding a legitimate student over a phone limitation, but it meant a student could dodge the entire check just by switching Bluetooth off for ten seconds before confirming.
- **Fix:** The adapter state is checked explicitly before scanning. If it's off, the same system "Turn on Bluetooth?" dialog Android shows for a Maps-style "turn on Location" prompt is triggered; only a genuine decline (or a real permission denial) blocks the student now, and "off" is no longer indistinguishable from "impossible."

### Case 05 — Sessions stuck "Active" forever in the admin dashboard

- **Symptom:** The admin dashboard's Sessions view showed sessions as still "Active" long after the class had visibly ended on the lecturer's phone.
- **Root cause:** `updateSessionStatus()` wrote the new status to the local database but never reset the row's `synced` flag. That was almost invisible under cold-start-only sync (5.2, pre-fix) — a session nearly always started *and* ended within one continuous app run, so its first-ever sync already saw the final status. Once periodic background sync was added, a session could get pushed to Neon mid-flight as "Active," get marked synced, and then permanently miss its own "Ended" transition, since the sync query only re-picks up rows where `synced` is still false. The identical bug independently affected a lecturer's manual attendance correction made after the original record had already synced once.
- **Fix:** Both write paths — `updateSessionStatus()` and the manual-override upsert — now reset `synced` to false on every change, so any status transition, not just the first one, re-qualifies for the next sync pass.

---

## 10. Technology Stack

| Layer | Technology | Role |
|---|---|---|
| Mobile app | Flutter / Dart, Riverpod, Drift (SQLite) | UI, on-device state, local persistence |
| LAN protocol | Raw UDP sockets, Shelf (embedded HTTP) | Session discovery + attendance submission |
| Proximity | flutter_ble_peripheral, flutter_blue_plus | Connectionless BLE advertise (lecturer) / scan (student) room-level gate |
| Sync server | Dart, Shelf, shelf_router, postgres, bcrypt | Authenticated bridge to the database |
| Admin dashboard | Next.js 16, React 19, TypeScript, Tailwind CSS 4 | Roster & account management UI |
| Data access (admin) | postgres.js, Server Actions, zod, bcryptjs | Validated, server-only writes |
| Database | PostgreSQL (Render), pgcrypto | Durable cloud record |
| Media | Cloudinary | Student avatar uploads |
| Hosting | Render (Docker + Postgres), Vercel | Sync server, database, dashboard |

---

## 11. Defense Q&A

**Why not just use a cloud API for attendance instead of UDP + local HTTP?**
Because the one requirement that can't be compromised on is that the classroom itself might have no usable internet — a congested campus network, a room with no signal, an outage. A cloud round-trip would make attendance fail exactly when it's needed most. UDP discovery and a local HTTP write both only need a Wi-Fi hop, which is available even when the internet isn't.

**What stops a student from spoofing a UDP packet or joining remotely?**
Nothing cryptographic — and that's an honestly scoped limitation, not an oversight. Joining a session requires being on the same LAN, detecting a genuine BLE proximity token from the lecturer's device (5.1.1), and submitting within the present/late window directly to the lecturer's own device, which together set a meaningful bar for a classroom deployment. Signed broadcasts or device attestation would raise that bar further still and are a reasonable next step, not something the current scope required.

**Why BLE instead of just tightening the Wi-Fi check — e.g. matching the specific access point (BSSID)?**
BSSID matching was the first alternative considered, and it's simpler. But one access point routinely covers an entire lecture hall plus the corridor outside it and sometimes adjacent rooms, so "same AP" still can't reliably distinguish "in this room" from "just outside it." BLE's much shorter, wall-attenuated range degrades close to the room's actual physical boundary instead of the Wi-Fi radio's much larger footprint.

**Why advertise/scan and not a Bluetooth GATT connection?**
Android phones reliably support only about 4–7 simultaneous BLE peripheral connections, undocumented and known to be flaky across OS versions — a tighter, less reliable ceiling than the Wi-Fi router-capacity problem BLE was partly meant to route around. Passive advertising and scanning have no such limit, since no connection is ever established.

**Why not geofencing?**
Indoor GPS accuracy — typically 10–50 metres — is often larger than the exact distance being distinguished, "in the room" versus "just outside it," so its error margin exceeds the signal it needs to measure. It also needs a coordinate — surveyed per room or captured live from an equally noisy GPS reading — and requires `ACCESS_FINE_LOCATION`, recording an actual device location. BLE, declared with `neverForLocation`, needs no location permission and records no coordinate anywhere in the protocol.

**What happens on a phone that can't run the BLE check at all?**
It blocks the submission with an explicit reason rather than silently letting it through — see Case 04. The lecturer's manual-override screen, already scoped so it can only touch that session's already-absent students, is the intended, auditable path for that legitimate edge case, not a bypass built into the client.

**Why keep a plaintext password cached on the device at all?**
To make the offline-login fallback in Section 5.3 possible at all — without a locally verifiable secret, a device with no internet could never authenticate its own user. It's scoped to the one device that logged in, matches the app's original pre-cloud local-login design, and is a documented trade-off (Section 6), not something that slipped through.

**Why two separate backends — the sync server and the admin dashboard — instead of one?**
They have different trust models. The admin dashboard is used by a small number of known staff behind one shared password doing rich CRUD; the sync server is the one thing the widely distributed, decompilable mobile app ever talks to, so it's kept deliberately minimal and defensible on its own even if the APK is reverse-engineered.

**How is data kept consistent between on-device SQLite and Postgres?**
It isn't kept consistent in real time — that's deliberate. Session and attendance data flows one way, device to cloud, whenever internet appears; roster data (courses, enrollment) flows the other way, cloud to device, on every network login. There is no live two-way sync, which is an accepted simplicity trade-off for a system whose core flow never needs the cloud copy to be immediately correct.

**What would extend naturally from here?**
True background sync (Android WorkManager) so a session ending while the app isn't open at all still reaches Neon, rather than waiting for the app to be reopened; an admin-visible "last synced" timestamp per lecturer, so staff have positive confirmation data left a device before revoking that lecturer's access, instead of assuming sync always happened; a live view in the admin dashboard of sessions currently in progress; signed UDP broadcasts and BLE payloads to close the remaining spoofing gap; and automated tests around the authentication reconciliation paths in Section 5.3 and the BLE gate's failure-mode handling in 5.1.1, both of which are the most state-dependent logic in the system. The BLE flow itself also still needs verification on two physical devices end-to-end — advertise/scan doesn't run in an emulator — before it's trusted in front of an actual class.

---

*OROmark — Signal-based attendance · IUEA*
*Compiled from the current codebase: `lib/` (mobile), `server/` (sync API), `admin/` (dashboard), `db/schema.sql` (database).*

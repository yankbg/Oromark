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

Classroom Wi-Fi is unreliable, but attendance still has to work. That single constraint is why OROmark's core attendance flow does not touch the internet at all: the lecturer's phone broadcasts a live session over the local network, a student's phone detects it and submits attendance directly to the lecturer's device, and the record is written before either phone has to ask anything outside the room for permission.

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

**Flutter / Dart**, one binary serving both student and lecturer roles. State is managed with Riverpod; on-device persistence uses Drift over SQLite. This is the only component that runs both the UDP broadcaster/listener *and* a lightweight local HTTP server — because it's the only component physically present in the room where the event it's recording actually happens. During a live session, the on-device SQLite database — not Postgres — is the real source of truth.

`riverpod` · `drift/sqlite` · `shelf` · `flutter_dotenv` · `bcrypt (via server)`

### 4.2 — Sync Server

**Dart, Shelf, deployed on Render as a Docker service.** A deliberately narrow API standing between the mobile app and Postgres — five routes total: `/auth/login`, `/auth/bootstrap-password`, `/sync`, `/lecturer/courses`, `/health`. It exists so the mobile app *never* holds a direct database connection string, which a decompiled APK would expose in minutes. Every route except login is gated by a shared API key; login is separately rate-limited instead.

`shelf_router` · `postgres (dart)` · `bcrypt` · `Docker` · `Render`

### 4.3 — Admin Dashboard

**Next.js 16 (App Router, Turbopack), React 19, TypeScript, deployed on Vercel.** The CRUD surface for staff: create and edit students, lecturers, courses, and enrollment; reset a password. Server Actions talk to Postgres directly — a trusted server context, so the connection string never reaches a browser. A single shared password gates the whole dashboard, appropriate for a small, known set of administrative staff.

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
4. **Student confirms attendance.** The app sends the student's ID as an HTTP `POST /attendance` straight to the lecturer's phone — not to any cloud endpoint. The lecturer's device rate-limits the request per IP, checks it against the present/late cutoff, and writes the record into its own local SQLite database.
5. **Lecturer ends the session.** The broadcast doesn't just stop — a short burst of `ENDED` packets goes out first, so listening students drop the session immediately. As a backstop for a dropped packet, every student device also independently forgets any session it hasn't heard from in 60 seconds. The lecturer's app then computes absentees — anyone enrolled who never submitted — and closes the local server.

> **Why this matters:** discovery, submission, and absentee computation all complete with the Wi-Fi radio as the only requirement. If the building's internet uplink is down, this flow doesn't notice.

### 5.2 — Cloud Sync (opportunistic, best-effort)

Whenever a device has real internet — not necessarily during the session itself — the app pushes ended sessions and their attendance records to the sync server over HTTPS, API-key authenticated, which writes them into Postgres. The same channel runs in reverse for rosters: on every successful network login, a lecturer's app pulls `/lecturer/courses` fresh, so a course or enrollment change made in the admin dashboard reaches the phone. This sync is one-directional at write time, silently retried on failure, and never blocks the live flow above it.

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

> **A documented trade-off:** a device that has logged in before caches its password locally in plaintext, scoped to that one device, purely to make offline login possible for that account going forward. This isn't an oversight — it's the same on-device model the app always had, kept intentionally so pre-cloud accounts keep working exactly as before.

---

## 7. Why Offline-First

Most mobile apps treat the internet as always-there and the local network as an occasional convenience. OROmark inverts that: the local network is the one thing the live flow can actually depend on inside a specific room at a specific time, and the internet is treated as best-effort infrastructure that shows up *eventually*.

That inversion drives three concrete engineering choices. UDP broadcast was chosen for discovery because it needs zero setup — no pairing, no shared cloud session, nothing beyond both phones being on the same Wi-Fi. A phone-hosted HTTP server was chosen over a cloud API for the actual attendance write, because the write only has to reach a device three metres away, not a data centre. And on-device SQLite — not Postgres — was kept as the true source of truth during class, with Postgres demoted to an eventually-consistent mirror fed after the fact. On a campus where classroom connectivity genuinely varies room to room, that ordering is the whole point.

---

## 8. Deployment Topology

| Component | Host | Notes |
|---|---|---|
| Mobile App | Android device (APK) | Ships a bundled `.env` with the sync server's URL and API key — never a database credential. |
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

---

## 10. Technology Stack

| Layer | Technology | Role |
|---|---|---|
| Mobile app | Flutter / Dart, Riverpod, Drift (SQLite) | UI, on-device state, local persistence |
| LAN protocol | Raw UDP sockets, Shelf (embedded HTTP) | Session discovery + attendance submission |
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
Nothing cryptographic — and that's an honestly scoped limitation, not an oversight. Joining a session requires being on the same LAN and submitting within the present/late window directly to the lecturer's own device, which already sets a meaningful bar for a classroom deployment. Signed broadcasts or device attestation would raise that bar further and are a reasonable next step, not something the current scope required.

**Why keep a plaintext password cached on the device at all?**
To make the offline-login fallback in Section 5.3 possible at all — without a locally verifiable secret, a device with no internet could never authenticate its own user. It's scoped to the one device that logged in, matches the app's original pre-cloud local-login design, and is a documented trade-off (Section 6), not something that slipped through.

**Why two separate backends — the sync server and the admin dashboard — instead of one?**
They have different trust models. The admin dashboard is used by a small number of known staff behind one shared password doing rich CRUD; the sync server is the one thing the widely distributed, decompilable mobile app ever talks to, so it's kept deliberately minimal and defensible on its own even if the APK is reverse-engineered.

**How is data kept consistent between on-device SQLite and Postgres?**
It isn't kept consistent in real time — that's deliberate. Session and attendance data flows one way, device to cloud, whenever internet appears; roster data (courses, enrollment) flows the other way, cloud to device, on every network login. There is no live two-way sync, which is an accepted simplicity trade-off for a system whose core flow never needs the cloud copy to be immediately correct.

**What would extend naturally from here?**
A live view in the admin dashboard of sessions currently in progress; push notifications to a lecturer once a sync completes; signed UDP broadcasts to close the spoofing gap above; and automated tests around the authentication reconciliation paths in Section 5.3, which are the most state-dependent logic in the system.

---

*OROmark — Signal-based attendance · IUEA*
*Compiled from the current codebase: `lib/` (mobile), `server/` (sync API), `admin/` (dashboard), `db/schema.sql` (database).*

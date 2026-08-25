-- OROmark — Neon Postgres schema
--
-- This is the cloud mirror of the on-device SQLite tables (lib/data/database/tables.dart),
-- feeding a future web admin dashboard. It is NOT the live attendance path — that stays
-- entirely on-device (SQLite) and on the classroom LAN (UDP/HTTP), which must keep working
-- with zero internet access. This database is written to only by the sync backend
-- (server/), after the fact, whenever a phone has real internet.
--
-- Deliberately excludes password columns — nothing here needs student/lecturer
-- credentials, and a database reachable over the internet is a meaningfully bigger
-- attack surface than an on-device SQLite file.

create extension if not exists pgcrypto;

create table if not exists courses (
    id             bigserial primary key,
    course_code    text unique not null,
    course_name    text not null,
    course_group   text,
    enrolled       integer not null default 0,
    avg_attendance integer not null default 0,
    lecturer_id    text
);

create table if not exists lecturers (
    id             bigserial primary key,
    lecturer_id    text unique not null,
    lecturer_name  text not null,
    lecturer_email text not null,
    department     text not null
);

create table if not exists students (
    id             bigserial primary key,
    student_id     text unique not null,
    student_name   text not null,
    student_email  text unique not null,
    phone_number   text not null,
    programme      text not null,
    year_of_study  text not null,
    avatar_url     text
);

create table if not exists enrolled_students (
    id           bigserial primary key,
    student_id   text not null,
    course_code  text not null,
    full_name    text not null,
    unique (student_id, course_code)
);

create table if not exists sessions (
    session_id      text primary key,
    course_code     text not null,
    course_name     text not null,
    lecturer_name   text,
    room_code       text not null,
    start_time      timestamptz not null,
    end_time        timestamptz not null,
    present_cutoff  text,
    late_cutoff     text,
    status          text not null,
    created_at      timestamptz not null,
    synced_at       timestamptz not null default now()
);

create table if not exists attendance_records (
    id           bigserial primary key,
    session_id   text not null references sessions(session_id) on delete cascade,
    student_id   text not null,
    status       text not null,
    "timestamp"  timestamptz not null,
    synced_at    timestamptz not null default now(),
    unique (session_id, student_id)
);

create index if not exists idx_attendance_session on attendance_records(session_id);
create index if not exists idx_attendance_student on attendance_records(student_id);
create index if not exists idx_sessions_course on sessions(course_code);
create index if not exists idx_enrolled_course on enrolled_students(course_code);

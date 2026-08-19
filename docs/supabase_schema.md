# TASILLA — Supabase Schema

**What actually exists in the live database, verified against production on 2026-07-17.**
Created by `tasilla_supabase_schema_v2.sql` (the 5 base tables), then
`mvp_piece1_submissions_schema.sql` (submissions + certificates + storage), then the
`certificate_gate_launch_scope` migration (Piece 5 — applied 2026-07-17).

This replaces the previous version of this document, which described only the 5 base
tables and listed `certificates` as "not built."

---

## The 7 tables

Every table the Dart code touches, and nothing it does not.

### `profiles`
One row per authenticated user — student or teacher.

| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | FK → `auth.users(id)`, `on delete cascade` |
| `role` | text | `'student'` or `'teacher'` |
| `full_name` | text | |
| `current_level` | text | `'A1'`, `'A2'`… |
| `access_code` | text UNIQUE | The code a student types to log in. Nullable (teachers have none). |
| `created_at` / `updated_at` | timestamptz | `updated_at` auto-maintained by trigger |

### `teacher_students`
Links a teacher to the students they teach. **Without a row here, a teacher cannot see a
student at all** — every teacher-facing RLS policy checks this table.

| Column | Notes |
|---|---|
| `teacher_id`, `student_id` | both FK → `profiles(id)` |
| `status` | `'active'` / `'inactive'` / `'removed'` — policies only honour `'active'` |
| UNIQUE(`teacher_id`, `student_id`) | |

### `student_step_progress`
Per-student, per-lesson progress. **This is what the assessment engine writes to.**

| Column | Notes |
|---|---|
| `student_id` | FK → `profiles(id)` |
| `learning_step_id` | text — e.g. `'A1-EXP-001'` |
| `status` | pending / in_progress / completed / review_needed / submitted / approved / rejected / locked / validated |
| `score` | numeric(4,3) — **0.000 to 1.000**. Nullable if never scored. |
| `validated_by_level_check` | boolean |
| `completed_at` | timestamptz |
| UNIQUE(`student_id`, `learning_step_id`) | required for the app's `upsert(onConflict: ...)` |

**Why the same table serves both the Roadmap and the Skill Paths:** progress is keyed by
`learning_step_id`. A lesson has ONE id regardless of which route the student reached it
through. Finishing "Listening: Café" in the Listening path marks it complete in the roadmap
too — with no sync logic. This falls out of the key design.

### `level_check_attempts`
History of placement/level-check attempts.

| Column | Notes |
|---|---|
| `student_id` | FK → `profiles(id)` |
| `level` | `'A1'` etc. |
| `score` | integer |
| `passed` | boolean |
| `answers` | jsonb |

### `assignments`
Teacher-assigned activities.

| Column | Notes |
|---|---|
| `teacher_id`, `student_id` | FK → `profiles(id)` |
| `target_type` | `'student'` or `'class'` |
| `title`, `category`, `level`, `note` | |
| `status` | pending / in_progress / completed / reviewed / canceled |
| `due_date`, `assigned_at`, `completed_at`, `reviewed_at` | |

### `student_submissions`
Speaking recordings + writing (typed or uploaded). One live row per student per lesson —
resubmitting after a rejection **overwrites** (unique constraint + upsert). If audit
history is ever needed, add a `submission_attempts` table; do not drop the constraint.

| Column | Notes |
|---|---|
| `student_id` | FK → `profiles(id)`, cascade |
| `learning_step_id` | text |
| `skill` | `'speaking'` or `'writing'` |
| `submission_type` | `'audio'` / `'text'` / `'file'` |
| `text_content` | typed writing lives here |
| `file_path` | storage path for audio + handwritten uploads: `{student_id}/{learning_step_id}.{ext}` |
| `status` | `'submitted'` (default) / `'approved'` / `'rejected'` |
| `teacher_feedback`, `reviewed_by`, `reviewed_at` | review fields — **only a teacher can set these** (trigger-enforced, see below) |
| `submitted_at` | timestamptz, default now() |
| UNIQUE(`student_id`, `learning_step_id`) | |

Indexes: by student, by status, and `(student_id, skill, status)` — the last one powers the
per-skill approval-rate query for the certificate check.

### `certificates`
Issued certificates with per-skill scores. **The four-skill rule lives in the database
itself:** the `four_skill_minimum` check constraint requires listening, reading, speaking,
and writing each ≥ 0.70 — a certificate row that violates the standard cannot physically
exist.

| Column | Notes |
|---|---|
| `certificate_code` | text UNIQUE — public, human-readable, e.g. `TSL-A1-7K2M9` |
| `student_id` | FK → `profiles(id)`, cascade |
| `issued_by` | FK → `profiles(id)` — the teacher |
| `level` | `'A1'` |
| `listening_score` / `reading_score` / `speaking_score` / `writing_score` | numeric(4,3), NOT NULL, each ≥ 0.70 (check constraint) |
| `final_exam_score` | numeric(4,3), **nullable** — launch scope (lessons 001–020) has no final exam. The ≥ 0.75 check was removed by the Piece 5 migration and must be **restored when the real final exam ships** (see the commented statements at the bottom of `mvp_piece5_certificate_gate.sql`). |
| `student_name` / `issued_by_name` | text — name **snapshots at issue time**, so the public verification page can show them without a login or a join. Captured, not joined. |
| `issued_at`, `revoked_at` | timestamptz |

---

## Row Level Security

**RLS is enabled on all 7 tables** (33 policies verified live). The rules, in plain terms:

- **A student can read and write only their own rows.** Enforced by `student_id = auth.uid()`.
- **A teacher can read a student's rows only if linked** via an `active` row in
  `teacher_students`.
- **Only teachers can create teacher-student links**, and only for themselves.
- **Teachers create assignments** only for students linked to them.
- **Submissions:** students insert/update their own; teachers read and review their linked
  students'. RLS alone cannot stop a student updating `status` on their own row — the
  review-authority **trigger** provides that guarantee (below).
- **Certificates:** only a teacher can insert, only for a student actively linked to them.
  **Anyone — including signed-out `anon` — can SELECT non-revoked certificates**
  (`certificates_public_verify`). This is what makes `/verify/{code}` possible with no login.

**This is why student login must create a REAL Supabase session.** An access code alone
proves nothing to Postgres — `auth.uid()` would be null and every policy would reject the
write. That is the entire reason for the derived-credential login (see
`provisioning_students.md`).

---

## Storage

Bucket **`submissions`** — private (`public = false`), verified live. Files are namespaced
by student id: `submissions/{student_id}/{learning_step_id}.{ext}`.

Four policies on `storage.objects` (all verified live):

| Policy | Rule |
|---|---|
| `submissions_insert_own_folder` | student uploads only into their own uuid folder |
| `submissions_update_own_folder` | student may overwrite own files (resubmission) |
| `submissions_read_own_folder` | student reads own files back |
| `submissions_read_linked_students` | teacher reads files of `active`-linked students |

**Storage RLS is written differently from table RLS** — it checks
`(storage.foldername(name))[1]` against the uuid. Do not assume the table policy pattern
copies over.

---

## Triggers

### `on_auth_user_created` → `handle_new_user()`
When a user is created in `auth.users` (including manually via the dashboard), a matching
`profiles` row is **created automatically**, defaulting to `role = 'student'`, level `'A1'`.

**Consequence — important:** you do NOT insert into `profiles` when provisioning. The row
already exists. You **UPDATE** it to set the real name, role, and access code. Trying to
INSERT produces a duplicate-key error.

### `student_submissions_review_authority` → `enforce_submission_review_authority()`
**The teeth behind the certificate.** Before-update trigger on `student_submissions`:

- The owning student can only set `status = 'submitted'` (resubmission) and can never
  write `teacher_feedback`, `reviewed_by`, or `reviewed_at`.
- Setting `status` to `'approved'` or `'rejected'` requires the actor's profile role to be
  `'teacher'`; the trigger then stamps `reviewed_by = auth.uid()` and `reviewed_at = now()`
  itself.

Without this, a student could UPDATE their own row to `approved` and self-certify. Do not
rely on the RLS policies alone.

### `set_updated_at()`
Maintains `updated_at` on `profiles` and `student_step_progress`.

---

## Deliberately not built

`organizations` · `classes` · `class_students` · `skills` · `learning_steps` · `exercises` ·
`exercise_questions` · `attempts` · `teacher_reviews` (folded into `student_submissions`
review fields) · `plans` · `subscriptions`

**Lesson content lives in Dart** (`a1_learning_experience_data.dart`), not the database.
That is a deliberate choice: content is versioned with the code, ships with the app, and
needs no network call to read. If content ever needs to be editable without a release, that
decision gets revisited — but not before.

---

## Known future needs

| Need | Why | When |
|---|---|---|
| Restore `final_exam_minimum` (≥ 0.75) + NOT NULL on `certificates.final_exam_score` | Launch scope has no exam; the real one must gate again | When Unit 4 + the multi-format final exam ship (statements are commented at the bottom of `mvp_piece5_certificate_gate.sql`) |
| `subscriptions` / plan state | Stripe webhook → automatic access unlock | Phase 2 (v1.1) |

---

## Verifying the schema

```sql
-- All 7 tables should show rowsecurity = true
select tablename, rowsecurity from pg_tables where schemaname = 'public';

-- Should list 33 policies across the 7 tables
select tablename, policyname from pg_policies where schemaname = 'public'
  order by tablename, policyname;

-- Storage: bucket private, 4 submissions_* policies
select id, public from storage.buckets where id = 'submissions';
select policyname from pg_policies
  where schemaname = 'storage' and tablename = 'objects';

-- Triggers: should include on_auth_user_created, profiles_set_updated_at,
-- student_step_progress_set_updated_at, student_submissions_review_authority
select tgname from pg_trigger where not tgisinternal;

-- Certificate launch gate applied? final_exam_score nullable, no final_exam_minimum,
-- four_skill_minimum still present, name snapshot columns exist
select column_name, is_nullable from information_schema.columns
  where table_name = 'certificates'
    and column_name in ('final_exam_score', 'student_name', 'issued_by_name');
select conname from pg_constraint
  where conrelid = 'public.certificates'::regclass and contype = 'c';
```

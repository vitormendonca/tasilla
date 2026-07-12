# TASILLA — Supabase Schema

**What currently exists in the live database.** The checked-in migrations still describe
an older schema and must be reconciled with this document before the next database change.

This replaces the old `supabase_mvp_schema.md`, which described a 16-table design that was
never built in the live project.

---

## The 5 tables

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

---

## Row Level Security

**RLS is enabled on all 5 tables.** The rules, in plain terms:

- **A student can read and write only their own rows.** Enforced by `student_id = auth.uid()`.
- **A teacher can read a student's rows only if linked** via an `active` row in
  `teacher_students`.
- **Only teachers can create teacher-student links**, and only for themselves.
- **Teachers create assignments** only for students linked to them.

**This is why student login must create a REAL Supabase session.** An access code alone
proves nothing to Postgres — `auth.uid()` would be null and every policy would reject the
write. That is the entire reason for the derived-credential login (see
`provisioning_students.md`).

---

## Triggers

### `on_auth_user_created` → `handle_new_user()`
When a user is created in `auth.users` (including manually via the dashboard), a matching
`profiles` row is **created automatically**, defaulting to `role = 'student'`, level `'A1'`.

**Consequence — important:** you do NOT insert into `profiles` when provisioning. The row
already exists. You **UPDATE** it to set the real name, role, and access code. Trying to
INSERT produces a duplicate-key error.

*(The old `supabase_auth_users.md` doc told you to INSERT. That is why it was deleted.)*

### `set_updated_at()`
Maintains `updated_at` on `profiles` and `student_step_progress`.

---

## Not built (deliberately)

The old schema doc listed these. They do not exist and are not needed yet:

`organizations` · `classes` · `class_students` · `skills` · `learning_steps` · `exercises` ·
`exercise_questions` · `attempts` · `teacher_reviews` · `certificates` · `plans` ·
`subscriptions`

**Lesson content lives in Dart** (`a1_learning_experience_data.dart`), not the database.
That is a deliberate choice: content is versioned with the code, ships with the app, and
needs no network call to read. If content ever needs to be editable without a release, that
decision gets revisited — but not before.

---

## Known future needs

| Need | Why | When |
|---|---|---|
| **Storage bucket + `writing_submissions` table** | Handwritten writing uploads (Mode B in the course structure) — student uploads a photo/PDF, teacher approves | When the writing-upload feature is built |
| **`certificates` table** | Certificate ID, issue date, per-skill scores, verification link — per certification standard §7 | Before issuing any certificate |
| **`teacher_reviews` table** | Teacher pass/redo decisions on speaking + writing submissions | When the teacher review flow is built |

---

## Verifying the schema

```sql
-- All 5 tables should show rowsecurity = true
select tablename, rowsecurity from pg_tables where schemaname = 'public';

-- Should list ~15 policies
select policyname, tablename from pg_policies where schemaname = 'public'
  order by tablename, policyname;

-- Should include on_auth_user_created, profiles_set_updated_at,
-- student_step_progress_set_updated_at
select tgname from pg_trigger where not tgisinternal;
```

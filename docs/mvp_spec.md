# TASILLA — MVP Spec: The Teacher Review Loop

**The MVP goal, stated plainly:** TASILLA can issue **one real certificate to one real
student** — a certificate that means what the certification standard says it means.

Everything in this spec exists to make that true. Anything that does not serve it is out.

---

## 1. What already works (do not rebuild)

| Capability | Status |
|---|---|
| Interactive, scored quizzes (MC, dictation, fill-blank) | ✅ shipped |
| Score-gated completion + retry flow | ✅ shipped |
| Per-step score persistence to `student_step_progress.score` | ✅ shipped |
| Real audio playback | ✅ shipped |
| Single-skill lesson rendering | ✅ shipped |
| Student auth via access code → real Supabase session | ✅ shipped |
| Teacher auth (email/password) | ✅ shipped |
| RLS: teachers see only their linked students | ✅ shipped |
| 10 teacher screens (students list, student detail, progress) | ✅ exist |
| `ActivityStatus` enum: `submitted → approved / rejected` | ✅ modelled |
| `SpeakingTask.maxRecordingSeconds`, `requiresTeacherReview` | ✅ modelled |
| `WritingMode` (13 modes, guided + free response) | ✅ modelled |

**The models already anticipate this feature.** What is missing is the plumbing.

---

## 2. What blocks a certificate today

Per the certification standard:

| Requirement | Blocker |
|---|---|
| 10 speaking submissions, **teacher-approved** | No recording. No submission. No review. |
| 10 writing submissions, **teacher-approved** | No submission. No review. |
| 4 skills gated **independently** at 70% | Per-lesson scores exist; nothing aggregates them **per skill** |
| Teacher final sign-off | Does not exist |
| Certificate with ID + verification link | Does not exist |

**These five are the MVP.** Nothing else.

---

## 3. Scope decisions

**Content: ship EXP 001–020 only.** Do NOT attempt the 20-topic restructure for MVP —
that is v2. The launch roadmap is already limited to the polished 001–020, and Units 3–4
are already hidden. That was the right call; keep it.

**Consequence to be honest about:** with 20 lessons, a student cannot produce 10 speaking
+ 10 writing submissions from lessons alone. **For MVP, lower the bar to what the content
supports** — e.g. 5 speaking + 5 writing + 2 portfolio tasks — and state the real number on
the certificate. Do NOT claim 10 if the course only offers 6. The certificate must not lie.
When the 20-topic restructure lands, raise it back to 10.

**Writing uploads (handwritten, Mode B): IN SCOPE.** It was designed in the course
structure; it needs Storage anyway for speaking recordings, so the marginal cost is low.

---

## 4. Build order

Five pieces. Each is testable on its own.

### Piece 1 — Supabase Storage + submissions table

**Storage bucket:** `submissions` (private, not public).

**New table:**
```sql
create table public.student_submissions (
  id                uuid primary key default gen_random_uuid(),
  student_id        uuid not null references public.profiles(id) on delete cascade,
  learning_step_id  text not null,
  skill             text not null check (skill in ('speaking', 'writing')),
  submission_type   text not null check (submission_type in ('audio', 'text', 'file')),
  text_content      text,          -- for typed writing
  file_path         text,          -- storage path, for audio + handwritten uploads
  status            text not null default 'submitted'
                      check (status in ('submitted', 'approved', 'rejected')),
  teacher_feedback  text,
  reviewed_by       uuid references public.profiles(id),
  reviewed_at       timestamptz,
  submitted_at      timestamptz not null default now(),
  unique (student_id, learning_step_id)   -- one live submission per step; resubmit overwrites
);
```

**RLS (same model as everything else):**
- Student: read + insert + update **their own** rows only
- Teacher: read + update rows for students **linked to them** via `teacher_students` (status `active`)

**Storage policies:** a student can upload only to `submissions/{their_user_id}/...`; a
teacher can read files belonging to their linked students. **Storage RLS is written
differently from table RLS — do not assume the table policy pattern copies over.**

### Piece 2 — Student: speaking recording

- Record audio in-app (`SpeakingTask.maxRecordingSeconds` already caps length)
- Playback before submitting (let them re-record — this is about proving ability, not
  punishing nerves)
- Upload to `submissions/{student_id}/{step_id}.m4a`
- Insert `student_submissions` row: `skill: 'speaking'`, `submission_type: 'audio'`
- Set step status → `submitted`

**A speaking lesson is complete when submitted, not when approved.** The student should not
be blocked waiting for a teacher. Approval gates the *certificate*, not progression.

### Piece 3 — Student: writing submission (both modes)

**Typed (Mode A):** text field → `text_content`, `submission_type: 'text'`

**Handwritten (Mode B):** file picker (image / PDF / DOCX) → upload → `file_path`,
`submission_type: 'file'`

Which mode a lesson uses is a property of the lesson content (see course structure §3).
For MVP with EXP 001–020, mark 2–3 as handwritten.

### Piece 4 — Teacher: review screen

**New screen:** a review queue.

- List of pending submissions across all the teacher's students
- Filter by student / skill / status
- Open a submission:
  - **Speaking** → audio player
  - **Writing typed** → the text
  - **Writing file** → image viewer / PDF preview / download link
- Show the lesson's **rubric** (already modelled — `Rubric.criteria`) next to it
- **Approve** or **Request redo**, with a feedback text field
- On approve: status → `approved`, `reviewed_by`, `reviewed_at`
- On redo: status → `rejected` + feedback; student sees it and can resubmit

**Reuse the existing teacher screens** (`teacher_student_detail_screen`,
`teacher_student_progress_screen`) rather than building a parallel navigation tree.

### Piece 5 — Per-skill scores + certificate

**Per-skill aggregation.** The standard demands four skills gated independently at 70%,
**never averaged**. So:

```
listening score = mean(score) over completed listening lessons
reading score   = mean(score) over completed reading lessons
speaking score  = % of speaking submissions approved by teacher
writing score   = % of writing submissions approved by teacher
```

**Speaking and writing are NOT auto-scored.** Their "score" is teacher approval rate. This
is the whole differentiator — multiple choice cannot prove someone speaks English.

Because lessons are now single-skill (shipped), each lesson maps to exactly one skill.
This aggregation is a simple query, not an engineering problem — that was the point of the
restructure.

**Certificate eligibility check** — all must be true:
- Every one of the 4 skills ≥ 70%, independently
- All required speaking submissions approved
- All required writing submissions approved
- All checkpoints passed
- Final exam ≥ 75%, every section ≥ 65%
- **Teacher has signed off**

**New table:**
```sql
create table public.certificates (
  id                uuid primary key default gen_random_uuid(),
  certificate_code  text unique not null,     -- public, human-readable, e.g. TSL-A1-7K2M9
  student_id        uuid not null references public.profiles(id),
  issued_by         uuid not null references public.profiles(id),   -- the teacher
  level             text not null,
  listening_score   numeric(4,3) not null,
  reading_score     numeric(4,3) not null,
  speaking_score    numeric(4,3) not null,
  writing_score     numeric(4,3) not null,
  final_exam_score  numeric(4,3) not null,
  issued_at         timestamptz not null default now(),
  revoked_at        timestamptz
);
```

**Teacher sign-off screen:** shows the eligibility checklist with every criterion green or
red. The "Issue certificate" button is **disabled until all criteria pass**. The teacher
cannot override — that is what makes the certificate mean something.

**Verification:** a public page at `/verify/{certificate_code}` showing level, issue date,
per-skill scores, issuing teacher, and the proven can-do statements. No login required —
an employer must be able to check it.

---

## 5. What is explicitly OUT of MVP scope

- The 20-topic content restructure (v2)
- Rewriting EXP 021–040 (hidden for launch — leave hidden)
- Payment / subscriptions
- Placement test
- Class-level assignments (`target_type: 'class'` exists but is unused)
- Realtime updates
- Mobile app store release (web is enough to prove the loop)

---

## 6. Suggested sequence

1. **Piece 1** (Storage + table + RLS) — nothing else works without it
2. **Piece 4** (teacher review screen) — build the destination before the submissions
3. **Piece 2** (speaking recording) — first real submission type
4. **Piece 3** (writing, both modes)
5. **Piece 5** (per-skill scores + certificate + verification page)

**Test the loop end to end after Piece 3:** one student records one speaking task, one
teacher opens it, hears it, approves it. If that works, everything after is repetition.

---

## 7. The honest MVP definition of done

> A student logs in with an access code, completes lessons that are actually scored and
> gated, records themselves speaking, writes something by hand and photographs it. Their
> teacher listens, reads, approves. When every skill clears 70% independently and the exam
> is passed, the teacher signs off and a certificate issues with a verification link an
> employer can check.

Nothing less is a certificate. Everything more is v2.

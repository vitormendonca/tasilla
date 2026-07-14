-- =============================================================================
-- TASILLA — MVP Piece 1: Submissions + Certificates + Storage
-- =============================================================================
-- Run this AFTER tasilla_supabase_schema_v2.sql (which created the 5 base tables).
--
-- Creates:
--   student_submissions  — speaking recordings + writing (typed or uploaded)
--   certificates         — issued certificates with per-skill scores
--   storage bucket       — 'submissions' (private)
--   storage policies     — students upload their own; teachers read their students'
--
-- Safe to run once on a project that already has the base schema.
-- =============================================================================


-- =============================================================================
-- 1. student_submissions
-- =============================================================================
-- One row per student per lesson. Resubmitting after a rejection OVERWRITES
-- (the unique constraint + upsert handles this) — we keep the latest attempt,
-- not a full history. If submission history is ever needed for audit, add a
-- separate submission_attempts table rather than dropping the unique constraint.

create table public.student_submissions (
  id                uuid primary key default gen_random_uuid(),
  student_id        uuid not null references public.profiles(id) on delete cascade,
  learning_step_id  text not null,
  skill             text not null check (skill in ('speaking', 'writing')),
  submission_type   text not null check (submission_type in ('audio', 'text', 'file')),

  text_content      text,        -- typed writing lives here
  file_path         text,        -- storage path for audio + handwritten uploads
                                 -- format: {student_id}/{learning_step_id}.{ext}

  status            text not null default 'submitted'
                      check (status in ('submitted', 'approved', 'rejected')),
  teacher_feedback  text,
  reviewed_by       uuid references public.profiles(id),
  reviewed_at       timestamptz,
  submitted_at      timestamptz not null default now(),

  unique (student_id, learning_step_id),

  -- A submission must actually contain something.
  constraint submission_has_content check (
    (submission_type = 'text' and text_content is not null and length(trim(text_content)) > 0)
    or
    (submission_type in ('audio', 'file') and file_path is not null)
  )
);

create index student_submissions_student_idx  on public.student_submissions (student_id);
create index student_submissions_status_idx   on public.student_submissions (status);
create index student_submissions_skill_idx    on public.student_submissions (student_id, skill, status);
-- ↑ this one powers the per-skill approval-rate query for the certificate check

alter table public.student_submissions enable row level security;

-- Student: sees only their own
create policy student_submissions_read_self
  on public.student_submissions for select
  to authenticated
  using (student_id = auth.uid());

-- Teacher: sees submissions from their linked students only
create policy student_submissions_read_teacher
  on public.student_submissions for select
  to authenticated
  using (
    exists (
      select 1 from public.teacher_students ts
      where ts.teacher_id = auth.uid()
        and ts.student_id = student_submissions.student_id
        and ts.status = 'active'
    )
  );

-- Student: submits their own work
create policy student_submissions_insert_self
  on public.student_submissions for insert
  to authenticated
  with check (student_id = auth.uid());

-- Student: may resubmit (overwrite) their own work.
-- NOTE: Postgres RLS cannot restrict WHICH columns are updated without a trigger.
-- A student could technically set status='approved' on their own row. The trigger
-- below prevents that — do not rely on the policy alone.
create policy student_submissions_update_self
  on public.student_submissions for update
  to authenticated
  using (student_id = auth.uid())
  with check (student_id = auth.uid());

-- Teacher: reviews (approves/rejects) submissions from their linked students
create policy student_submissions_update_teacher
  on public.student_submissions for update
  to authenticated
  using (
    exists (
      select 1 from public.teacher_students ts
      where ts.teacher_id = auth.uid()
        and ts.student_id = student_submissions.student_id
        and ts.status = 'active'
    )
  )
  with check (
    exists (
      select 1 from public.teacher_students ts
      where ts.teacher_id = auth.uid()
        and ts.student_id = student_submissions.student_id
        and ts.status = 'active'
    )
  );


-- ---------------------------------------------------------------------------
-- Trigger: students cannot approve their own work
-- ---------------------------------------------------------------------------
-- This is the teeth behind the certificate. Without it, a student could UPDATE
-- their own submission row to status='approved' and self-certify.

create or replace function public.enforce_submission_review_authority()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_role text;
begin
  select role into actor_role from public.profiles where id = auth.uid();

  -- If the actor is the student who owns this row, they may only resubmit —
  -- never set review fields.
  if auth.uid() = new.student_id then
    if new.status is distinct from 'submitted' then
      raise exception 'A student cannot set the review status of their own submission.';
    end if;
    if new.teacher_feedback is distinct from old.teacher_feedback
       or new.reviewed_by is distinct from old.reviewed_by
       or new.reviewed_at is distinct from old.reviewed_at then
      raise exception 'A student cannot write teacher review fields.';
    end if;
  end if;

  -- If a review status is being set, the actor must be a teacher.
  if new.status in ('approved', 'rejected')
     and new.status is distinct from old.status then
    if actor_role is distinct from 'teacher' then
      raise exception 'Only a teacher can approve or reject a submission.';
    end if;
    new.reviewed_by := auth.uid();
    new.reviewed_at := now();
  end if;

  return new;
end;
$$;

create trigger student_submissions_review_authority
  before update on public.student_submissions
  for each row
  execute function public.enforce_submission_review_authority();


-- =============================================================================
-- 2. certificates
-- =============================================================================

create table public.certificates (
  id                uuid primary key default gen_random_uuid(),
  certificate_code  text unique not null,   -- public, human-readable: TSL-A1-7K2M9
  student_id        uuid not null references public.profiles(id) on delete cascade,
  issued_by         uuid not null references public.profiles(id),   -- the teacher
  level             text not null,

  listening_score   numeric(4,3) not null,
  reading_score     numeric(4,3) not null,
  speaking_score    numeric(4,3) not null,
  writing_score     numeric(4,3) not null,
  final_exam_score  numeric(4,3) not null,

  issued_at         timestamptz not null default now(),
  revoked_at        timestamptz,

  -- The four-skill rule, enforced in the database itself. A certificate row that
  -- violates the standard cannot physically exist.
  constraint four_skill_minimum check (
    listening_score >= 0.70
    and reading_score  >= 0.70
    and speaking_score >= 0.70
    and writing_score  >= 0.70
  ),
  constraint final_exam_minimum check (final_exam_score >= 0.75)
);

create index certificates_student_idx on public.certificates (student_id);
create unique index certificates_code_idx on public.certificates (certificate_code);

alter table public.certificates enable row level security;

-- Student: sees their own certificates
create policy certificates_read_self
  on public.certificates for select
  to authenticated
  using (student_id = auth.uid());

-- Teacher: sees certificates they issued
create policy certificates_read_teacher
  on public.certificates for select
  to authenticated
  using (issued_by = auth.uid());

-- Only a teacher may issue, and only for a student linked to them
create policy certificates_insert_teacher
  on public.certificates for insert
  to authenticated
  with check (
    issued_by = auth.uid()
    and exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and p.role = 'teacher'
    )
    and exists (
      select 1 from public.teacher_students ts
      where ts.teacher_id = auth.uid()
        and ts.student_id = certificates.student_id
        and ts.status = 'active'
    )
  );

-- PUBLIC verification: anyone (even signed out) can look up a certificate by code.
-- This is what makes the certificate checkable by an employer.
create policy certificates_public_verify
  on public.certificates for select
  to anon
  using (revoked_at is null);


-- =============================================================================
-- 3. Storage bucket + policies
-- =============================================================================
-- Private bucket. Files are namespaced by student id:
--     submissions/{student_id}/{learning_step_id}.{ext}
--
-- Storage RLS works on storage.objects, and the path is split into segments by
-- storage.foldername(). The FIRST folder segment is the student's uuid — that is
-- what these policies check against.

insert into storage.buckets (id, name, public)
values ('submissions', 'submissions', false)
on conflict (id) do nothing;

-- Student: upload into their own folder only
create policy submissions_insert_own_folder
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'submissions'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Student: overwrite their own files (resubmission)
create policy submissions_update_own_folder
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'submissions'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Student: read their own files back
create policy submissions_read_own_folder
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'submissions'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Teacher: read files belonging to their linked students
create policy submissions_read_linked_students
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'submissions'
    and exists (
      select 1 from public.teacher_students ts
      where ts.teacher_id = auth.uid()
        and ts.student_id::text = (storage.foldername(name))[1]
        and ts.status = 'active'
    )
  );


-- =============================================================================
-- Verification
-- =============================================================================
--   select tablename, rowsecurity from pg_tables
--     where schemaname = 'public'
--       and tablename in ('student_submissions', 'certificates');
--     -- both should show rowsecurity = true
--
--   select id, public from storage.buckets where id = 'submissions';
--     -- should exist, public = false
--
--   select policyname from pg_policies
--     where tablename = 'objects' and schemaname = 'storage';
--     -- should list the 4 submissions_* policies
-- =============================================================================

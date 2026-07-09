-- TASILLA MVP database schema for Supabase/Postgres.
-- Apply this file in the Supabase SQL editor or with the Supabase CLI.

create extension if not exists pgcrypto;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  organization_id uuid references public.organizations(id) on delete set null,
  role text not null check (role in ('student', 'teacher', 'admin')),
  full_name text not null,
  current_level text not null default 'A1',
  access_code text unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete cascade,
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  description text not null default '',
  class_type text not null default 'Group'
    check (class_type in ('Individual', 'Group')),
  class_code text not null unique,
  class_day text,
  class_time text,
  frequency text,
  format text check (format is null or format in ('Online', 'Presential')),
  status text not null default 'active'
    check (status in ('active', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.teacher_students (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete cascade,
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  class_type text not null default 'Individual'
    check (class_type in ('Individual', 'Group')),
  class_day text,
  class_time text,
  frequency text,
  format text check (format is null or format in ('Online', 'Presential')),
  status text not null default 'active'
    check (status in ('active', 'archived')),
  created_at timestamptz not null default now(),
  unique (teacher_id, student_id)
);

create table if not exists public.class_students (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'active'
    check (status in ('active', 'archived')),
  joined_at timestamptz not null default now(),
  unique (class_id, student_id)
);

create table if not exists public.skills (
  id text primary key,
  title text not null,
  description text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.learning_steps (
  id text primary key,
  level text not null,
  skill_id text not null references public.skills(id) on delete cascade,
  title text not null,
  description text not null,
  step_type text not null check (step_type in ('lesson', 'review', 'final_test')),
  step_order int not null,
  lesson_number int,
  review_number int,
  passing_score int not null default 85 check (passing_score between 0 and 100),
  created_at timestamptz not null default now(),
  unique (level, skill_id, step_order)
);

create table if not exists public.exercises (
  id text primary key,
  learning_step_id text references public.learning_steps(id) on delete set null,
  skill_id text not null references public.skills(id) on delete restrict,
  level text not null default 'A1',
  title text not null,
  description text not null default '',
  instructions text not null default '',
  content jsonb not null default '{}'::jsonb,
  passing_score int not null default 85 check (passing_score between 0 and 100),
  is_published boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.exercise_questions (
  id uuid primary key default gen_random_uuid(),
  exercise_id text not null references public.exercises(id) on delete cascade,
  question_order int not null,
  prompt text not null,
  options jsonb not null default '[]'::jsonb,
  correct_answer text,
  explanation text,
  created_at timestamptz not null default now(),
  unique (exercise_id, question_order)
);

create table if not exists public.assignments (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid references public.profiles(id) on delete cascade,
  class_id uuid references public.classes(id) on delete cascade,
  exercise_id text references public.exercises(id) on delete set null,
  learning_step_id text references public.learning_steps(id) on delete set null,
  target_type text not null default 'student'
    check (target_type in ('student', 'class')),
  check (
    (target_type = 'student' and student_id is not null)
    or (target_type = 'class' and class_id is not null)
  ),
  title text not null,
  category text not null,
  level text not null default 'A1',
  due_date date,
  note text not null default '',
  status text not null default 'pending'
    check (status in ('pending', 'completed', 'review_needed', 'reviewed', 'canceled')),
  assigned_at timestamptz not null default now(),
  completed_at timestamptz,
  reviewed_at timestamptz
);

create table if not exists public.attempts (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  assignment_id uuid references public.assignments(id) on delete set null,
  exercise_id text references public.exercises(id) on delete set null,
  learning_step_id text references public.learning_steps(id) on delete set null,
  score int not null check (score between 0 and 100),
  status text not null check (status in ('completed', 'review_needed')),
  answers jsonb not null default '{}'::jsonb,
  started_at timestamptz not null default now(),
  completed_at timestamptz not null default now()
);

create table if not exists public.student_step_progress (
  student_id uuid not null references public.profiles(id) on delete cascade,
  learning_step_id text not null references public.learning_steps(id) on delete cascade,
  status text not null default 'completed'
    check (status in ('completed', 'validated')),
  best_score int check (best_score is null or best_score between 0 and 100),
  validated_by_level_check boolean not null default false,
  completed_at timestamptz not null default now(),
  primary key (student_id, learning_step_id)
);

create table if not exists public.teacher_reviews (
  id uuid primary key default gen_random_uuid(),
  teacher_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  assignment_id uuid references public.assignments(id) on delete set null,
  attempt_id uuid references public.attempts(id) on delete set null,
  status text not null default 'reviewed'
    check (status in ('reviewed', 'needs_retry')),
  feedback text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.level_check_attempts (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  level text not null,
  score int not null check (score between 0 and 100),
  passed boolean not null,
  answers jsonb not null default '{}'::jsonb,
  completed_at timestamptz not null default now()
);

create table if not exists public.certificates (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  level text not null,
  certificate_code text not null unique,
  issued_at timestamptz not null default now(),
  revoked_at timestamptz,
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.plans (
  id text primary key,
  name text not null,
  max_students int,
  price_cents int not null default 0,
  currency text not null default 'BRL',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  plan_id text not null references public.plans(id) on delete restrict,
  provider text not null default 'manual'
    check (provider in ('manual', 'mercado_pago', 'stripe', 'revenuecat')),
  provider_subscription_id text,
  status text not null default 'trialing'
    check (status in ('trialing', 'active', 'past_due', 'canceled', 'expired')),
  current_period_start timestamptz,
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_classes_teacher on public.classes(teacher_id);
create index if not exists idx_teacher_students_teacher on public.teacher_students(teacher_id);
create index if not exists idx_teacher_students_student on public.teacher_students(student_id);
create index if not exists idx_class_students_class on public.class_students(class_id);
create index if not exists idx_class_students_student on public.class_students(student_id);
create index if not exists idx_learning_steps_skill_order on public.learning_steps(skill_id, step_order);
create index if not exists idx_exercises_skill_level on public.exercises(skill_id, level);
create index if not exists idx_assignments_teacher on public.assignments(teacher_id);
create index if not exists idx_assignments_student_status on public.assignments(student_id, status);
create index if not exists idx_assignments_class_status on public.assignments(class_id, status);
create index if not exists idx_attempts_student on public.attempts(student_id);
create index if not exists idx_attempts_assignment on public.attempts(assignment_id);
create index if not exists idx_student_step_progress_student on public.student_step_progress(student_id);

create unique index if not exists idx_assignments_open_student_unique
on public.assignments (teacher_id, student_id, title, category)
where student_id is not null
  and status in ('pending', 'completed', 'review_needed');

create unique index if not exists idx_assignments_open_class_unique
on public.assignments (teacher_id, class_id, title, category)
where class_id is not null
  and status in ('pending', 'completed', 'review_needed');

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_organizations_updated_at on public.organizations;
create trigger set_organizations_updated_at
before update on public.organizations
for each row execute function public.set_updated_at();

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_classes_updated_at on public.classes;
create trigger set_classes_updated_at
before update on public.classes
for each row execute function public.set_updated_at();

drop trigger if exists set_exercises_updated_at on public.exercises;
create trigger set_exercises_updated_at
before update on public.exercises
for each row execute function public.set_updated_at();

drop trigger if exists set_subscriptions_updated_at on public.subscriptions;
create trigger set_subscriptions_updated_at
before update on public.subscriptions
for each row execute function public.set_updated_at();

create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.is_teacher_for_student(student_profile_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.teacher_students ts
    where ts.teacher_id = auth.uid()
      and ts.student_id = student_profile_id
      and ts.status = 'active'
  )
$$;

create or replace function public.is_student_in_class(class_row_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.class_students cs
    where cs.class_id = class_row_id
      and cs.student_id = auth.uid()
      and cs.status = 'active'
  )
$$;

alter table public.organizations enable row level security;
alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.teacher_students enable row level security;
alter table public.class_students enable row level security;
alter table public.skills enable row level security;
alter table public.learning_steps enable row level security;
alter table public.exercises enable row level security;
alter table public.exercise_questions enable row level security;
alter table public.assignments enable row level security;
alter table public.attempts enable row level security;
alter table public.student_step_progress enable row level security;
alter table public.teacher_reviews enable row level security;
alter table public.level_check_attempts enable row level security;
alter table public.certificates enable row level security;
alter table public.plans enable row level security;
alter table public.subscriptions enable row level security;

drop policy if exists "organizations visible to members" on public.organizations;
create policy "organizations visible to members"
on public.organizations
for select
to authenticated
using (
  owner_id = auth.uid()
  or id in (select organization_id from public.profiles where id = auth.uid())
  or public.current_user_role() = 'admin'
);

drop policy if exists "profiles visible to owner and teacher" on public.profiles;
create policy "profiles visible to owner and teacher"
on public.profiles
for select
to authenticated
using (
  id = auth.uid()
  or public.is_teacher_for_student(id)
  or public.current_user_role() = 'admin'
);

drop policy if exists "profiles update own profile" on public.profiles;
create policy "profiles update own profile"
on public.profiles
for update
to authenticated
using (id = auth.uid() or public.current_user_role() = 'admin')
with check (id = auth.uid() or public.current_user_role() = 'admin');

drop policy if exists "classes visible to teacher and students" on public.classes;
create policy "classes visible to teacher and students"
on public.classes
for select
to authenticated
using (
  teacher_id = auth.uid()
  or public.is_student_in_class(id)
  or public.current_user_role() = 'admin'
);

drop policy if exists "teachers manage their classes" on public.classes;
create policy "teachers manage their classes"
on public.classes
for all
to authenticated
using (teacher_id = auth.uid() or public.current_user_role() = 'admin')
with check (teacher_id = auth.uid() or public.current_user_role() = 'admin');

drop policy if exists "teacher student links visible to participants" on public.teacher_students;
create policy "teacher student links visible to participants"
on public.teacher_students
for select
to authenticated
using (
  teacher_id = auth.uid()
  or student_id = auth.uid()
  or public.current_user_role() = 'admin'
);

drop policy if exists "teachers manage their student links" on public.teacher_students;
create policy "teachers manage their student links"
on public.teacher_students
for all
to authenticated
using (teacher_id = auth.uid() or public.current_user_role() = 'admin')
with check (teacher_id = auth.uid() or public.current_user_role() = 'admin');

drop policy if exists "class student links visible to participants" on public.class_students;
create policy "class student links visible to participants"
on public.class_students
for select
to authenticated
using (
  student_id = auth.uid()
  or exists (
    select 1
    from public.classes c
    where c.id = class_id
      and c.teacher_id = auth.uid()
  )
  or public.current_user_role() = 'admin'
);

drop policy if exists "teachers manage their class students" on public.class_students;
create policy "teachers manage their class students"
on public.class_students
for all
to authenticated
using (
  exists (
    select 1
    from public.classes c
    where c.id = class_id
      and c.teacher_id = auth.uid()
  )
  or public.current_user_role() = 'admin'
)
with check (
  exists (
    select 1
    from public.classes c
    where c.id = class_id
      and c.teacher_id = auth.uid()
  )
  or public.current_user_role() = 'admin'
);

drop policy if exists "authenticated users read skills" on public.skills;
create policy "authenticated users read skills"
on public.skills
for select
to authenticated
using (true);

drop policy if exists "authenticated users read learning steps" on public.learning_steps;
create policy "authenticated users read learning steps"
on public.learning_steps
for select
to authenticated
using (true);

drop policy if exists "authenticated users read published exercises" on public.exercises;
create policy "authenticated users read published exercises"
on public.exercises
for select
to authenticated
using (is_published = true or public.current_user_role() in ('teacher', 'admin'));

drop policy if exists "authenticated users read exercise questions" on public.exercise_questions;
create policy "authenticated users read exercise questions"
on public.exercise_questions
for select
to authenticated
using (
  exists (
    select 1
    from public.exercises e
    where e.id = exercise_id
      and (e.is_published = true or public.current_user_role() in ('teacher', 'admin'))
  )
);

drop policy if exists "assignments visible to participants" on public.assignments;
create policy "assignments visible to participants"
on public.assignments
for select
to authenticated
using (
  teacher_id = auth.uid()
  or student_id = auth.uid()
  or (
    class_id is not null
    and public.is_student_in_class(class_id)
  )
  or public.current_user_role() = 'admin'
);

drop policy if exists "teachers create assignments" on public.assignments;
create policy "teachers create assignments"
on public.assignments
for insert
to authenticated
with check (teacher_id = auth.uid() or public.current_user_role() = 'admin');

drop policy if exists "participants update assignments" on public.assignments;
create policy "participants update assignments"
on public.assignments
for update
to authenticated
using (
  teacher_id = auth.uid()
  or student_id = auth.uid()
  or public.current_user_role() = 'admin'
)
with check (
  teacher_id = auth.uid()
  or student_id = auth.uid()
  or public.current_user_role() = 'admin'
);

drop policy if exists "attempts visible to student and teacher" on public.attempts;
create policy "attempts visible to student and teacher"
on public.attempts
for select
to authenticated
using (
  student_id = auth.uid()
  or public.is_teacher_for_student(student_id)
  or public.current_user_role() = 'admin'
);

drop policy if exists "students create their attempts" on public.attempts;
create policy "students create their attempts"
on public.attempts
for insert
to authenticated
with check (student_id = auth.uid() or public.current_user_role() = 'admin');

drop policy if exists "step progress visible to student and teacher" on public.student_step_progress;
create policy "step progress visible to student and teacher"
on public.student_step_progress
for select
to authenticated
using (
  student_id = auth.uid()
  or public.is_teacher_for_student(student_id)
  or public.current_user_role() = 'admin'
);

drop policy if exists "students write their step progress" on public.student_step_progress;
create policy "students write their step progress"
on public.student_step_progress
for insert
to authenticated
with check (student_id = auth.uid() or public.current_user_role() = 'admin');

drop policy if exists "students update their step progress" on public.student_step_progress;
create policy "students update their step progress"
on public.student_step_progress
for update
to authenticated
using (student_id = auth.uid() or public.current_user_role() = 'admin')
with check (student_id = auth.uid() or public.current_user_role() = 'admin');

drop policy if exists "reviews visible to student and teacher" on public.teacher_reviews;
create policy "reviews visible to student and teacher"
on public.teacher_reviews
for select
to authenticated
using (
  teacher_id = auth.uid()
  or student_id = auth.uid()
  or public.current_user_role() = 'admin'
);

drop policy if exists "teachers create reviews" on public.teacher_reviews;
create policy "teachers create reviews"
on public.teacher_reviews
for insert
to authenticated
with check (teacher_id = auth.uid() or public.current_user_role() = 'admin');

drop policy if exists "level checks visible to student and teacher" on public.level_check_attempts;
create policy "level checks visible to student and teacher"
on public.level_check_attempts
for select
to authenticated
using (
  student_id = auth.uid()
  or public.is_teacher_for_student(student_id)
  or public.current_user_role() = 'admin'
);

drop policy if exists "students create level checks" on public.level_check_attempts;
create policy "students create level checks"
on public.level_check_attempts
for insert
to authenticated
with check (student_id = auth.uid() or public.current_user_role() = 'admin');

drop policy if exists "certificates visible to student and teacher" on public.certificates;
create policy "certificates visible to student and teacher"
on public.certificates
for select
to authenticated
using (
  student_id = auth.uid()
  or public.is_teacher_for_student(student_id)
  or public.current_user_role() = 'admin'
);

drop policy if exists "authenticated users read plans" on public.plans;
create policy "authenticated users read plans"
on public.plans
for select
to authenticated
using (is_active = true or public.current_user_role() = 'admin');

drop policy if exists "organization subscriptions visible to owner" on public.subscriptions;
create policy "organization subscriptions visible to owner"
on public.subscriptions
for select
to authenticated
using (
  organization_id in (
    select id from public.organizations where owner_id = auth.uid()
  )
  or public.current_user_role() = 'admin'
);

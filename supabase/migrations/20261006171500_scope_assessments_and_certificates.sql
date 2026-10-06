alter table public.attempts
 add column if not exists teacher_id uuid references public.profiles(id),
 add column if not exists organization_id uuid references public.organizations(id) on delete cascade;
alter table public.level_check_attempts
 add column if not exists teacher_id uuid references public.profiles(id),
 add column if not exists organization_id uuid references public.organizations(id) on delete cascade;

alter table public.attempts drop constraint if exists attempts_student_id_learning_step_id_attempt_number_key;
create unique index if not exists attempts_teaching_context_number_key
 on public.attempts(student_id,teacher_id,organization_id,learning_step_id,attempt_number) nulls not distinct;
create index if not exists attempts_teacher_context_idx
 on public.attempts(teacher_id,organization_id,student_id,completed_at desc);
create index if not exists level_check_attempts_teacher_context_idx
 on public.level_check_attempts(teacher_id,organization_id,student_id,attempted_at desc);

drop policy if exists attempts_insert_self on public.attempts;
create policy attempts_insert_self on public.attempts for insert to authenticated
with check(student_id=(select auth.uid()) and teacher_id is not null and exists(
 select 1 from public.teacher_students ts where ts.teacher_id=attempts.teacher_id
 and ts.student_id=(select auth.uid()) and ts.status='active'
 and ts.organization_id is not distinct from attempts.organization_id
));
drop policy if exists attempts_read_teacher on public.attempts;
create policy attempts_read_teacher on public.attempts for select to authenticated
using(teacher_id=(select auth.uid()) and exists(
 select 1 from public.teacher_students ts where ts.teacher_id=(select auth.uid())
 and ts.student_id=attempts.student_id and ts.status='active'
 and ts.organization_id is not distinct from attempts.organization_id
));

drop policy if exists level_check_attempts_insert_self on public.level_check_attempts;
create policy level_check_attempts_insert_self on public.level_check_attempts for insert to authenticated
with check(student_id=(select auth.uid()) and teacher_id is not null and exists(
 select 1 from public.teacher_students ts where ts.teacher_id=level_check_attempts.teacher_id
 and ts.student_id=(select auth.uid()) and ts.status='active'
 and ts.organization_id is not distinct from level_check_attempts.organization_id
));
drop policy if exists level_check_attempts_read_teacher on public.level_check_attempts;
create policy level_check_attempts_read_teacher on public.level_check_attempts for select to authenticated
using(teacher_id=(select auth.uid()) and exists(
 select 1 from public.teacher_students ts where ts.teacher_id=(select auth.uid())
 and ts.student_id=level_check_attempts.student_id and ts.status='active'
 and ts.organization_id is not distinct from level_check_attempts.organization_id
));

drop policy if exists certificates_insert_teacher on public.certificates;
create policy certificates_insert_teacher on public.certificates for insert to authenticated
with check(
 issued_by=(select auth.uid())
 and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='teacher')
 and exists(select 1 from public.teacher_students ts where ts.teacher_id=(select auth.uid())
   and ts.student_id=certificates.student_id and ts.status='active'
   and ts.organization_id is not distinct from certificates.organization_id)
 and (certificates.organization_id is null or (
   exists(select 1 from public.organization_members tm where tm.organization_id=certificates.organization_id
     and tm.user_id=(select auth.uid()) and tm.role='teacher')
   and exists(select 1 from public.organization_members sm where sm.organization_id=certificates.organization_id
     and sm.user_id=certificates.student_id and sm.role='student')
 ))
);
drop policy if exists certificates_read_teacher on public.certificates;
create policy certificates_read_teacher on public.certificates for select to authenticated
using(
 issued_by=(select auth.uid())
 and exists(select 1 from public.teacher_students ts where ts.teacher_id=(select auth.uid())
   and ts.student_id=certificates.student_id and ts.status='active'
   and ts.organization_id is not distinct from certificates.organization_id)
);
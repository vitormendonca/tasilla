alter table public.student_step_progress
 add column if not exists teacher_id uuid references public.profiles(id),
 add column if not exists organization_id uuid references public.organizations(id) on delete cascade;

alter table public.student_step_progress
 drop constraint if exists student_step_progress_student_id_learning_step_id_key;

create unique index if not exists student_step_progress_teaching_context_key
 on public.student_step_progress(student_id,teacher_id,organization_id,learning_step_id) nulls not distinct;

create index if not exists student_step_progress_teacher_context_idx
 on public.student_step_progress(teacher_id,organization_id,status,updated_at desc);

drop policy if exists student_step_progress_write_self on public.student_step_progress;
create policy student_step_progress_write_self on public.student_step_progress
for insert to authenticated
with check (
 student_id=(select auth.uid())
 and teacher_id is not null
 and exists(
   select 1 from public.teacher_students ts
   where ts.teacher_id=student_step_progress.teacher_id
     and ts.student_id=(select auth.uid())
     and ts.status='active'
     and ts.organization_id is not distinct from student_step_progress.organization_id
 )
);

drop policy if exists student_step_progress_update_self on public.student_step_progress;
create policy student_step_progress_update_self on public.student_step_progress
for update to authenticated
using (
 student_id=(select auth.uid())
 and exists(
   select 1 from public.teacher_students ts
   where ts.teacher_id=student_step_progress.teacher_id
     and ts.student_id=(select auth.uid())
     and ts.status='active'
     and ts.organization_id is not distinct from student_step_progress.organization_id
 )
)
with check (
 student_id=(select auth.uid())
 and exists(
   select 1 from public.teacher_students ts
   where ts.teacher_id=student_step_progress.teacher_id
     and ts.student_id=(select auth.uid())
     and ts.status='active'
     and ts.organization_id is not distinct from student_step_progress.organization_id
 )
);

drop policy if exists student_step_progress_read_teacher on public.student_step_progress;
create policy student_step_progress_read_teacher on public.student_step_progress
for select to authenticated
using (
 teacher_id=(select auth.uid())
 and exists(
   select 1 from public.teacher_students ts
   where ts.teacher_id=(select auth.uid())
     and ts.student_id=student_step_progress.student_id
     and ts.status='active'
     and ts.organization_id is not distinct from student_step_progress.organization_id
 )
);
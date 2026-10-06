alter table public.student_submissions
  add column if not exists teacher_id uuid references public.profiles(id),
  add column if not exists organization_id uuid references public.organizations(id) on delete cascade;

update public.student_submissions s
set teacher_id=(select ts.teacher_id from public.teacher_students ts where ts.student_id=s.student_id and ts.status='active' order by ts.created_at limit 1),
    organization_id=(select ts.organization_id from public.teacher_students ts where ts.student_id=s.student_id and ts.status='active' order by ts.created_at limit 1)
where s.teacher_id is null
  and 1=(select count(*) from public.teacher_students ts2 where ts2.student_id=s.student_id and ts2.status='active');

do $$ begin
  if exists(select 1 from public.student_submissions where teacher_id is null) then
    raise exception 'Cannot enforce submission teacher context: unresolved existing rows';
  end if;
end $$;

alter table public.student_submissions alter column teacher_id set not null;
alter table public.student_submissions drop constraint if exists student_submissions_student_id_learning_step_id_key;
drop index if exists public.student_submissions_independent_context_key;
drop index if exists public.student_submissions_school_context_key;
create unique index if not exists student_submissions_teaching_context_key
  on public.student_submissions(student_id,teacher_id,organization_id,learning_step_id) nulls not distinct;
create index if not exists student_submissions_teacher_context_idx
  on public.student_submissions(teacher_id,organization_id,status,submitted_at desc);

drop policy if exists student_submissions_insert_self on public.student_submissions;
create policy student_submissions_insert_self on public.student_submissions for insert to authenticated
with check (student_id=(select auth.uid()) and exists(
  select 1 from public.teacher_students ts
  where ts.teacher_id=student_submissions.teacher_id
    and ts.student_id=(select auth.uid())
    and ts.status='active'
    and ts.organization_id is not distinct from student_submissions.organization_id
));

drop policy if exists student_submissions_read_teacher on public.student_submissions;
create policy student_submissions_read_teacher on public.student_submissions for select to authenticated
using (teacher_id=(select auth.uid()) and exists(
  select 1 from public.teacher_students ts
  where ts.teacher_id=(select auth.uid())
    and ts.student_id=student_submissions.student_id
    and ts.status='active'
    and ts.organization_id is not distinct from student_submissions.organization_id
));

drop policy if exists student_submissions_update_teacher on public.student_submissions;
create policy student_submissions_update_teacher on public.student_submissions for update to authenticated
using (teacher_id=(select auth.uid()) and exists(
  select 1 from public.teacher_students ts
  where ts.teacher_id=(select auth.uid())
    and ts.student_id=student_submissions.student_id
    and ts.status='active'
    and ts.organization_id is not distinct from student_submissions.organization_id
))
with check (teacher_id=(select auth.uid()) and exists(
  select 1 from public.teacher_students ts
  where ts.teacher_id=(select auth.uid())
    and ts.student_id=student_submissions.student_id
    and ts.status='active'
    and ts.organization_id is not distinct from student_submissions.organization_id
));

create or replace function public.enforce_submission_review_authority()
returns trigger language plpgsql security definer set search_path='' as $$
declare actor_role text;
begin
  select role into actor_role from public.profiles where id=auth.uid();
  if auth.uid()=new.student_id then
    if new.teacher_id is distinct from old.teacher_id
       or new.organization_id is distinct from old.organization_id
       or new.student_id is distinct from old.student_id
       or new.learning_step_id is distinct from old.learning_step_id then
      raise exception 'A student cannot change submission teaching context.';
    end if;
    if new.status is distinct from 'submitted' then
      raise exception 'A student cannot set the review status of their own submission.';
    end if;
    if new.teacher_feedback is distinct from old.teacher_feedback
       or new.reviewed_by is distinct from old.reviewed_by
       or new.reviewed_at is distinct from old.reviewed_at then
      raise exception 'A student cannot write teacher review fields.';
    end if;
  end if;
  if auth.uid()<>new.student_id and (
       new.teacher_id is distinct from old.teacher_id
       or new.organization_id is distinct from old.organization_id
       or new.student_id is distinct from old.student_id
       or new.learning_step_id is distinct from old.learning_step_id) then
    raise exception 'A reviewer cannot change submission teaching context.';
  end if;
  if new.status in ('approved','rejected') and new.status is distinct from old.status then
    if actor_role is distinct from 'teacher' or auth.uid() is distinct from new.teacher_id then
      raise exception 'Only the assigned teacher can approve or reject a submission.';
    end if;
    new.reviewed_by:=auth.uid();
    new.reviewed_at:=now();
  end if;
  return new;
end $$;
revoke all on function public.enforce_submission_review_authority() from public,anon,authenticated;
grant execute on function public.enforce_submission_review_authority() to service_role;

drop policy if exists submissions_read_linked_students on storage.objects;
drop policy if exists submissions_read_scoped_teacher on storage.objects;
create policy submissions_read_scoped_teacher on storage.objects for select to authenticated
using (
  bucket_id='submissions'
  and (storage.foldername(name))[2]=(select auth.uid())::text
  and exists(
    select 1 from public.teacher_students ts
    where ts.teacher_id=(select auth.uid())
      and ts.student_id::text=(storage.foldername(name))[1]
      and ts.status='active'
      and (
        (ts.organization_id is null and (storage.foldername(name))[3]='independent')
        or (ts.organization_id is not null and ts.organization_id::text=(storage.foldername(name))[3])
      )
  )
);
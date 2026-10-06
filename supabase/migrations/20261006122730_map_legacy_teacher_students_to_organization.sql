alter table public.teacher_students
  add column if not exists organization_id uuid
  references public.organizations(id) on delete set null;

create index if not exists teacher_students_organization_id_idx
  on public.teacher_students(organization_id);

create or replace function public.map_teacher_student_to_organization(
  relationship_id uuid,
  target_organization_id uuid
)
returns public.teacher_students
language plpgsql
security invoker
set search_path = ''
as $$
declare
  relationship public.teacher_students;
  target_role text;
  result_row public.teacher_students;
begin
  select *
    into relationship
    from public.teacher_students
   where id = relationship_id
     and teacher_id = (select auth.uid())
   for update;

  if relationship.id is null then
    raise exception 'Teacher-student relationship not found or not owned by current teacher';
  end if;

  if relationship.organization_id is not null
     and relationship.organization_id <> target_organization_id then
    raise exception 'Relationship is already mapped to another organization';
  end if;

  if not exists (
    select 1 from public.organization_members
     where organization_id = target_organization_id
       and user_id = (select auth.uid())
       and role in ('owner','admin','teacher')
  ) then
    raise exception 'Current teacher is not staff in the target organization';
  end if;

  select role into target_role from public.profiles where id = relationship.student_id;
  if target_role <> 'student' then
    raise exception 'Target user is not a student';
  end if;

  insert into public.organization_members (organization_id, user_id, role)
  values (target_organization_id, relationship.student_id, 'student')
  on conflict (organization_id, user_id) do nothing;

  update public.teacher_students
     set organization_id = target_organization_id
   where id = relationship.id
  returning * into result_row;

  return result_row;
end;
$$;

revoke execute on function public.map_teacher_student_to_organization(uuid, uuid) from public;
revoke execute on function public.map_teacher_student_to_organization(uuid, uuid) from anon;
revoke execute on function public.map_teacher_student_to_organization(uuid, uuid) from authenticated;
grant execute on function public.map_teacher_student_to_organization(uuid, uuid) to authenticated;

drop policy if exists "teacher_students_update_teacher" on public.teacher_students;
create policy "teacher_students_update_teacher"
on public.teacher_students
for update
to authenticated
using ((select auth.uid()) = teacher_id)
with check (
  (select auth.uid()) = teacher_id
  and (
    organization_id is null
    or exists (
      select 1 from public.organization_members actor
       where actor.organization_id = teacher_students.organization_id
         and actor.user_id = (select auth.uid())
         and actor.role in ('owner','admin','teacher')
    )
  )
);
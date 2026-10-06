alter table public.assignments
  add column if not exists organization_id uuid references public.organizations(id) on delete cascade;

create index if not exists assignments_organization_id_idx
  on public.assignments (organization_id);

drop policy if exists "assignments_insert_teacher" on public.assignments;
drop policy if exists "assignments_read_student" on public.assignments;
drop policy if exists "assignments_read_teacher" on public.assignments;
drop policy if exists "assignments_update_student_status" on public.assignments;
drop policy if exists "assignments_update_teacher" on public.assignments;

create policy "assignments_read_student"
on public.assignments for select to authenticated
using (
  student_id = (select auth.uid())
  and (
    organization_id is null
    or exists (
      select 1 from public.organization_members om
      where om.organization_id = assignments.organization_id
        and om.user_id = (select auth.uid())
        and om.role = 'student'
    )
  )
);

create policy "assignments_read_staff"
on public.assignments for select to authenticated
using (
  teacher_id = (select auth.uid())
  or (
    organization_id is not null
    and exists (
      select 1 from public.organization_members om
      where om.organization_id = assignments.organization_id
        and om.user_id = (select auth.uid())
        and om.role in ('owner','admin','teacher')
    )
  )
);

create policy "assignments_insert_staff"
on public.assignments for insert to authenticated
with check (
  teacher_id = (select auth.uid())
  and (
    (
      organization_id is null
      and not exists (
        select 1 from public.organization_members om
        where om.user_id = (select auth.uid())
      )
      and (
        student_id is null
        or exists (
          select 1 from public.teacher_students ts
          where ts.teacher_id = (select auth.uid())
            and ts.student_id = assignments.student_id
            and ts.status = 'active'
        )
      )
    )
    or (
      organization_id is not null
      and exists (
        select 1 from public.organization_members om
        where om.organization_id = assignments.organization_id
          and om.user_id = (select auth.uid())
          and om.role in ('owner','admin','teacher')
      )
      and (
        student_id is null
        or exists (
          select 1 from public.organization_members sm
          where sm.organization_id = assignments.organization_id
            and sm.user_id = assignments.student_id
            and sm.role = 'student'
        )
      )
      and (
        class_id is null
        or exists (
          select 1 from public.classes c
          where c.id = assignments.class_id
            and c.organization_id = assignments.organization_id
        )
      )
    )
  )
);

create policy "assignments_update_student_status"
on public.assignments for update to authenticated
using (student_id = (select auth.uid()))
with check (student_id = (select auth.uid()));

create policy "assignments_update_staff"
on public.assignments for update to authenticated
using (
  teacher_id = (select auth.uid())
  or (
    organization_id is not null
    and exists (
      select 1 from public.organization_members om
      where om.organization_id = assignments.organization_id
        and om.user_id = (select auth.uid())
        and om.role in ('owner','admin','teacher')
    )
  )
)
with check (
  (
    teacher_id = (select auth.uid())
    or (
      organization_id is not null
      and exists (
        select 1 from public.organization_members om
        where om.organization_id = assignments.organization_id
          and om.user_id = (select auth.uid())
          and om.role in ('owner','admin','teacher')
      )
    )
  )
  and (
    organization_id is null
    or exists (
      select 1 from public.organization_members om
      where om.organization_id = assignments.organization_id
        and om.user_id = assignments.teacher_id
        and om.role in ('owner','admin','teacher')
    )
  )
);

create or replace function public.prevent_student_assignment_reassignment()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if (old.student_id = (select auth.uid())) then
    if new.student_id is distinct from old.student_id
       or new.teacher_id is distinct from old.teacher_id
       or new.organization_id is distinct from old.organization_id
       or new.class_id is distinct from old.class_id
       or new.title is distinct from old.title
       or new.category is distinct from old.category
       or new.level is distinct from old.level
       or new.target_type is distinct from old.target_type
       or new.note is distinct from old.note
       or new.due_date is distinct from old.due_date
       then
      raise exception 'Students may only update assignment status and timestamps';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_prevent_student_assignment_reassignment on public.assignments;
create trigger trg_prevent_student_assignment_reassignment
before update on public.assignments
for each row execute function public.prevent_student_assignment_reassignment();

revoke execute on function public.prevent_student_assignment_reassignment() from public, anon, authenticated;
grant execute on function public.prevent_student_assignment_reassignment() to postgres, service_role;
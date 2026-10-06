-- Prevent organization members from creating new legacy/unscoped teacher-student links.
-- Existing NULL organization_id rows remain temporarily readable during explicit migration.
drop policy if exists teacher_students_insert_teacher on public.teacher_students;

create policy teacher_students_insert_teacher
on public.teacher_students
for insert
to authenticated
with check (
  teacher_id = (select auth.uid())
  and exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'teacher'
  )
  and (
    (
      organization_id is null
      and not exists (
        select 1 from public.organization_members om
        where om.user_id = (select auth.uid())
      )
    )
    or (
      organization_id is not null
      and exists (
        select 1 from public.organization_members tm
        where tm.organization_id = teacher_students.organization_id
          and tm.user_id = (select auth.uid())
          and tm.role = any (array['owner'::text,'admin'::text,'teacher'::text])
      )
      and exists (
        select 1 from public.organization_members sm
        where sm.organization_id = teacher_students.organization_id
          and sm.user_id = teacher_students.student_id
          and sm.role = 'student'
      )
    )
  )
);

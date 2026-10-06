drop policy if exists assignments_insert_staff on public.assignments;
create policy assignments_insert_staff on public.assignments for insert to authenticated
with check (
 teacher_id=(select auth.uid())
 and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='teacher')
 and (
   (organization_id is null and class_id is null and student_id is not null and exists(select 1 from public.teacher_students ts where ts.teacher_id=(select auth.uid()) and ts.student_id=assignments.student_id and ts.organization_id is null and ts.status='active'))
   or
   (organization_id is not null and exists(select 1 from public.organization_members om where om.organization_id=assignments.organization_id and om.user_id=(select auth.uid()) and om.role='teacher')
    and (student_id is null or exists(select 1 from public.organization_members sm where sm.organization_id=assignments.organization_id and sm.user_id=assignments.student_id and sm.role='student'))
    and (class_id is null or exists(select 1 from public.classes c where c.id=assignments.class_id and c.organization_id=assignments.organization_id and c.teacher_id=(select auth.uid()))))
 )
);

drop policy if exists assignments_read_staff on public.assignments;
create policy assignments_read_staff on public.assignments for select to authenticated
using (teacher_id=(select auth.uid()) or (organization_id is not null and exists(select 1 from public.organization_members om where om.organization_id=assignments.organization_id and om.user_id=(select auth.uid()) and om.role in ('owner','admin'))));

drop policy if exists assignments_update_staff on public.assignments;
create policy assignments_update_staff on public.assignments for update to authenticated
using (teacher_id=(select auth.uid()) or (organization_id is not null and exists(select 1 from public.organization_members om where om.organization_id=assignments.organization_id and om.user_id=(select auth.uid()) and om.role in ('owner','admin'))))
with check (
 (teacher_id=(select auth.uid()) or (organization_id is not null and exists(select 1 from public.organization_members om where om.organization_id=assignments.organization_id and om.user_id=(select auth.uid()) and om.role in ('owner','admin'))))
 and (organization_id is null or exists(select 1 from public.organization_members tm where tm.organization_id=assignments.organization_id and tm.user_id=assignments.teacher_id and tm.role='teacher'))
 and (class_id is null or exists(select 1 from public.classes c where c.id=assignments.class_id and c.organization_id=assignments.organization_id and c.teacher_id=assignments.teacher_id))
);

drop policy if exists assignments_update_student_status on public.assignments;
create policy assignments_update_student_status on public.assignments for update to authenticated
using (student_id=(select auth.uid()))
with check (
 student_id=(select auth.uid()) and teacher_id is not null
 and ((organization_id is null and class_id is null)
 or (organization_id is not null
   and exists(select 1 from public.organization_members sm where sm.organization_id=assignments.organization_id and sm.user_id=(select auth.uid()) and sm.role='student')
   and (class_id is null or exists(select 1 from public.classes c where c.id=assignments.class_id and c.organization_id=assignments.organization_id and c.teacher_id=assignments.teacher_id))))
);
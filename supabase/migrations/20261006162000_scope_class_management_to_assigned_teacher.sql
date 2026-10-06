drop policy if exists classes_update_org_staff on public.classes;
create policy classes_update_org_staff on public.classes for update to authenticated
using (private.is_org_member(classes.organization_id) and exists(select 1 from public.organization_members om where om.organization_id=classes.organization_id and om.user_id=(select auth.uid()) and (om.role in ('owner','admin') or (om.role='teacher' and classes.teacher_id=(select auth.uid())))))
with check (private.is_org_member(classes.organization_id) and exists(select 1 from public.organization_members om where om.organization_id=classes.organization_id and om.user_id=(select auth.uid()) and (om.role in ('owner','admin') or (om.role='teacher' and classes.teacher_id=(select auth.uid())))));

drop policy if exists classes_delete_org_staff on public.classes;
create policy classes_delete_org_staff on public.classes for delete to authenticated
using (private.is_org_member(classes.organization_id) and exists(select 1 from public.organization_members om where om.organization_id=classes.organization_id and om.user_id=(select auth.uid()) and (om.role in ('owner','admin') or (om.role='teacher' and classes.teacher_id=(select auth.uid())))));

drop policy if exists class_students_insert_org_staff on public.class_students;
create policy class_students_insert_org_staff on public.class_students for insert to authenticated
with check (
 exists(select 1 from public.classes c join public.organization_members actor on actor.organization_id=c.organization_id and actor.user_id=(select auth.uid()) where c.id=class_students.class_id and (actor.role in ('owner','admin') or (actor.role='teacher' and c.teacher_id=(select auth.uid()))))
 and exists(select 1 from public.organization_members target where target.organization_id=(select c.organization_id from public.classes c where c.id=class_students.class_id) and target.user_id=class_students.student_id and target.role='student')
);

drop policy if exists class_students_update_org_staff on public.class_students;
create policy class_students_update_org_staff on public.class_students for update to authenticated
using (exists(select 1 from public.classes c join public.organization_members actor on actor.organization_id=c.organization_id and actor.user_id=(select auth.uid()) where c.id=class_students.class_id and (actor.role in ('owner','admin') or (actor.role='teacher' and c.teacher_id=(select auth.uid())))))
with check (exists(select 1 from public.classes c join public.organization_members actor on actor.organization_id=c.organization_id and actor.user_id=(select auth.uid()) where c.id=class_students.class_id and (actor.role in ('owner','admin') or (actor.role='teacher' and c.teacher_id=(select auth.uid())))));

drop policy if exists class_students_delete_org_staff on public.class_students;
create policy class_students_delete_org_staff on public.class_students for delete to authenticated
using (exists(select 1 from public.classes c join public.organization_members actor on actor.organization_id=c.organization_id and actor.user_id=(select auth.uid()) where c.id=class_students.class_id and (actor.role in ('owner','admin') or (actor.role='teacher' and c.teacher_id=(select auth.uid())))));
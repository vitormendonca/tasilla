-- Keep teacher access to private submission files aligned with the
-- organization-aware teacher/student relationship.
-- Unmapped legacy relationships remain readable during the transition.
drop policy if exists submissions_read_linked_students on storage.objects;

create policy submissions_read_linked_students on storage.objects
for select to authenticated
using (
  bucket_id = 'submissions'
  and exists (
    select 1
    from public.teacher_students ts
    where ts.teacher_id = (select auth.uid())
      and ts.student_id::text = (storage.foldername(objects.name))[1]
      and ts.status = 'active'
      and (
        ts.organization_id is null
        or exists (
          select 1
          from public.organization_members tm
          join public.organization_members sm
            on sm.organization_id = tm.organization_id
          where tm.organization_id = ts.organization_id
            and tm.user_id = (select auth.uid())
            and tm.role in ('owner', 'admin', 'teacher')
            and sm.user_id = ts.student_id
            and sm.role = 'student'
        )
      )
  )
);

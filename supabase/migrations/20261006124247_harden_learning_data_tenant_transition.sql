-- Transition legacy teacher/student authorization to organization-aware checks.
-- Unmapped legacy relationships remain readable during migration; mapped relationships
-- additionally require teacher/staff and student membership in the same organization.

drop policy if exists attempts_read_teacher on public.attempts;
create policy attempts_read_teacher on public.attempts for select to authenticated using (
  exists (select 1 from public.teacher_students ts
    where ts.teacher_id = auth.uid() and ts.student_id = attempts.student_id and ts.status = 'active'
      and (ts.organization_id is null or exists (
        select 1 from public.organization_members tm
        join public.organization_members sm on sm.organization_id = tm.organization_id
        where tm.organization_id = ts.organization_id and tm.user_id = auth.uid()
          and tm.role in ('owner','admin','teacher')
          and sm.user_id = attempts.student_id and sm.role = 'student'
      )))
);

drop policy if exists student_step_progress_read_teacher on public.student_step_progress;
create policy student_step_progress_read_teacher on public.student_step_progress for select to authenticated using (
  exists (select 1 from public.teacher_students ts
    where ts.teacher_id = auth.uid() and ts.student_id = student_step_progress.student_id and ts.status = 'active'
      and (ts.organization_id is null or exists (
        select 1 from public.organization_members tm
        join public.organization_members sm on sm.organization_id = tm.organization_id
        where tm.organization_id = ts.organization_id and tm.user_id = auth.uid()
          and tm.role in ('owner','admin','teacher')
          and sm.user_id = student_step_progress.student_id and sm.role = 'student'
      )))
);

drop policy if exists student_submissions_read_teacher on public.student_submissions;
create policy student_submissions_read_teacher on public.student_submissions for select to authenticated using (
  exists (select 1 from public.teacher_students ts
    where ts.teacher_id = auth.uid() and ts.student_id = student_submissions.student_id and ts.status = 'active'
      and (ts.organization_id is null or exists (
        select 1 from public.organization_members tm
        join public.organization_members sm on sm.organization_id = tm.organization_id
        where tm.organization_id = ts.organization_id and tm.user_id = auth.uid()
          and tm.role in ('owner','admin','teacher')
          and sm.user_id = student_submissions.student_id and sm.role = 'student'
      )))
);

drop policy if exists student_submissions_update_teacher on public.student_submissions;
create policy student_submissions_update_teacher on public.student_submissions for update to authenticated
using (
  exists (select 1 from public.teacher_students ts
    where ts.teacher_id = auth.uid() and ts.student_id = student_submissions.student_id and ts.status = 'active'
      and (ts.organization_id is null or exists (
        select 1 from public.organization_members tm
        join public.organization_members sm on sm.organization_id = tm.organization_id
        where tm.organization_id = ts.organization_id and tm.user_id = auth.uid()
          and tm.role in ('owner','admin','teacher')
          and sm.user_id = student_submissions.student_id and sm.role = 'student'
      )))
)
with check (
  exists (select 1 from public.teacher_students ts
    where ts.teacher_id = auth.uid() and ts.student_id = student_submissions.student_id and ts.status = 'active'
      and (ts.organization_id is null or exists (
        select 1 from public.organization_members tm
        join public.organization_members sm on sm.organization_id = tm.organization_id
        where tm.organization_id = ts.organization_id and tm.user_id = auth.uid()
          and tm.role in ('owner','admin','teacher')
          and sm.user_id = student_submissions.student_id and sm.role = 'student'
      )))
);

drop policy if exists certificates_insert_teacher on public.certificates;
create policy certificates_insert_teacher on public.certificates for insert to authenticated with check (
  issued_by = auth.uid()
  and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'teacher')
  and exists (select 1 from public.teacher_students ts
    where ts.teacher_id = auth.uid() and ts.student_id = certificates.student_id and ts.status = 'active'
      and (ts.organization_id is null or exists (
        select 1 from public.organization_members tm
        join public.organization_members sm on sm.organization_id = tm.organization_id
        where tm.organization_id = ts.organization_id and tm.user_id = auth.uid()
          and tm.role in ('owner','admin','teacher')
          and sm.user_id = certificates.student_id and sm.role = 'student'
      )))
);

drop policy if exists certificates_read_teacher on public.certificates;
create policy certificates_read_teacher on public.certificates for select to authenticated using (
  issued_by = auth.uid() or exists (select 1 from public.teacher_students ts
    where ts.teacher_id = auth.uid() and ts.student_id = certificates.student_id and ts.status = 'active'
      and (ts.organization_id is null or exists (
        select 1 from public.organization_members tm
        join public.organization_members sm on sm.organization_id = tm.organization_id
        where tm.organization_id = ts.organization_id and tm.user_id = auth.uid()
          and tm.role in ('owner','admin','teacher')
          and sm.user_id = certificates.student_id and sm.role = 'student'
      )))
);

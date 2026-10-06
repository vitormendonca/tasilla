alter table public.certificates add column if not exists organization_id uuid references public.organizations(id) on delete cascade;
create index if not exists certificates_organization_id_idx on public.certificates(organization_id);

drop policy if exists certificates_insert_teacher on public.certificates;
create policy certificates_insert_teacher on public.certificates
for insert to authenticated
with check (
  issued_by = (select auth.uid())
  and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'teacher')
  and organization_id is not null
  and exists (
    select 1 from public.teacher_students ts
    where ts.teacher_id = (select auth.uid())
      and ts.student_id = certificates.student_id
      and ts.status = 'active'
      and ts.organization_id = certificates.organization_id
      and exists (select 1 from public.organization_members tm where tm.organization_id = certificates.organization_id and tm.user_id = (select auth.uid()) and tm.role in ('owner','admin','teacher'))
      and exists (select 1 from public.organization_members sm where sm.organization_id = certificates.organization_id and sm.user_id = certificates.student_id and sm.role = 'student')
  )
);

drop policy if exists certificates_read_teacher on public.certificates;
create policy certificates_read_teacher on public.certificates
for select to authenticated
using (
  issued_by = (select auth.uid())
  or (
    organization_id is not null
    and exists (select 1 from public.organization_members tm where tm.organization_id = certificates.organization_id and tm.user_id = (select auth.uid()) and tm.role in ('owner','admin','teacher'))
    and exists (select 1 from public.organization_members sm where sm.organization_id = certificates.organization_id and sm.user_id = certificates.student_id and sm.role = 'student')
  )
);

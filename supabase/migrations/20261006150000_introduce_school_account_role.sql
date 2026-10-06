alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check check (role in ('school','teacher','student'));

drop policy if exists organizations_insert_teacher_owner on public.organizations;
drop policy if exists organizations_insert_school_owner on public.organizations;
create policy organizations_insert_school_owner
on public.organizations for insert to authenticated
with check (
  owner_id = (select auth.uid())
  and exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'school'
  )
);

drop policy if exists organizations_update_owner on public.organizations;
create policy organizations_update_owner
on public.organizations for update to authenticated
using ((select private.is_org_owner(id)))
with check (
  owner_id = (select auth.uid())
  and exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'school'
  )
);

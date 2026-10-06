create table public.account_entitlements (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.profiles(id) on delete cascade,
  account_type text not null check (account_type in ('school','teacher')),
  plan_code text not null default 'pilot',
  max_teachers integer check (max_teachers is null or max_teachers >= 0),
  max_students integer check (max_students is null or max_students >= 0),
  status text not null default 'active' check (status in ('active','trialing','past_due','canceled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(account_id)
);

alter table public.account_entitlements enable row level security;
revoke all on public.account_entitlements from anon, authenticated;
grant select on public.account_entitlements to authenticated;
create policy account_entitlements_select_own on public.account_entitlements
for select to authenticated using (account_id = (select auth.uid()));

create table public.teacher_invitations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  invited_email text not null,
  invited_by uuid not null references public.profiles(id) on delete restrict,
  status text not null default 'pending' check (status in ('pending','accepted','revoked','expired')),
  created_at timestamptz not null default now(),
  accepted_at timestamptz,
  constraint teacher_invitations_email_nonempty check (length(trim(invited_email)) >= 3)
);
create unique index teacher_invitations_pending_email_per_org
on public.teacher_invitations(organization_id, lower(invited_email))
where status='pending';

alter table public.teacher_invitations enable row level security;
revoke all on public.teacher_invitations from anon, authenticated;
grant select, insert, update on public.teacher_invitations to authenticated;
create policy teacher_invitations_select_school_owner on public.teacher_invitations
for select to authenticated using ((select private.is_org_owner(organization_id)));
create policy teacher_invitations_insert_school_owner on public.teacher_invitations
for insert to authenticated with check (
  invited_by=(select auth.uid())
  and (select private.is_org_owner(organization_id))
  and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='school')
);
create policy teacher_invitations_update_school_owner on public.teacher_invitations
for update to authenticated
using ((select private.is_org_owner(organization_id)))
with check ((select private.is_org_owner(organization_id)));

create or replace function public.ensure_default_entitlement()
returns public.account_entitlements language plpgsql security invoker set search_path=''
as $$
declare v_role text; v_row public.account_entitlements;
begin
 select role into v_role from public.profiles where id=(select auth.uid());
 if v_role not in ('school','teacher') then raise exception 'Paid account role required'; end if;
 insert into public.account_entitlements(account_id,account_type,plan_code,max_teachers,max_students)
 values ((select auth.uid()),v_role,'pilot',case when v_role='school' then 3 else null end,case when v_role='teacher' then 10 else 50 end)
 on conflict(account_id) do nothing;
 select * into v_row from public.account_entitlements where account_id=(select auth.uid());
 return v_row;
end $$;
revoke execute on function public.ensure_default_entitlement() from public,anon;
grant execute on function public.ensure_default_entitlement() to authenticated;

create or replace function public.invite_teacher(target_organization_id uuid, teacher_email text)
returns public.teacher_invitations language plpgsql security invoker set search_path=''
as $$
declare v_limit integer; v_used integer; v_row public.teacher_invitations;
begin
 if not (select private.is_org_owner(target_organization_id)) then raise exception 'School ownership required'; end if;
 if not exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='school') then raise exception 'School account required'; end if;
 select max_teachers into v_limit from public.account_entitlements where account_id=(select auth.uid()) and status in ('active','trialing');
 if v_limit is null then raise exception 'Active School entitlement required'; end if;
 select count(*) into v_used from public.organization_members where organization_id=target_organization_id and role='teacher';
 v_used := v_used + (select count(*) from public.teacher_invitations where organization_id=target_organization_id and status='pending');
 if v_used >= v_limit then raise exception 'Teacher plan limit reached'; end if;
 insert into public.teacher_invitations(organization_id,invited_email,invited_by)
 values(target_organization_id,lower(trim(teacher_email)),(select auth.uid())) returning * into v_row;
 return v_row;
end $$;
revoke execute on function public.invite_teacher(uuid,text) from public,anon;
grant execute on function public.invite_teacher(uuid,text) to authenticated;

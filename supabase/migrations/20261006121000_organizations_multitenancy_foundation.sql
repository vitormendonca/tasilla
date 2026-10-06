create schema if not exists private;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete restrict,
  name text not null,
  slug text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint organizations_name_nonempty check (length(trim(name)) between 2 and 160),
  constraint organizations_slug_format check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  constraint organizations_slug_unique unique (slug)
);

create table if not exists public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint organization_members_role_check check (role in ('owner','admin','teacher','student')),
  constraint organization_members_unique unique (organization_id, user_id)
);

create index if not exists idx_organizations_owner on public.organizations(owner_id);
create index if not exists idx_org_members_user on public.organization_members(user_id);
create index if not exists idx_org_members_org_role on public.organization_members(organization_id, role);

create or replace function private.is_org_member(target_org_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.organization_members om
    where om.organization_id = target_org_id and om.user_id = (select auth.uid())
  );
$$;

create or replace function private.is_org_owner(target_org_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.organizations o
    where o.id = target_org_id and o.owner_id = (select auth.uid())
  );
$$;

revoke execute on function private.is_org_member(uuid), private.is_org_owner(uuid) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.is_org_member(uuid), private.is_org_owner(uuid) to authenticated;

alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;

revoke all on table public.organizations, public.organization_members from anon, authenticated;
grant select, insert, update, delete on table public.organizations, public.organization_members to authenticated;

create policy organizations_select_members on public.organizations for select to authenticated using ((select private.is_org_member(id)));
create policy organizations_insert_teacher_owner on public.organizations for insert to authenticated with check (
  owner_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'teacher'
  )
);
create policy organizations_update_owner on public.organizations for update to authenticated
using ((select private.is_org_owner(id)))
with check (
  owner_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'teacher'
  )
);
create policy organizations_delete_owner on public.organizations for delete to authenticated using ((select private.is_org_owner(id)));

create policy organization_members_select_member on public.organization_members for select to authenticated using ((select private.is_org_member(organization_id)));
create policy organization_members_insert_owner on public.organization_members for insert to authenticated with check (
  (select private.is_org_owner(organization_id)) and (user_id <> (select auth.uid()) or role = 'owner')
);
create policy organization_members_update_owner on public.organization_members for update to authenticated
using ((select private.is_org_owner(organization_id)) and not (user_id = (select auth.uid()) and role = 'owner'))
with check ((select private.is_org_owner(organization_id)) and role <> 'owner');
create policy organization_members_delete_owner on public.organization_members for delete to authenticated
using ((select private.is_org_owner(organization_id)) and user_id <> (select auth.uid()));
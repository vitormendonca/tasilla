alter table public.profiles add column if not exists email_normalized text;
update public.profiles p set email_normalized=lower(trim(u.email)) from auth.users u where u.id=p.id and u.email is not null and p.email_normalized is null;
create unique index if not exists profiles_email_normalized_unique on public.profiles(email_normalized) where email_normalized is not null;
drop function if exists public.accept_teacher_invitation(uuid);
drop function if exists public.list_my_teacher_invitations();
create or replace function public.accept_teacher_invitation(invitation_id uuid)
returns public.organization_members language plpgsql security invoker set search_path=''
as $$
declare v_inv public.teacher_invitations; v_email text; v_member public.organization_members;
begin
 select email_normalized into v_email from public.profiles where id=(select auth.uid()) and role='teacher';
 if v_email is null then raise exception 'Teacher email unavailable'; end if;
 select * into v_inv from public.teacher_invitations where id=invitation_id and status='pending' and lower(trim(invited_email))=v_email;
 if v_inv.id is null then raise exception 'Pending invitation not found'; end if;
 insert into public.organization_members(organization_id,user_id,role) values(v_inv.organization_id,(select auth.uid()),'teacher')
 on conflict(organization_id,user_id) do update set role='teacher' returning * into v_member;
 update public.teacher_invitations set status='accepted',accepted_at=now() where id=v_inv.id;
 return v_member;
end $$;
revoke execute on function public.accept_teacher_invitation(uuid) from public,anon;
grant execute on function public.accept_teacher_invitation(uuid) to authenticated;
create policy teacher_invitations_select_invited_teacher on public.teacher_invitations for select to authenticated using (
 status='pending' and lower(trim(invited_email))=(select p.email_normalized from public.profiles p where p.id=(select auth.uid()) and p.role='teacher'));
create policy teacher_invitations_update_invited_teacher on public.teacher_invitations for update to authenticated
using (status='pending' and lower(trim(invited_email))=(select p.email_normalized from public.profiles p where p.id=(select auth.uid()) and p.role='teacher'))
with check (lower(trim(invited_email))=(select p.email_normalized from public.profiles p where p.id=(select auth.uid()) and p.role='teacher'));

create or replace function private.current_auth_email()
returns text language sql security definer set search_path=''
as $$
 select lower(trim(u.email)) from auth.users u where u.id=(select auth.uid());
$$;
revoke all on function private.current_auth_email() from public,anon,authenticated;
grant usage on schema private to authenticated;
grant execute on function private.current_auth_email() to authenticated;

create or replace function private.accept_teacher_invitation(invitation_id uuid)
returns boolean language plpgsql security definer set search_path=''
as $$
declare v_actor uuid := (select auth.uid()); v_inv public.teacher_invitations; v_email text;
begin
 if v_actor is null then raise exception 'Authentication required'; end if;
 if not exists(select 1 from public.profiles where id=v_actor and role='teacher') then raise exception 'Teacher account required'; end if;
 select lower(trim(u.email)) into v_email from auth.users u where u.id=v_actor;
 if v_email is null then raise exception 'Teacher email unavailable'; end if;
 select * into v_inv from public.teacher_invitations where id=invitation_id and status='pending' and lower(trim(invited_email))=v_email for update;
 if v_inv.id is null then raise exception 'Pending invitation not found'; end if;
 insert into public.organization_members(organization_id,user_id,role) values(v_inv.organization_id,v_actor,'teacher')
 on conflict(organization_id,user_id) do update set role='teacher';
 update public.teacher_invitations set status='accepted',accepted_at=now() where id=v_inv.id;
 return true;
end $$;
revoke all on function private.accept_teacher_invitation(uuid) from public,anon,authenticated;
grant execute on function private.accept_teacher_invitation(uuid) to authenticated;
drop function if exists private.accept_teacher_invitation(uuid,uuid);

create or replace function public.accept_teacher_invitation(invitation_id uuid)
returns boolean language sql security invoker set search_path=''
as $$ select private.accept_teacher_invitation(invitation_id); $$;
revoke execute on function public.accept_teacher_invitation(uuid) from public,anon;
grant execute on function public.accept_teacher_invitation(uuid) to authenticated;

drop policy if exists teacher_invitations_select_invited_teacher on public.teacher_invitations;
create policy teacher_invitations_select_invited_teacher on public.teacher_invitations for select to authenticated
using (
 status='pending'
 and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='teacher')
 and lower(trim(invited_email))=private.current_auth_email()
);
drop policy if exists teacher_invitations_update_invited_teacher on public.teacher_invitations;
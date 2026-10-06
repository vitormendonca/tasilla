drop policy if exists organization_members_insert_invited_teacher on public.organization_members;
drop function if exists private.has_pending_teacher_invitation(uuid,uuid);

create or replace function private.accept_teacher_invitation(invitation_id uuid, actor_id uuid)
returns boolean language plpgsql security definer set search_path=''
as $$
declare v_inv public.teacher_invitations; v_email text;
begin
 if actor_id is null or actor_id <> (select auth.uid()) then raise exception 'Authentication mismatch'; end if;
 select email_normalized into v_email from public.profiles where id=actor_id and role='teacher';
 if v_email is null then raise exception 'Teacher email unavailable'; end if;
 select * into v_inv from public.teacher_invitations where id=invitation_id and status='pending' and lower(trim(invited_email))=v_email for update;
 if v_inv.id is null then raise exception 'Pending invitation not found'; end if;
 insert into public.organization_members(organization_id,user_id,role) values(v_inv.organization_id,actor_id,'teacher')
 on conflict(organization_id,user_id) do update set role='teacher';
 update public.teacher_invitations set status='accepted',accepted_at=now() where id=v_inv.id;
 return true;
end $$;
revoke all on function private.accept_teacher_invitation(uuid,uuid) from public,anon,authenticated;
grant usage on schema private to authenticated;
grant execute on function private.accept_teacher_invitation(uuid,uuid) to authenticated;

create or replace function public.accept_teacher_invitation(invitation_id uuid)
returns boolean language sql security invoker set search_path=''
as $$ select private.accept_teacher_invitation(invitation_id,(select auth.uid())); $$;
revoke execute on function public.accept_teacher_invitation(uuid) from public,anon;
grant execute on function public.accept_teacher_invitation(uuid) to authenticated;

create or replace function private.school_student_limit(target_organization_id uuid)
returns integer language sql security definer set search_path=''
as $$
 select ae.max_students from public.organizations o join public.account_entitlements ae on ae.account_id=o.owner_id
 where o.id=target_organization_id and ae.status in ('active','trialing') limit 1;
$$;
revoke all on function private.school_student_limit(uuid) from public,anon,authenticated;
grant execute on function private.school_student_limit(uuid) to authenticated;

create or replace function public.link_student_by_access_code(student_access_code text, target_organization_id uuid default null)
returns public.teacher_students language plpgsql security invoker set search_path=''
as $$
declare v_teacher uuid := (select auth.uid()); v_student uuid; v_limit integer; v_used integer; v_row public.teacher_students;
begin
 if v_teacher is null then raise exception 'Authentication required'; end if;
 if not exists(select 1 from public.profiles where id=v_teacher and role='teacher') then raise exception 'Teacher account required'; end if;
 if length(trim(student_access_code)) < 4 then raise exception 'Invalid student access code'; end if;
 v_student := private.resolve_student_by_access_code(student_access_code);
 if v_student is null then raise exception 'Student not found'; end if;
 if target_organization_id is null then
   if exists(select 1 from public.organization_members where user_id=v_teacher) then raise exception 'Organization teacher must select an organization'; end if;
   select max_students into v_limit from public.account_entitlements where account_id=v_teacher and status in ('active','trialing');
   if v_limit is null then raise exception 'Active Teacher entitlement required'; end if;
   select count(*) into v_used from public.teacher_students where teacher_id=v_teacher and status='active' and organization_id is null;
 else
   if not exists(select 1 from public.organization_members where organization_id=target_organization_id and user_id=v_teacher and role in ('teacher','admin','owner')) then raise exception 'Organization membership required'; end if;
   if not exists(select 1 from public.organization_members where organization_id=target_organization_id and user_id=v_student and role='student') then raise exception 'Student must belong to organization'; end if;
   v_limit := private.school_student_limit(target_organization_id);
   if v_limit is null then raise exception 'Active School entitlement required'; end if;
   select count(distinct student_id) into v_used from public.teacher_students where organization_id=target_organization_id and status='active';
 end if;
 if v_used >= v_limit and not exists(select 1 from public.teacher_students where teacher_id=v_teacher and student_id=v_student and status='active') then raise exception 'Student plan limit reached'; end if;
 insert into public.teacher_students(teacher_id,student_id,status,organization_id) values(v_teacher,v_student,'active',target_organization_id)
 on conflict(teacher_id,student_id) do update set status='active',organization_id=excluded.organization_id returning * into v_row;
 return v_row;
end $$;
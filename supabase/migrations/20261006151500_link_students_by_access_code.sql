create or replace function private.resolve_student_by_access_code(student_access_code text)
returns uuid language sql security definer set search_path=''
as $$
  select p.id from public.profiles p where p.role='student' and p.access_code=upper(trim(student_access_code)) limit 1;
$$;
revoke all on function private.resolve_student_by_access_code(text) from public,anon,authenticated;
grant usage on schema private to authenticated;
grant execute on function private.resolve_student_by_access_code(text) to authenticated,postgres,service_role;

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
   select ae.max_students into v_limit from public.organizations o join public.account_entitlements ae on ae.account_id=o.owner_id where o.id=target_organization_id and ae.status in ('active','trialing');
   if v_limit is null then raise exception 'Active School entitlement required'; end if;
   select count(distinct student_id) into v_used from public.teacher_students where organization_id=target_organization_id and status='active';
 end if;
 if v_used >= v_limit and not exists(select 1 from public.teacher_students where teacher_id=v_teacher and student_id=v_student and status='active') then raise exception 'Student plan limit reached'; end if;
 insert into public.teacher_students(teacher_id,student_id,status,organization_id) values(v_teacher,v_student,'active',target_organization_id)
 on conflict(teacher_id,student_id) do update set status='active',organization_id=excluded.organization_id returning * into v_row;
 return v_row;
end $$;
revoke execute on function public.link_student_by_access_code(text,uuid) from public,anon;
grant execute on function public.link_student_by_access_code(text,uuid) to authenticated;

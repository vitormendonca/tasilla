create or replace function public.link_student_to_teacher(target_student_id uuid, target_organization_id uuid default null)
returns public.teacher_students language plpgsql security invoker set search_path=''
as $$
declare v_limit integer; v_used integer; v_row public.teacher_students;
begin
 if not exists(select 1 from public.profiles where id=(select auth.uid()) and role='teacher') then raise exception 'Teacher account required'; end if;
 if not exists(select 1 from public.profiles where id=target_student_id and role='student') then raise exception 'Student account required'; end if;
 if target_organization_id is null then
   if exists(select 1 from public.organization_members where user_id=(select auth.uid())) then raise exception 'Organization teacher must select an organization'; end if;
   select max_students into v_limit from public.account_entitlements where account_id=(select auth.uid()) and status in ('active','trialing');
   if v_limit is null then raise exception 'Active Teacher entitlement required'; end if;
   select count(*) into v_used from public.teacher_students where teacher_id=(select auth.uid()) and status='active' and organization_id is null;
 else
   if not exists(select 1 from public.organization_members where organization_id=target_organization_id and user_id=(select auth.uid()) and role in ('teacher','admin','owner')) then raise exception 'Organization membership required'; end if;
   if not exists(select 1 from public.organization_members where organization_id=target_organization_id and user_id=target_student_id and role='student') then raise exception 'Student must belong to organization'; end if;
   select ae.max_students into v_limit from public.organizations o join public.account_entitlements ae on ae.account_id=o.owner_id where o.id=target_organization_id and ae.status in ('active','trialing');
   if v_limit is null then raise exception 'Active School entitlement required'; end if;
   select count(distinct student_id) into v_used from public.teacher_students where organization_id=target_organization_id and status='active';
 end if;
 if v_used >= v_limit and not exists(select 1 from public.teacher_students where teacher_id=(select auth.uid()) and student_id=target_student_id and status='active') then raise exception 'Student plan limit reached'; end if;
 insert into public.teacher_students(teacher_id,student_id,status,organization_id) values((select auth.uid()),target_student_id,'active',target_organization_id)
 on conflict(teacher_id,student_id) do update set status='active',organization_id=excluded.organization_id returning * into v_row;
 return v_row;
end $$;
revoke execute on function public.link_student_to_teacher(uuid,uuid) from public,anon;
grant execute on function public.link_student_to_teacher(uuid,uuid) to authenticated;

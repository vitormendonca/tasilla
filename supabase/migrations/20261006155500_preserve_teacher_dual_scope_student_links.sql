alter table public.teacher_students drop constraint if exists teacher_students_teacher_id_student_id_key;
create unique index if not exists teacher_students_independent_pair_key on public.teacher_students(teacher_id,student_id) where organization_id is null;
create unique index if not exists teacher_students_school_pair_key on public.teacher_students(teacher_id,student_id,organization_id) where organization_id is not null;

drop policy if exists teacher_students_insert_teacher on public.teacher_students;
create policy teacher_students_insert_teacher on public.teacher_students for insert to authenticated
with check (
 teacher_id=(select auth.uid())
 and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='teacher')
 and (
   organization_id is null
   or (
     organization_id is not null
     and exists(select 1 from public.organization_members tm where tm.organization_id=teacher_students.organization_id and tm.user_id=(select auth.uid()) and tm.role in ('owner','admin','teacher'))
     and exists(select 1 from public.organization_members sm where sm.organization_id=teacher_students.organization_id and sm.user_id=teacher_students.student_id and sm.role='student')
   )
 )
);

create or replace function public.link_student_by_access_code(student_access_code text,target_organization_id uuid default null)
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
   select max_students into v_limit from public.account_entitlements where account_id=v_teacher and status in ('active','trialing');
   if v_limit is null then raise exception 'Active Teacher entitlement required'; end if;
   select count(*) into v_used from public.teacher_students where teacher_id=v_teacher and status='active' and organization_id is null;
   if v_used >= v_limit and not exists(select 1 from public.teacher_students where teacher_id=v_teacher and student_id=v_student and status='active' and organization_id is null) then raise exception 'Student plan limit reached'; end if;
   insert into public.teacher_students(teacher_id,student_id,status,organization_id) values(v_teacher,v_student,'active',null)
   on conflict(teacher_id,student_id) where organization_id is null do update set status='active' returning * into v_row;
 else
   if not exists(select 1 from public.organization_members where organization_id=target_organization_id and user_id=v_teacher and role in ('teacher','admin','owner')) then raise exception 'Organization membership required'; end if;
   if not exists(select 1 from public.organization_members where organization_id=target_organization_id and user_id=v_student and role='student') then raise exception 'Student must belong to organization'; end if;
   v_limit := private.school_student_limit(target_organization_id);
   if v_limit is null then raise exception 'Active School entitlement required'; end if;
   select count(distinct student_id) into v_used from public.teacher_students where organization_id=target_organization_id and status='active';
   if v_used >= v_limit and not exists(select 1 from public.teacher_students where teacher_id=v_teacher and student_id=v_student and status='active' and organization_id=target_organization_id) then raise exception 'Student plan limit reached'; end if;
   insert into public.teacher_students(teacher_id,student_id,status,organization_id) values(v_teacher,v_student,'active',target_organization_id)
   on conflict(teacher_id,student_id,organization_id) where organization_id is not null do update set status='active' returning * into v_row;
 end if;
 return v_row;
end $$;
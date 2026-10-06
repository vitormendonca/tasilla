create or replace function private.is_school_teacher(target_organization_id uuid,target_teacher_id uuid)
returns boolean language sql security definer set search_path=''
as $$
 select exists(select 1 from public.organization_members om join public.profiles p on p.id=om.user_id
 where om.organization_id=target_organization_id and om.user_id=target_teacher_id and om.role='teacher' and p.role='teacher');
$$;
revoke all on function private.is_school_teacher(uuid,uuid) from public,anon,authenticated;
grant usage on schema private to authenticated;
grant execute on function private.is_school_teacher(uuid,uuid) to authenticated;

create or replace function public.create_school_class(target_organization_id uuid,target_teacher_id uuid,class_name text,class_level text default 'A1')
returns public.classes language plpgsql security invoker set search_path=''
as $$
declare v_class public.classes;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if length(trim(class_name)) < 2 or length(trim(class_name)) > 160 then raise exception 'Invalid class name'; end if;
 if class_level not in ('A1','A2','B1') then raise exception 'Invalid class level'; end if;
 if not exists(select 1 from public.organizations o where o.id=target_organization_id and o.owner_id=auth.uid()) then raise exception 'School ownership required'; end if;
 if not exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='school') then raise exception 'School account required'; end if;
 if not private.is_school_teacher(target_organization_id,target_teacher_id) then raise exception 'Teacher must belong to school'; end if;
 insert into public.classes(organization_id,teacher_id,name,level) values(target_organization_id,target_teacher_id,trim(class_name),class_level) returning * into v_class;
 return v_class;
end $$;
revoke execute on function public.create_school_class(uuid,uuid,text,text) from public,anon;
grant execute on function public.create_school_class(uuid,uuid,text,text) to authenticated;

drop policy if exists classes_insert_school_owner_for_teacher on public.classes;
create policy classes_insert_school_owner_for_teacher on public.classes for insert to authenticated
with check (
 exists(select 1 from public.organizations o where o.id=classes.organization_id and o.owner_id=(select auth.uid()))
 and exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='school')
 and private.is_school_teacher(classes.organization_id,classes.teacher_id)
);
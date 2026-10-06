create or replace function public.create_organization(organization_name text, organization_slug text)
returns public.organizations language plpgsql security invoker set search_path=''
as $$
declare new_org public.organizations;
begin
 if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
 if not exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='school') then raise exception 'School account required'; end if;
 insert into public.organizations(owner_id,name,slug) values((select auth.uid()),trim(organization_name),lower(trim(organization_slug))) returning * into new_org;
 insert into public.organization_members(organization_id,user_id,role) values(new_org.id,(select auth.uid()),'owner');
 return new_org;
end $$;

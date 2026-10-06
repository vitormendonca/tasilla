create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  teacher_id uuid not null references public.profiles(id) on delete restrict,
  name text not null,
  level text not null default 'A1',
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint classes_name_nonempty check (length(trim(name)) between 2 and 160),
  constraint classes_status_check check (status in ('active','archived')),
  constraint classes_unique_name_per_org unique (organization_id, name)
);

create table if not exists public.class_students (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'active',
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  constraint class_students_status_check check (status in ('active','inactive','removed')),
  constraint class_students_unique unique (class_id, student_id)
);

create index if not exists idx_classes_org on public.classes(organization_id);
create index if not exists idx_classes_teacher on public.classes(teacher_id);
create index if not exists idx_class_students_student on public.class_students(student_id);
create index if not exists idx_class_students_class on public.class_students(class_id);

alter table public.assignments
  add constraint assignments_class_id_fkey
  foreign key (class_id) references public.classes(id) on delete set null;

alter table public.classes enable row level security;
alter table public.class_students enable row level security;

revoke all on table public.classes, public.class_students from anon, authenticated;
grant select, insert, update, delete on table public.classes, public.class_students to authenticated;

create policy classes_select_org_member on public.classes for select to authenticated
using ((select private.is_org_member(organization_id)));

create policy classes_insert_org_staff on public.classes for insert to authenticated
with check (
  (select private.is_org_member(classes.organization_id))
  and classes.teacher_id = (select auth.uid())
  and exists (
    select 1 from public.organization_members om
    where om.organization_id = classes.organization_id
      and om.user_id = (select auth.uid())
      and om.role in ('owner','admin','teacher')
  )
);

create policy classes_update_org_staff on public.classes for update to authenticated
using (
  (select private.is_org_member(organization_id))
  and exists (
    select 1 from public.organization_members om
    where om.organization_id = classes.organization_id
      and om.user_id = (select auth.uid())
      and om.role in ('owner','admin','teacher')
  )
)
with check (
  (select private.is_org_member(organization_id))
  and teacher_id = (select auth.uid())
  and exists (
    select 1 from public.organization_members om
    where om.organization_id = classes.organization_id
      and om.user_id = (select auth.uid())
      and om.role in ('owner','admin','teacher')
  )
);

create policy classes_delete_org_staff on public.classes for delete to authenticated
using (
  (select private.is_org_member(organization_id))
  and exists (
    select 1 from public.organization_members om
    where om.organization_id = classes.organization_id
      and om.user_id = (select auth.uid())
      and om.role in ('owner','admin','teacher')
  )
);

create policy class_students_select_org_member on public.class_students for select to authenticated
using (
  exists (
    select 1 from public.classes c
    where c.id = class_students.class_id
      and (select private.is_org_member(c.organization_id))
  )
);

create policy class_students_insert_org_staff on public.class_students for insert to authenticated
with check (
  exists (
    select 1 from public.classes c
    where c.id = class_students.class_id
      and (select private.is_org_member(c.organization_id))
      and exists (
        select 1 from public.organization_members om
        where om.organization_id = c.organization_id
          and om.user_id = (select auth.uid())
          and om.role in ('owner','admin','teacher')
      )
  )
  and exists (
    select 1 from public.organization_members target
    where target.organization_id = (
      select c.organization_id from public.classes c where c.id = class_students.class_id
    )
      and target.user_id = class_students.student_id
      and target.role = 'student'
  )
);

create policy class_students_update_org_staff on public.class_students for update to authenticated
using (
  exists (
    select 1 from public.classes c
    where c.id = class_students.class_id
      and (select private.is_org_member(c.organization_id))
      and exists (
        select 1 from public.organization_members om
        where om.organization_id = c.organization_id
          and om.user_id = (select auth.uid())
          and om.role in ('owner','admin','teacher')
      )
  )
)
with check (
  exists (
    select 1 from public.classes c
    where c.id = class_students.class_id
      and (select private.is_org_member(c.organization_id))
  )
);

create policy class_students_delete_org_staff on public.class_students for delete to authenticated
using (
  exists (
    select 1 from public.classes c
    where c.id = class_students.class_id
      and (select private.is_org_member(c.organization_id))
      and exists (
        select 1 from public.organization_members om
        where om.organization_id = c.organization_id
          and om.user_id = (select auth.uid())
          and om.role in ('owner','admin','teacher')
      )
  )
);
-- Adds roadmap milestones for the guided A1 student path.

insert into public.skills (id, title, description, sort_order)
values (
  'a1_roadmap',
  'A1 Road Map',
  'Guided A1 path with cumulative reviews and final test.',
  0
)
on conflict (id) do update
set
  title = excluded.title,
  description = excluded.description,
  sort_order = excluded.sort_order;

with roadmap_review_rows as (
  select
    review_number,
    review_number * 7 as step_order,
    ((review_number - 1) * 6) + 1 as first_activity,
    review_number * 6 as last_activity
  from generate_series(1, 10) as numbers(review_number)
)
insert into public.learning_steps (
  id,
  level,
  skill_id,
  title,
  description,
  step_type,
  step_order,
  lesson_number,
  review_number
)
select
  'a1_roadmap_review_' || review_number,
  'A1',
  'a1_roadmap',
  'A1 Review ' || review_number,
  'Review road activities ' || first_activity || ' to ' || last_activity || '.',
  'review',
  step_order,
  null,
  review_number
from roadmap_review_rows
union all
select
  'a1_roadmap_final_test',
  'A1',
  'a1_roadmap',
  'A1 Final Test',
  'A stronger test covering the complete A1 road map.',
  'final_test',
  71,
  null,
  null
on conflict (id) do update
set
  title = excluded.title,
  description = excluded.description,
  step_type = excluded.step_type,
  step_order = excluded.step_order,
  lesson_number = excluded.lesson_number,
  review_number = excluded.review_number;

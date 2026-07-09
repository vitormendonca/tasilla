-- TASILLA MVP seed data.
-- Run after 202605310001_initial_mvp_schema.sql.

insert into public.skills (id, title, description, sort_order)
values
  ('listening', 'Listening', 'Audio comprehension, dictation and listening confidence.', 1),
  ('speaking', 'Speaking', 'Guided prompts, pronunciation practice and oral fluency.', 2),
  ('reading', 'Reading', 'Short texts, key vocabulary and comprehension practice.', 3),
  ('vocabulary', 'Vocabulary', 'Themed words, usage in context and cumulative review.', 4),
  ('homework', 'Grammar & Practice', 'Grammar patterns, sentence building and written practice.', 5),
  ('a1_roadmap', 'A1 Road Map', 'Guided A1 path with cumulative reviews and final test.', 0)
on conflict (id) do update
set
  title = excluded.title,
  description = excluded.description,
  sort_order = excluded.sort_order;

with skill_rows as (
  select * from (
    values
      ('listening', 'Listening'),
      ('speaking', 'Speaking'),
      ('reading', 'Reading'),
      ('vocabulary', 'Vocabulary'),
      ('homework', 'Grammar & Practice')
  ) as rows(skill_id, skill_title)
),
lesson_rows as (
  select
    skill_id,
    skill_title,
    lesson_number,
    lesson_number + ((lesson_number - 1) / 3)::int as step_order
  from skill_rows
  cross join generate_series(1, 12) as numbers(lesson_number)
),
review_rows as (
  select
    skill_id,
    skill_title,
    review_number,
    review_number * 4 as step_order
  from skill_rows
  cross join generate_series(1, 4) as numbers(review_number)
),
final_rows as (
  select
    skill_id,
    skill_title,
    17 as step_order
  from skill_rows
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
  skill_id || '_a1_lesson_' || lesson_number,
  'A1',
  skill_id,
  skill_title || ' Lesson ' || lesson_number,
  case skill_id
    when 'listening' then 'Listen, understand the main idea and answer short questions.'
    when 'speaking' then 'Practice a guided speaking prompt and build oral confidence.'
    when 'reading' then 'Read a short text and answer comprehension questions.'
    when 'vocabulary' then 'Learn themed vocabulary and use it in short sentences.'
    when 'homework' then 'Practice grammar and sentence structure with guided tasks.'
    else 'Complete the practice activity and keep moving forward.'
  end,
  'lesson',
  step_order,
  lesson_number,
  null
from lesson_rows
union all
select
  skill_id || '_a1_review_' || review_number,
  'A1',
  skill_id,
  skill_title || ' Review ' || review_number,
  'Review lessons ' || (((review_number - 1) * 3) + 1) || ' to ' || (review_number * 3) || '.',
  'review',
  step_order,
  null,
  review_number
from review_rows
union all
select
  skill_id || '_a1_final_test',
  'A1',
  skill_id,
  'A1 ' || skill_title || ' Final Test',
  'A stronger cumulative test for the full A1 ' || skill_title || ' path.',
  'final_test',
  step_order,
  null,
  null
from final_rows
on conflict (id) do update
set
  title = excluded.title,
  description = excluded.description,
  step_type = excluded.step_type,
  step_order = excluded.step_order,
  lesson_number = excluded.lesson_number,
  review_number = excluded.review_number;

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

insert into public.plans (id, name, max_students, price_cents, currency)
values
  ('free', 'Free', 3, 0, 'BRL'),
  ('starter', 'Starter', 25, 4900, 'BRL'),
  ('pro', 'Pro', 100, 9900, 'BRL')
on conflict (id) do update
set
  name = excluded.name,
  max_students = excluded.max_students,
  price_cents = excluded.price_cents,
  currency = excluded.currency;

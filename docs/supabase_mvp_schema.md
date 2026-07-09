# TASILLA Supabase MVP Schema

This schema prepares the app to move from local `SharedPreferences` data to a real multi-user backend.

## Core Decision

Use Supabase Free during development and move to Supabase Pro before production launch if the MVP has real users, needs backups, or exceeds the free limits.

## MVP Tables

- `organizations`: teacher or school account owner.
- `profiles`: authenticated users with `student`, `teacher`, or `admin` role.
- `classes`: teacher groups/classes with schedule metadata.
- `teacher_students`: relationship between teacher and student.
- `class_students`: students inside a class/group.
- `skills`: Listening, Speaking, Reading, Vocabulary, Grammar & Practice.
- `learning_steps`: A1 path steps, including 12 lessons, 4 reviews, and 1 final test per skill.
- `exercises`: real exercise content connected to skills and optional path steps.
- `exercise_questions`: questions/options for scored activities.
- `assignments`: teacher guidance for a student.
- `attempts`: student submissions and scores.
- `student_step_progress`: completed or validated path steps.
- `teacher_reviews`: teacher feedback.
- `level_check_attempts`: placement/level validation attempts.
- `certificates`: issued level certificates.
- `plans` and `subscriptions`: billing readiness for a paid teacher/school model.

## Implementation Order

1. Create a Supabase project on the Free plan.
2. Run `supabase/migrations/202605310001_initial_mvp_schema.sql`.
3. Run `supabase/seed.sql`.
4. Add `supabase_flutter` to the Flutter app.
5. Replace login mock data with Supabase Auth.
6. Migrate assignments and attempts first.
7. Migrate learning path progress.
8. Move exercises into the database.

## Important Notes

- Audio and speaking recordings should go to Supabase Storage, not database columns.
- The MVP should avoid realtime subscriptions unless a screen truly needs live updates.
- Certificate issuance should eventually happen through a trusted server/RPC flow, not directly from the client.
- Current RLS policies are a strong starting point, but should be tested with real teacher/student accounts before publication.

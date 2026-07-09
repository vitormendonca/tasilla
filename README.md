# TASILLA

TASILLA is a Flutter MVP for guided English learning. It combines a student learning road, teacher guidance, progress tracking, placement tests, and a Supabase-ready backend structure.

The project was built as a portfolio product: it shows mobile/web UI work, state management with local persistence, Supabase integration readiness, product thinking, and a complete teacher-student workflow.

## Problem

Many English students depend on the teacher to decide every next step. TASILLA gives the student a clear path to follow independently while keeping the teacher as a guide when assignments, review, or feedback are needed.

## Solution

- A guided A1 Road Map with 60 activities, reviews every 6 activities, and one final test.
- Skill paths for focused practice: Listening, Speaking, Reading, Vocabulary, and Grammar.
- Teacher guidance for assigning activities and reviewing student work.
- Student profile with progress, level badge, placement test access, and activity status.
- Dark and light UI themes.
- Supabase schema, seed, and Flutter bootstrap for real auth/progress migration.

## Demo Access

The app can run in local demo mode without Supabase credentials.

Student demo codes:

```text
joao123
maria123
ana123
```

Teacher demo code:

```text
teacher123
```

## Tech Stack

- Flutter / Dart
- Material 3
- Supabase Flutter
- SharedPreferences for local MVP state
- GitHub Pages deployment workflow
- Supabase SQL migrations and seed data

## Current MVP Features

- Student login with demo code or Supabase email login when configured.
- Teacher login with demo code.
- Student A1 Road Map.
- Linked progress between roadmap activities and skill categories.
- A1 reviews and final test checkpoints.
- Skill-specific paths.
- Teacher assignment flow.
- Teacher student progress view.
- Student profile and level badge system.
- Placement Test flow.
- Dark/light mode.
- Supabase database schema and row-level security policies.

## Running Locally

Install Flutter, then run:

```powershell
flutter pub get
flutter run -d chrome
```

To run with Supabase:

```powershell
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

If Supabase values are not provided, the app uses local MVP demo data.

## Supabase Setup

Run the SQL files in this order:

```text
supabase/migrations/202605310001_initial_mvp_schema.sql
supabase/migrations/202606010001_add_a1_roadmap_steps.sql
supabase/seed.sql
```

For GitHub Pages deployment with Supabase, add these repository variables:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
```

## Web Deployment

This repository includes a GitHub Actions workflow for GitHub Pages:

```text
.github/workflows/deploy-web.yml
```

After pushing to `main`, enable GitHub Pages:

1. Open the GitHub repository.
2. Go to Settings.
3. Open Pages.
4. In Build and deployment, choose GitHub Actions.
5. Push to `main`.

The workflow builds Flutter Web and deploys the `build/web` artifact.

## Project Structure

```text
lib/
  data/       Demo content and learning path definitions
  models/     App models
  screens/    Student, teacher, auth, and activity screens
  services/   Auth, assignments, progress, Supabase bootstrap
  theme/      Light/dark app theme
  widgets/    Shared UI components
supabase/
  migrations/ Database schema changes
  seed.sql    MVP seed data
tool/
  verify_learning_path.dart
```

## Validation

Useful local checks:

```powershell
dart analyze lib test tool
dart run tool\verify_learning_path.dart
```

## Roadmap

- Replace development exercise placeholders with richer real content.
- Add real speaking recording and teacher audio review.
- Move all assignments and attempts to Supabase.
- Improve certificates after final test completion.
- Add production payment flow for teacher/school plans.
- Expand A2, B1, B2, and C-level paths.

## Portfolio Note

This is an MVP built to demonstrate product design, Flutter development, backend planning, and iterative UX decisions. It is not a finished commercial learning platform yet, but it is structured to evolve into one.

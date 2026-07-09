# Supabase Flutter Setup

The app reads Supabase credentials from Dart defines. Do not commit project keys into source files.

## Install Package

When package download is available, add the official Flutter package:

```powershell
flutter pub add supabase_flutter
```

The current project already has a safe bootstrap placeholder, so the app keeps working while the dependency is not installed.

## Development Run

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

If these values are not provided, the app keeps using the current local/mock data flow. This lets us migrate one feature at a time.

## Where To Find The Values

In Supabase:

1. Open the TASILLA project.
2. Go to Project Settings.
3. Open API.
4. Copy `Project URL`.
5. Copy the public `anon` key.

## Migration Order

1. Auth and profiles.
2. Assignments and attempts.
3. Learning path progress.
4. Exercises and questions.
5. Speaking recordings through Storage.

# Supabase Flutter Setup

The app reads Supabase credentials and the student-code salt from **Dart defines**
(build-time constants). None of these values are stored in files — they are passed on the
command line, so they never get committed.

---

## Required defines

| Define | What it is | Where to find it |
|---|---|---|
| `SUPABASE_URL` | Project API URL | Supabase → Project Settings → API → **Project URL** |
| `SUPABASE_ANON_KEY` | Public anon key | Supabase → Project Settings → API → **anon / public** key |
| `STUDENT_CODE_SALT` | App-wide secret used to derive student passwords from access codes | Chosen once by you. **Never changes.** See below. |

**The anon key is safe to embed in a client app** — that is its purpose. Row Level
Security is what protects the data. **Never** use the `service_role` key in the app.

**Note on the URL:** it is `https://YOUR_PROJECT_REF.supabase.co` — NOT the dashboard link
(`https://supabase.com/dashboard/project/...`). Using the dashboard URL will fail silently.

---

## About `STUDENT_CODE_SALT`

Students log in with **only an access code**. The app derives their Supabase Auth
email/password from that code plus this salt (see `provisioning_students.md`).

**Critical:**
- Pick one long random string. Use it **forever**, in every run and every build.
- If it changes, every existing student's derived password breaks and none of them can log
  in until re-provisioned.
- It must **never** be committed. Treat it like a password.
- If it is missing at build time, student login silently fails with "Invalid access code" —
  a confusing symptom with a non-obvious cause.

---

## Development run

Rather than retyping this every time, keep it in a **git-ignored** script.

Create `run.ps1` in the project root:

```powershell
flutter run `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY `
  --dart-define=STUDENT_CODE_SALT=YOUR_SALT `
  -d chrome
```

Then just:

```powershell
.\run.ps1
```

**Add `run.ps1` to `.gitignore`.** It contains the salt.

---

## Release build

Same defines, same values:

```powershell
flutter build web `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY `
  --dart-define=STUDENT_CODE_SALT=YOUR_SALT
```

---

## Behaviour when defines are missing

| Missing | Result |
|---|---|
| `SUPABASE_URL` or `SUPABASE_ANON_KEY` | `SupabaseConfig.isConfigured` is false. App runs entirely on local `SharedPreferences` + hardcoded demo data. Login screen shows **"Demo mode"** at the bottom instead of **"Connected"**. Teacher email/password fields do not render. |
| `STUDENT_CODE_SALT` | Supabase connects fine, but the app derives the **wrong** password for every student. Student login fails with "Invalid access code." Teacher login still works (it does not use the salt). |

**Quick diagnostic:** the text at the bottom of the login screen tells you which state you
are in — "Connected" vs "Demo mode".

---

## Verifying it works

1. Run with all three defines.
2. Login screen should say **"Connected"** at the bottom.
3. Tap "I am a teacher" — email/password fields should appear (they are hidden in demo mode).
4. Log in as a provisioned student using their access code.
5. In Supabase → Authentication → Users, that student's **last sign-in** timestamp should
   update.

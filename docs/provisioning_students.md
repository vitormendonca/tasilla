# Provisioning Students (access-code login with real Supabase auth)

Students log in with **only an access code** — no email, no password typed.
Behind the scenes the app signs them into Supabase using credentials **derived**
from that code:

- **Email:** `{access-code}@students.tasilla.app`
- **Password:** `sha256("{access-code}::{STUDENT_CODE_SALT}")`

`STUDENT_CODE_SALT` is an app-wide secret passed at build time via `--dart-define`
(never committed). The same code + salt always produces the same password, so the
app can authenticate a student without storing per-student passwords anywhere.

**This means provisioning must create an Auth user whose password equals that
exact derived value.** You cannot type a random password — it has to match what
the app will compute. Use the helper script below to compute it.

---

## Step 0 — pick your salt (once, ever)

Choose a long random string. This is your `STUDENT_CODE_SALT`. Use the **same**
value everywhere: in every `flutter run/build` command, and in the provisioning
script. If you change it later, every existing student's derived password breaks
and they can't log in until re-provisioned. Treat it like a secret.

Example (generate your own, don't use this one):
```
STUDENT_CODE_SALT=Xk92mVq7nR4pLs0wZbYt3Hf6Dj1Ac8E
```

Run the app with it:
```
flutter run \
  --dart-define=SUPABASE_URL=https://dgkstqbrclbmrudailfz.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=STUDENT_CODE_SALT=Xk92mVq7nR4pLs0wZbYt3Hf6Dj1Ac8E
```

---

## Step 1 — compute the derived password for a student's code

Run this tiny Python helper (matches the app's Dart derivation exactly):

```python
import hashlib
access_code = "test-student-1"          # the code the student will type
salt        = "Xk92mVq7nR4pLs0wZbYt3Hf6Dj1Ac8E"   # your STUDENT_CODE_SALT
code = access_code.strip().lower()
email = f"{code}@students.tasilla.app"
password = hashlib.sha256(f"{code}::{salt}".encode()).hexdigest()
print("email:   ", email)
print("password:", password)
```

---

## Step 2 — create the Auth user with that exact email + password

In Supabase → Authentication → Users → Add user:
- Email: the `email` printed above (e.g. `test-student-1@students.tasilla.app`)
- Password: the `password` printed above (the long sha256 hex string)
- Tick "Auto Confirm User" so they can sign in immediately

The `handle_new_user()` trigger auto-creates a `profiles` row for this user.

---

## Step 3 — fill in the student's profile details

Copy the new user's `id` (UUID) from the Users table, then in SQL editor:

```sql
update public.profiles
set
  role = 'student',
  full_name = 'Test Student',
  current_level = 'A1',
  access_code = 'test-student-1'
where id = 'PASTE_STUDENT_UUID_HERE';
```

The `access_code` here must match exactly what you used in step 1.

---

## Step 4 — link the student to their teacher

```sql
insert into public.teacher_students (teacher_id, student_id, status)
values ('PASTE_TEACHER_UUID_HERE', 'PASTE_STUDENT_UUID_HERE', 'active');
```

---

## Done

The student can now type `test-student-1` on the login screen and be signed into
a real Supabase session — all their progress and scores will persist remotely and
be visible to their linked teacher.

**Note on the teacher account:** teachers still log in with email + password
directly (the "I am a teacher" screen), exactly as before. Only students use the
derived-credential access-code path.

# Supabase Auth Users

The app now supports Supabase email/password login, but each Auth user also needs a matching row in `public.profiles`.

## Create A Teacher

1. In Supabase, open Authentication.
2. Create a user with email and password.
3. Copy the new user `id`.
4. In SQL Editor, run:

```sql
insert into public.profiles (
  id,
  role,
  full_name,
  current_level
)
values (
  'PASTE_AUTH_USER_ID_HERE',
  'teacher',
  'Teacher',
  'A1'
);
```

## Create A Student

1. In Supabase, open Authentication.
2. Create a user with email and password.
3. Copy the new user `id`.
4. In SQL Editor, run:

```sql
insert into public.profiles (
  id,
  role,
  full_name,
  current_level,
  access_code
)
values (
  'PASTE_AUTH_USER_ID_HERE',
  'student',
  'Student Name',
  'A1',
  'student-demo-code'
);
```

## Notes

- The email/password account is handled by Supabase Auth.
- The app role, display name, level, and access code live in `public.profiles`.
- For the MVP, demo access codes still work locally while we migrate the rest of the app.

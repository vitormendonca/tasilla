# TASILLA — Architecture

## Client
Flutter Web / Dart. The client may use local demo data when Supabase configuration is absent, but production flows must use the persisted backend.

## Backend
Supabase Auth + PostgreSQL + Row Level Security. Supabase is the source of truth for identity, organizations, relationships, progress, attempts, submissions, reviews and certificates.

## Authorization
Authorization is enforced by PostgreSQL RLS and backend constraints, not by hidden UI controls.

The tenant boundary is:

organization → members → classes → class students → assignments/progress/evidence

Organization membership is stored in organization_members. Organization ownership is stored in organizations.owner_id. RLS policies prevent non-members from reading tenant rows.

Private SECURITY DEFINER helpers are used only where required to avoid RLS recursion; they have an empty search_path and restricted execute privileges.

## Data flow
Auth → profile → organization membership → class membership → learning activity → attempt/submission → teacher review → progress/competency → certificate → public verification.

## Data model boundary
student_step_progress is the current snapshot for a student/step. attempts is append-only history for retries and submitted answers.

organizations is now live in Supabase. classes is still the next schema dependency because assignments.class_id already exists but the active classes table does not yet.

## Important boundary
Never expose service-role/secret credentials in the Flutter client. Publishable/anon credentials are client-safe only when paired with correct RLS.

Supabase's current guidance treats grants and RLS as separate controls, so both must be reviewed for every exposed tenant table.
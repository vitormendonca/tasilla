# TASILLA — Architecture

## Identity
Supabase Auth provides authentication. public.profiles.role is the global account type and is constrained to school, teacher or student.

Global role and tenant role are deliberately separate:
- profiles.role = school | teacher | student
- organization_members.role = owner | admin | teacher | student

## Product boundaries
School owns an Organization. A School can manage Teachers subject to plan entitlements.
A Teacher may be independent and manage Students directly, or operate inside a School.
A Student may participate in authorized Teacher/School learning relationships.

An organization_id IS NULL teacher/student relationship is therefore not inherently legacy or invalid: it can represent the supported independent-Teacher model.

## Client
Flutter Web / Dart. Production flows use persisted backend state. Demo fallback is isolated from configured production environments.

## Backend
Supabase Auth + PostgreSQL + RLS. Supabase is the source of truth for identity, organizations, memberships, learning relationships, progress, attempts, submissions, reviews, certificates and future entitlements.

## Authorization
Authorization is enforced by RLS/backend constraints, never by hidden UI controls.

School tenant path:
School → Organization → Teachers → Classes/Students → learning data

Independent path:
Teacher → Students → learning data

## Organizations
organizations.owner_id references the School profile.
organization_members represents tenant membership and authorization within the School.
School ownership and Teacher membership must not be confused with the global account type.

## Learning state
Private learning records are scoped to an explicit teaching context. `student_submissions`, `student_step_progress`, `attempts` and `level_check_attempts` carry `teacher_id` plus nullable `organization_id`.

- `organization_id IS NULL` = Independent Teacher context.
- `organization_id IS NOT NULL` = School context.
- RLS requires the exact active Teacher → Student relationship in that context.
- `student_step_progress` is the current snapshot for a Student/Teacher/context/step.
- `attempts` is append-only history per Student/Teacher/context/step.
- Evidence Storage paths include Student, Teacher and context so a second Teacher linked to the same Student cannot read another Teacher's private evidence.

Certificates use the same context for eligibility and issuance. Independent Teacher certificates have NULL `organization_id`; School certificates carry the School id. Non-revoked certificate verification remains public by design.

## Security boundary
Never expose service-role/secret credentials in Flutter. Data API grants and RLS are separate controls and both must be reviewed for exposed tables.

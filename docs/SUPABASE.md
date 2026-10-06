# TASILLA — Supabase

## Connected project

- Project: tasilla project
- Ref: dgkstqbrclbmrudailfz
- PostgreSQL: 17

## Current architecture

The active backend supports three global account types in `profiles.role`: `school`, `teacher`, and `student`.

Global role and Organization membership are separate concepts. A Teacher can be independent, a member of a School, or both.

For `teacher_students`:
- `organization_id IS NULL` means the supported Independent Teacher scope.
- a non-null `organization_id` means the School tenant scope.

NULL must not be automatically mapped to an Organization or treated as invalid merely because the Teacher also belongs to a School.

The same Teacher/Student pair can coexist in independent and School scopes. Partial unique indexes enforce uniqueness independently for each scope.

## Organizations, entitlements and invitations

- Only a global `school` account can own/create a School Organization.
- `account_entitlements` centralizes pilot limits server-side.
- Pilot defaults currently used for technical validation: School 3 Teachers / 50 Students; Independent Teacher 10 Students. These are not final commercial pricing.
- School → Teacher invitations are tenant-aware.
- Invitation visibility and acceptance are authorized against the authenticated email in `auth.users`, not `profiles.email_normalized`.
- The public acceptance RPC is SECURITY INVOKER; a narrowly scoped helper in the private schema performs the required privileged membership mutation.
- School Student-limit lookup exposes only the numeric limit required by the linking operation.

## Classes

Classes are School-tenant resources and require an explicit Teacher.

`create_school_class` allows the School owner to create a Class only when the selected Teacher is an active Teacher member of the same Organization. Cross-School Teacher assignment is rejected.

The School account itself must never become `classes.teacher_id`.

## RLS and evidence

RLS remains enabled on the observed public application tables. Learning/evidence authorization must preserve both supported Teacher/Student scopes.

Submission Storage, assignments, attempts, progress, reviews and certification must not infer that a NULL `teacher_students.organization_id` is transitional. NULL can represent an intentional Independent Teacher relationship.

Where data is School-scoped, authorization must validate matching Organization membership. Where data is independent, authorization must validate the explicit Teacher/Student relationship and authenticated ownership.

## Security status

The earlier `public.enforce_submission_review_authority()` execution exposure was hardened: public/anon/authenticated execution was revoked and service-role execution retained where required.

Current Security Advisor status after the invitation-identity, dual-scope and School-Class regressions: only `auth_leaked_password_protection` remains. This is deferred because the current plan does not provide the feature.

No client-controlled metadata or profile email should be used as the authority for invitation identity.

## Migration discipline

The repository previously contained migration-history drift relative to the active project. Reconciliation has therefore been incremental rather than replaying the original MVP schema blindly.

Rules:
- never modify unrelated Supabase projects;
- review and test schema changes against the active project;
- keep every accepted production change represented in repository migrations;
- run rollback-only authorization regressions for tenant-sensitive changes;
- run Security Advisor after auth/RLS/function changes;
- never automatically migrate an Independent Teacher relationship into a School tenant.

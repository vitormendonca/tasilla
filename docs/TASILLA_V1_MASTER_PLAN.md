# TASILLA V1 Master Plan

## Product north star

School → organization → teacher → class → students → learning → evidence → teacher review → competency consolidation → approval → certificate → QR/code → public verification.

TASILLA is a B2B learning platform for teachers and schools. Students are the end users.

## Execution order

1. Sprint 0 — Foundation and audit.
2. Sprint 1 — Integrity — persist attempt history, answers, score, retry history and verify RLS.
3. Sprint 2 — Organizations — membership, roles, tenant isolation, invitations and data migration.
4. Sprint 3 — Classes — class lifecycle, enrollment, transfers and assignments.
5. Sprint 4 — Teacher dashboard.
6. Sprint 5 — Certification.
7. Sprint 6 — E2E quality.
8. Sprint 7 — Pilot.
9. Sprint 8 — Monetization.
10. Sprint 9 — Scale/admin/analytics.
11. Sprint 10 — Expansion.

## Current status

Sprint 1 attempt persistence is implemented and protected by a unique (student_id, learning_step_id, attempt_number) index.

The first Sprint 2 foundation is live:

- organizations
- organization_members
- tenant-aware RLS
- owner/admin/teacher/student membership roles
- private membership/ownership helpers

No existing users were migrated into an organization yet. This is deliberate: the next step is to connect the existing teacher/student relationship and class model without creating an unsafe implicit tenant.

## Current blockers

- The active database still lacks the classes table even though assignments.class_id exists.
- Historical repository schema definitions still require explicit reconciliation.
- Supabase Auth leaked-password protection is currently disabled.
- The application needs organization management UI/service before the new tables are useful to teachers.

## Immediate next gate

Build the organization service and teacher-facing organization creation/member flow, then connect teacher_students to organization membership.

After that, restore the missing classes dependency and make assignments.class_id enforce a real class relationship before expanding the teacher dashboard.

## Definition of done

A feature is done only when code is implemented, migrations are versioned when required, RLS/authorization are reviewed, loading/empty/error/retry states exist, automated tests cover critical behavior, the real target flow is verified, documentation is updated and no known regression remains.
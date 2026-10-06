# TASILLA V1 Master Plan

## Product north star

**School → organization → teacher → class → students → learning → evidence → teacher review → competency consolidation → approval → certificate → QR/code → public verification.**

TASILLA is a B2B learning platform for teachers and schools. Students are the end users.

## Execution order

1. **Sprint 0 — Foundation and audit** — documentation, repository/schema audit, migration reconciliation and security review.
2. **Sprint 1 — Integrity** — persist assessment/attempt history, connect attempts to progress, preserve answers/score/status/retry history and verify RLS.
3. **Sprint 2 — Organizations** — membership, roles, tenant isolation, invitations and data migration.
4. **Sprint 3 — Classes** — class lifecycle, enrollment, transfers and assignments.
5. **Sprint 4 — Teacher dashboard** — students, progress, pending reviews, risk indicators and certificate readiness.
6. **Sprint 5 — Certification** — four-skill gate, public verification, QR/share, audit trail and revocation.
7. **Sprint 6 — E2E quality** — teacher/student paths and security regression tests.
8. **Sprint 7 — Pilot** — 3–5 teachers and 20–50 students; measure activation, completion, teacher value and retention.
9. **Sprint 8 — Monetization** — plans, checkout, subscriptions and entitlement enforcement.
10. **Sprint 9 — Scale/admin/analytics** — administration, reporting, event instrumentation and support.
11. **Sprint 10 — Expansion** — A2/B1 and carefully scoped teacher-assistance AI.

## Definition of done

A feature is done only when code is implemented, migrations are versioned when required, RLS/authorization are reviewed, loading/empty/error/retry states exist, automated tests cover critical behavior, the real target flow is verified, documentation is updated and no known regression remains.

## Current blockers

- Supabase migration history does not yet reproduce the complete schema represented by the repository.
- The active database and repository must be reconciled before production schema changes.
- Supabase Auth leaked-password protection is currently disabled.
- Security hardening of the submission-review function has been applied and versioned.

## Immediate next gate

Do not start organizations/classes expansion yet. First finish schema reconciliation and then execute Sprint 1 against the existing attempts model rather than creating a duplicate assessment_attempts table.

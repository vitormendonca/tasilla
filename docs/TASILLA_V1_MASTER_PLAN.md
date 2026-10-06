# TASILLA V1 Master Plan

## Product north star

School → Teachers → Classes/Students → learning → evidence → review → competency → certification.

Independent Teacher → Students → Classes/Learning → evidence → review → certification.

TASILLA supports two paying account families: School and Independent Teacher. Student is the end user.

## Execution order

1. Sprint 0 — Foundation and audit.
2. Sprint 1 — Integrity.
3. Sprint 2 — Organizations / multi-tenancy.
4. Sprint 3 — Classes.
5. Sprint 4 — Teacher dashboard.
6. Sprint 5 — Certification.
7. Sprint 6 — E2E quality.
8. Sprint 7 — Pilot.
9. Sprint 8 — Monetization.
10. Sprint 9 — Scale/admin/analytics.
11. Sprint 10 — Expansion.

## Current status — 2026-10-06

### Completed foundation

- Three global account roles: School, Teacher and Student.
- School onboarding owns the Organization; Teacher does not need an Organization to operate independently.
- Teacher can belong to a School and continue using Independent Teacher context.
- `organization_id IS NULL` is the intentional independent scope; non-null is School scope.
- The same Teacher/Student pair can coexist in independent and School scopes without one relationship overwriting the other.
- Server-side entitlements enforce School Teacher/Student limits and Independent Teacher Student limits.
- School → Teacher invitation flow is tenant-aware and invitation identity is bound to the authenticated Auth email.
- School operational dashboard exposes real Teacher, invite, Student and Class metrics.
- School can create a Class only by selecting a Teacher belonging to the same School.
- Teacher Students UI exposes an explicit Independent Teacher context plus each School context.
- Email login enforces the selected Teacher/School global role.
- Multi-tenant, dual-context, invitation identity and School Class regressions have passed.
- Current Security Advisor result contains only the deferred leaked-password-protection warning.

### Current V1 gates

1. Finish School management UX: invitation revoke/resend semantics, Teacher/Student lists and Class management lifecycle.
2. Audit Teacher Classes UI so it no longer offers School Organization creation and so independent-vs-School class behavior is explicit.
3. Complete Student-side context selection and browser E2E for the now context-scoped assignment/progress/submission/assessment/certificate flows.
4. Complete Teacher Dashboard around real operational data.
5. Run end-to-end School → Teacher → Student and Independent Teacher → Student flows.
6. Validate Independent Teacher and School certification end-to-end in the target browser environment.
7. Complete pilot readiness, billing, admin and launch documentation.

### Superseded migration assumption

Earlier Sprint 2 work treated `teacher_students.organization_id IS NULL` as a temporary legacy state that should eventually be mapped into an Organization. That assumption is superseded.

Do not automatically map or retire NULL relationships. A NULL relationship is valid when it represents Independent Teacher scope. Historical sections below that refer to “legacy NULL relationships” document the earlier transition and must not be used as the current architecture rule.

## Definition of done

A feature is done only when code is implemented, migrations are versioned when required, RLS/authorization are reviewed, loading/empty/error/retry states exist, automated tests cover critical behavior, the real target flow is verified, documentation is updated and no known regression remains.

## 2026-10-06 — Contextual learning-data gate

Completed:
- assignments and Teacher Student screens propagate the selected Independent/School context;
- submissions/evidence carry explicit Teacher + Organization context and Storage paths are scoped by Student/Teacher/context;
- learning progress carries explicit Teacher + Organization context;
- attempts and level-check attempts carry explicit Teacher + Organization context;
- Review Queue exposes explicit Independent Teacher / School context selection;
- certification eligibility reads only progress/evidence belonging to the issuing Teacher and selected context;
- Independent Teacher certification is supported; School certification requires matching School memberships;
- public verification remains available for non-revoked certificates.

Validation:
- contextual assessment/progress/certification regression passed 5/5 with transactional fixtures and ROLLBACK;
- Flutter Quality/build/deploy for the contextual Progress/Review/Assessment/Certification commits completed successfully;
- Security Advisor reports only the deferred leaked-password-protection warning.

Remaining V1 work in this area:
- add explicit Student-side context selection before allowing a Student with multiple active teaching contexts to submit evidence or write progress/attempts;
- complete E2E browser validation for Independent Teacher → Student and School → Teacher → Student;
- keep public certificate verification separate from private tenant learning data.

## 2026-10-06 — Current tenancy and security checkpoint

Current rule:
- Independent Teacher relationship: `teacher_students.organization_id IS NULL`.
- School relationship: `teacher_students.organization_id IS NOT NULL`.
- A Teacher may use both simultaneously.
- Global account role and Organization membership role remain separate concepts.

Verified regressions:
- tenant isolation: 9/9;
- Teacher dual-scope relationship behavior: 3/3;
- invitation identity: 5/5;
- School Class creation for same-tenant Teacher: 2/2.

Invitation identity no longer depends on client-maintained `profiles.email_normalized`; it is checked against the authenticated Auth identity.

Security Advisor after these changes reports only the known leaked-password-protection warning, deferred under the current plan constraint.

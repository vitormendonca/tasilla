# Multi-tenant RLS regression

Last verified: 2026-10-06

This regression validates both supported ownership scopes without permanently changing production data. Fixtures are created inside transactions and discarded with ROLLBACK.

## Scope model

TASILLA intentionally supports two Teacher → Student scopes:

- `organization_id IS NULL`: Independent Teacher context, owned by the Teacher account and limited by the Teacher entitlement.
- `organization_id IS NOT NULL`: School context, isolated by Organization membership and limited by the School entitlement.

A NULL organization is not inherently legacy, invalid or awaiting migration. A Teacher may belong to one or more Schools while continuing to use the independent context.

The same Teacher/Student pair may exist once in the independent scope and once per School scope. Partial unique indexes preserve those relationships independently instead of moving one relationship between contexts.

## Tenant isolation regression

Passed 9/9:
- Student A can read only Organization A, Class A and Assignment A.
- Student B can read only Organization B, Class B and Assignment B.
- Organization A rejects enrollment, assignment and Teacher/Student mapping for a Student who belongs only to Organization B.

## Institutional flow regression

Passed:
- invited Teacher can accept an invitation and become a Teacher member of the intended School;
- Teacher can link a Student belonging to the same School;
- cross-School Student linking is rejected;
- Teacher cannot enumerate members from another School;
- School Teacher limits and Student limits are enforced server-side.

## Dual-context regression

Passed 3/3:
- a Teacher who is already a School member can still link a Student in Independent Teacher context;
- the same Teacher/Student pair can also exist in a School context;
- both records remain distinct and active.

The database uses:
- a partial unique index on `(teacher_id, student_id)` when `organization_id IS NULL`;
- a partial unique index on `(teacher_id, student_id, organization_id)` when `organization_id IS NOT NULL`.

## Invitation identity regression

Passed 5/5:
- wrong authenticated email cannot view the invitation;
- wrong authenticated email cannot accept the invitation;
- correct Auth email can view the invitation even if `profiles.email_normalized` differs;
- correct Auth email can accept the invitation;
- accepted Teacher becomes a member of the intended School.

Invitation authorization is bound to the authenticated identity in `auth.users`, not a client-maintained profile email. The public acceptance RPC remains SECURITY INVOKER; the narrowly scoped private helper performs the privileged membership mutation after validating the authenticated Teacher and invitation email.

## School Class creation regression

Passed 2/2:
- School owner can create a Class for an active Teacher belonging to that School;
- assigning a Teacher from another School is rejected.

The School UI must select an explicit Teacher. A School account is never used as `classes.teacher_id`.

## Learning evidence, progress, assessment and certification regression

Passed 5/5 in a rollback-only production-schema transaction:
- one Student can persist distinct Independent Teacher and School attempts/progress for the same Teacher without the scopes collapsing;
- Teacher B cannot read Teacher A private attempts or learning progress for a shared Student;
- Teacher A can read the private learning records assigned to Teacher A in both supported contexts;
- Teacher A can issue a certificate in Independent Teacher context when the active independent relationship exists;
- Teacher A can issue a separate School-context certificate when the Teacher, Student and relationship belong to that School.

`student_submissions`, `student_step_progress`, `attempts` and `level_check_attempts` now carry explicit `teacher_id` + nullable `organization_id` teaching context. NULL means Independent Teacher; non-NULL means School. Their RLS checks the exact active `teacher_students` relationship for that context.

Certificate verification is intentionally different from private learning records: a non-revoked certificate remains publicly readable by certificate code. Tenant isolation controls who may issue a certificate and which private evidence/progress may be used to establish eligibility; it must not disable public verification.

## Student multi-context end-to-end gate

Passed 6/6 in a rollback-only transaction against the production schema:
- Teacher A created separate Independent Teacher and School assignments for the same Student;
- the Student could read both records as distinct contexts;
- the Student persisted separate progress and evidence in Independent and School contexts;
- Teacher B, despite having a separate active relationship with the same Student, could not read Teacher A private progress or evidence;
- Teacher A reviewed evidence in both owned contexts and the review trigger stamped the assigned reviewer;
- Teacher A issued separate Independent and School certificates without collapsing their tenancy context.

All fixtures were rolled back. No persistent test users, memberships, assignments, evidence, progress or certificates were created.

The Flutter Student flow now resolves one validated active teaching context. A single relationship is selected automatically. Multiple active relationships require an explicit Student choice; no first-Teacher/first-School fallback is allowed. Assignments, submissions, progress, attempts and level checks consume that selected context, and local progress cache keys include it.

## Security status

Security Advisor after the current regressions reports only `auth_leaked_password_protection`. This warning is intentionally deferred under the current plan constraint.

Do not weaken RLS to simplify UI flows. New flows must preserve both independent and School scopes and must add rollback-only regression coverage for cross-tenant authorization.

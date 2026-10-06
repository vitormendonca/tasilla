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

## Security status

Security Advisor after the current regressions reports only `auth_leaked_password_protection`. This warning is intentionally deferred under the current plan constraint.

Do not weaken RLS to simplify UI flows. New flows must preserve both independent and School scopes and must add rollback-only regression coverage for cross-tenant authorization.

# Multi-tenant RLS regression

Last verified: 2026-10-06

This regression validates tenant isolation without permanently changing production data. Test fixtures are created inside a transaction and discarded with ROLLBACK.

## Verified

- Student A can read only Organization A.
- Student A can read only Class A.
- Student A can read only Assignment A.
- Student B can read only Organization B.
- Student B can read only Class B.
- Student B can read only Assignment B.
- Organization A class rejects a student who belongs only to Organization B.
- Organization A assignment rejects a student who belongs only to Organization B.
- Organization A teacher/student mapping rejects a student who belongs only to Organization B.

Result: 9/9 checks passed.

## Remaining transition constraint

The active database still has two active legacy teacher_students relationships with organization_id IS NULL. They intentionally keep the temporary compatibility path for teacher reads of attempts, student_step_progress, student_submissions and submission Storage.

Because there is currently only one teacher profile in the active test data, a strict Teacher A vs Teacher B regression cannot be honestly executed with the existing identities before the legacy relationships are explicitly mapped.

Do not remove the legacy branch until:

1. each active legacy relationship is explicitly mapped to the intended organization;
2. each target student has a student membership in that organization;
3. a second isolated teacher/organization identity is available for the final staff-side A x B regression;
4. attempts, progress, submissions, certificates and submission Storage are verified across both tenants;
5. Security Advisor and the application quality gate are rerun.

No automatic mapping is permitted.

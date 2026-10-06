# V1 interface and authentication gate

Verified on 2026-10-06. Source inspected: main at 746ee52.

## Commit-specific CI evidence

| Commit | Flutter Quality | Deploy Flutter Web |
| --- | --- | --- |
| 44a0ab8 | success, run 37532334657 | success, run 37532334723 |
| e16f5c9 | success, run 37532390907 | cancelled, run 37532391051 |
| 54442ab | success, run 37532407695 | success, run 37532407509 |

The Vercel status on all three commits is failure with a build-rate-limit URL. Successful GitHub Pages deployment does not establish successful Vercel deployment. These results also do not establish CI success for subsequent commits.

## Dashboard correction

Teacher dashboard metrics reload when returning from a destination screen, including reviews, students, classes and invitations. Each request captures its teaching context and only the latest request can update the screen. This prevents delayed responses from replacing metrics for a newer selection.

Static diff validation passed. Flutter and Dart are not installed in the execution workspace; analyzer, widget tests and authenticated browser verification of this change remain pending.

## Required browser evidence before V1 approval

Use dedicated test accounts and record deployed commit, URL, role, teaching context, expected result and observed result for each scenario:

1. Login as a teacher and student; reload and verify session and role routing. Verify invalid credentials and expired sessions have usable recovery paths.
2. Logout, then login as a different student on the same browser. Verify the previous account's teaching context, progress, assignments and identity do not appear.
3. With two student teaching contexts, verify explicit selection, reload persistence and data isolation for assignments, submissions, assessments and certificates.
4. Independent teacher: assign an activity, submit as the linked student, review as the teacher, return to the dashboard and verify updated metrics and student status.
5. School teacher: repeat the workflow in a school context and verify the independent context and another school do not expose those records.
6. Change dashboard contexts rapidly. Verify that the final selected context matches the displayed metrics; verify unavailable metrics show an error and Retry recovers.
7. Verify empty states and network failures in student learning, assignments, teacher reviews and progress. Check that all visible primary actions have a usable destination.
8. Verify a connected build without a session does not fall back to demo identities or local demonstration records.

Code inspection found no literal TODO, placeholder, coming-soon, or explicitly null tap/press handlers in teacher/student screens. This is a narrow static finding, not proof of functional completion.

## Gate decision

OPEN. The three historical quality runs are complete, but authenticated browser evidence and verification of the current deployed revision are still required. No V1 certification is asserted.

Leaked-password protection remains an accepted post-V1 dependency on Supabase Pro. This pass did not re-query Security Advisor; its unchanged status is user-reported.

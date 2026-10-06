# TASILLA — Supabase

## Connected project
- Project: tasilla project
- Ref: dgkstqbrclbmrudailfz
- PostgreSQL: 17

## Current observed schema
The active database contains profiles, teacher/student relationships, classes, class students, learning content, assignments, attempts, progress, teacher reviews, level-check attempts and certificates. All observed public tables have RLS enabled.

## Migration integrity issue
The Supabase migration history currently reports only migration version 20260717041825, while the repository contains older schema migrations that describe a substantially larger schema. This indicates migration-history drift and must be reconciled before production schema changes are considered complete.

## Security findings to resolve
Supabase advisors currently report that public.enforce_submission_review_authority() is SECURITY DEFINER and executable by anon and authenticated. Review and restrict this function before production certification flows.

Auth also reports leaked-password protection disabled; enable it before commercial launch.

## Rule
Never modify unrelated Supabase projects. All schema changes must be reviewed, verified with a test query, and represented in repository migrations before release.


## 2026-10-06 — Storage de submissions e isolamento por organização

A política de leitura dos arquivos privados de submissions foi endurecida para relações teacher_students já mapeadas a uma organização. O acesso exige professor owner/admin/teacher e aluno student na mesma organização. Relações legadas sem organization_id continuam temporariamente compatíveis durante a migração. A alteração foi aplicada no Supabase e versionada em 20261006130000_harden_submission_storage_tenant_access.sql.

Após a alteração, a política foi consultada diretamente no banco e o Security Advisor foi reexecutado. O único alerta restante continua sendo auth_leaked_password_protection, mantido pendente por decisão do projeto.


### 2026-10-06 — Teacher/student tenant boundary hardening

- New organization-scoped teacher/student relationships can no longer be created with a null `organization_id` by a teacher who already belongs to an organization.
- Organization-scoped inserts require the actor to be owner/admin/teacher in that organization and the target student to be a student member of the same organization.
- Existing legacy null relationships remain temporarily readable only for the explicit migration window; no automatic mapping was performed.
- Live policy was verified after application. Security Advisor remains at the known single warning: leaked-password protection disabled due to current plan constraint.
- Versioned migration: `20261006143000_harden_teacher_student_insert_tenant_boundary.sql`.

## 2026-10-06 — Three-account commercial model and entitlements

Product identity is now explicitly School, Teacher and Student. A Teacher may be independent; therefore a teacher_students row with organization_id NULL can be a valid independent-Teacher relationship and must not be automatically migrated or retired merely because it is unscoped.

Implemented:
- School is the global account type allowed to own/create an Organization.
- Teacher remains a standalone paid-account path and may also accept membership in a School.
- account_entitlements centralizes pilot limits server-side; Flutter does not define the authorization limit.
- School pilot defaults are 3 Teachers / 50 Students; independent Teacher pilot default is 10 Students. These are test defaults, not final commercial pricing.
- teacher_invitations supports School → Teacher invitation with tenant-aware RLS.
- invitation acceptance uses the authenticated Teacher profile email and SECURITY INVOKER; the earlier SECURITY DEFINER draft was replaced after Security Advisor flagged it.
- link_student_to_teacher enforces Student limits for independent Teachers and School tenants.
- Security Advisor after the final design reports only the known leaked-password-protection warning, deferred because of the current plan constraint.

Architecture rule: global account role (profiles.role) and organization membership role (organization_members.role) are separate concepts.

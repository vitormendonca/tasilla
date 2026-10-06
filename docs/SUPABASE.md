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

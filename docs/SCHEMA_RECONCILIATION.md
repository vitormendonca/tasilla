# TASILLA Schema Reconciliation

Date: 2026-10-06

## Finding

The active Supabase project dgkstqbrclbmrudailfz initially exposed seven public base tables: assignments, certificates, level_check_attempts, profiles, student_step_progress, student_submissions and teacher_students.

The earlier repository schema defined a broader model including organizations, classes, class_students, skills, learning_steps, exercises, exercise_questions, attempts, teacher_reviews, plans and subscriptions.

The active database could not be reproduced from its registered migration history without risking conflicts.

## Current active models

The database now contains the certification/submission model plus the Sprint 1 and first multi-tenant additions:

- student_submissions with speaking/writing evidence and teacher review fields.
- certificates with four skill scores and public name snapshots.
- student_step_progress as the current per-step snapshot.
- level_check_attempts.
- assignments with a class_id column.
- attempts as append-only step-attempt history.
- organizations and organization_members as the first multi-tenant foundation.
- classes and class_students for organization-scoped classroom enrollment.
- assignments.organization_id for explicit assignment tenancy, with tenant-aware RLS and compatibility for legacy null-tenant rows.
- assignments.class_id now references classes.id.

student_step_progress has a unique (student_id, learning_step_id) constraint, so it remains the current snapshot while attempts preserves historical retries.

## Migration history

Registered Supabase migrations now include:

1. 20260717041825_certificate_gate_launch_scope
2. 20261006114526_harden_submission_review_function_execute_privileges
3. 20261006114810_persist_step_attempt_history
4. 20261006114924_enforce_unique_step_attempt_numbers
5. organizations_multitenancy_foundation

## Multi-tenant foundation

organizations stores the tenant owner, display name and URL-safe slug.

organization_members stores one membership per user/organization with roles owner, admin, teacher and student.

RLS is enabled on both tables. Membership/ownership checks use private SECURITY DEFINER helpers with an empty search_path and restricted execute privileges. No existing user was automatically assigned to a new organization.

The foundation remains additive. Classes/enrollment are now live and assignments have an explicit organization boundary. Existing `teacher_students` rows are intentionally not auto-migrated. A future migration must explicitly map each teacher/student relationship into organization membership before legacy assignment authorization is retired.

## Decision

Do not apply the repository's original initial migration blindly. Reconciliation remains additive and explicit:

1. Capture the active schema as the source of truth for existing production data.
2. Add missing capabilities in dependency order.
3. Rebuild RLS for the final multi-tenant model.
4. Connect classes and assignments to organizations.
5. Verify Flutter queries against the resulting schema.
6. Run E2E and RLS regression tests before pilot.

## Security note

public.enforce_submission_review_authority() remains intentionally SECURITY DEFINER because it is a trigger function. Its public execute privilege has been removed.

Supabase Auth leaked-password protection remains the only current Security Advisor warning.

## 2026-10-06 — organização → alunos → matrícula

A base ativa recebeu duas migrações incrementais para permitir que staff da organização consulte perfis de alunos da própria organização, sem abrir leitura global de perfis:

- `20261006120654_allow_org_staff_to_read_student_profiles`
- `20261006120658_harden_org_student_profile_visibility`

A segunda migração substitui a primeira política por uma versão explicitamente tenant-aware, exigindo que o ator seja owner/admin/teacher da mesma organização do aluno.

No branch atual, a implementação Flutter correspondente está em:

- `OrganizationService.getStudentMembers()`
- `ClassService.listStudents()` com perfil do aluno
- `TeacherClassesScreen` com seleção de turma, roster e matrícula de alunos da organização.

**Regra de reconciliação:** essas migrações foram aplicadas diretamente no ambiente ativo durante a reconciliação. Antes de um novo bootstrap/replay de migrações, os arquivos de migração devem ser reconciliados com o histórico real para evitar reaplicação duplicada. Não executar cegamente a migration inicial antiga.


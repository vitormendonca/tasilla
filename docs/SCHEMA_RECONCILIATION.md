# TASILLA Schema Reconciliation

Date: 2026-10-06

## Finding

The active Supabase project dgkstqbrclbmrudailfz currently exposes seven public base tables:

- assignments
- certificates
- level_check_attempts
- profiles
- student_step_progress
- student_submissions
- teacher_students

The repository's initial migration defines a broader schema including organizations, classes, class_students, skills, learning_steps, exercises, exercise_questions, attempts, teacher_reviews, plans and subscriptions.

The active database therefore cannot be reproduced from the migration history currently registered in Supabase.

## Current active models

The database already contains the later certification/submission model:

- student_submissions with speaking/writing evidence and teacher review fields.
- certificates with four skill scores and public name snapshots.
- student_step_progress with score/status history.
- level_check_attempts.
- assignments with a class_id column, but no active classes table.

## Migration history

Registered Supabase migrations currently include:

1. 20260717041825_certificate_gate_launch_scope
2. 20261006114526_harden_submission_review_function_execute_privileges

The repository also contains earlier migrations that are not represented in the active migration history.

## Decision

Do not apply the repository's original initial migration blindly to the active project. It was designed for an earlier schema state and contains policies/functions that can conflict with the current certification/submission model.

The reconciliation must be additive and explicit:

1. Capture the active schema as the source of truth for existing production data.
2. Identify the repository migrations that created the seven active tables.
3. Create a clean forward migration baseline for missing capabilities.
4. Add missing tables/columns/constraints in dependency order.
5. Rebuild RLS for the final multi-tenant model.
6. Verify Flutter queries against the resulting schema.
7. Only then begin Sprint 1 integrity changes.

## Security note

public.enforce_submission_review_authority() is intentionally SECURITY DEFINER because it is a trigger function. Its public execute privilege has been removed and the correction is recorded in migration 20261006114526_harden_submission_review_function_execute_privileges.

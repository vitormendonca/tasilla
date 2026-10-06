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


## 2026-10-06 — mapeamento explícito de teacher_students

A migração ativa `20261006122730_map_legacy_teacher_students_to_organization` adiciona `teacher_students.organization_id` como referência opcional para `organizations` e cria a função transacional `map_teacher_student_to_organization(relationship_id, target_organization_id)`.

Regras:

- nenhuma relação existente é migrada automaticamente;
- somente o professor dono da relação pode solicitar o mapeamento;
- o professor precisa ser owner/admin/teacher da organização alvo;
- o aluno é inserido como membro `student` da organização, se ainda não estiver;
- uma relação já mapeada não pode ser movida silenciosamente para outra organização;
- a autorização legada continua ativa até que todas as relações necessárias sejam mapeadas e a cobertura RLS seja validada.

O arquivo correspondente deve permanecer versionado em `supabase/migrations/20261006122730_map_legacy_teacher_students_to_organization.sql`.


## 2026-10-06 — tela de alunos orientada por organização

- TeacherStudentsScreen passou a carregar as organizações disponíveis ao professor e exigir uma organização selecionada para consultar alunos.
- TeacherStudentsService.getStudentsForCurrentTeacher(organizationId: ...) é chamado com o tenant explícito.
- Relações legadas teacher_students sem organization_id não aparecem na tela de alunos de uma organização.
- Usuário autenticado sem organização vê estado vazio orientando a criação/entrada em uma organização, em vez de receber dados globais.
- Isso mantém a migração legada controlada e evita que a UI reintroduza o caminho global depois das políticas tenant-aware.


## 2026-10-06 — assignments e contexto de organização nas telas

- `AssignmentService.getAssignedActivitiesForStudent` passou a aceitar `organizationId` e filtrar assignments pelo tenant resolvido.
- `StudentAssignmentsScreen` deixou de usar `SharedPreferences` para decidir qual aluno consultar; em sessão autenticada usa `auth.currentUser.id` e o perfil remoto.
- `TeacherStudentDetailScreen`, `TeacherAssignActivityScreen` e `TeacherStudentAssignedActivitiesScreen` propagam o `organizationId` selecionado.
- Criação de assignment para aluno inclui o tenant explícito quando disponível.
- Operações autenticadas de assignments não usam mais `SharedPreferences` como fallback após falha remota.
- Atualização/cancelamento remoto confirma que uma linha foi efetivamente alterada antes de considerar a operação concluída.
- A autorização final continua no Supabase RLS; a UI não é considerada mecanismo de segurança.
- Ainda é necessário validar progress/certificate screens quanto ao mesmo contexto de organização e executar analyzer/testes Flutter no ambiente de desenvolvimento antes de declarar a etapa como totalmente validada.


## 2026-10-06 — transição de autorização dos dados de aprendizagem para tenant

A auditoria de RLS confirmou que attempts, student_step_progress, student_submissions e certificates ainda usavam teacher_students como autorização principal. A migração 20261006124247_harden_learning_data_tenant_transition atualizou essas políticas.

- Relação teacher_students com organization_id preenchido: o professor/staff precisa ser membro owner/admin/teacher da organização e o aluno precisa ser membro student da mesma organização.
- Relação ainda sem organization_id: o caminho legado continua temporariamente permitido para não quebrar os dois relacionamentos existentes durante a migração.
- O banco foi verificado após a alteração e as políticas novas estão ativas.
- Estado atual: 2 relacionamentos ativos; 0 mapeados; 2 ainda não mapeados.
- Portanto, a remoção definitiva da autorização legada ainda NÃO deve ser feita.
- Security Advisor continua apresentando somente auth_leaked_password_protection como alerta; nenhum novo alerta de RLS foi introduzido por esta alteração.

### Critério para retirar o legado

1. Mapear explicitamente todos os relacionamentos ativos para uma organização.
2. Confirmar membership student correspondente para cada aluno.
3. Executar teste E2E de isolamento entre duas organizações.
4. Substituir as políticas para remover o ramo organization_id is null.
5. Reexecutar Security Advisor e testes de regressão.

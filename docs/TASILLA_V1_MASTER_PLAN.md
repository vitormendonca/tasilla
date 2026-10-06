# TASILLA V1 Master Plan

## Product north star

School → organization → teacher → class → students → learning → evidence → teacher review → competency consolidation → approval → certificate → QR/code → public verification.

TASILLA is a B2B learning platform for teachers and schools. Students are the end users.

## Execution order

1. Sprint 0 — Foundation and audit.
2. Sprint 1 — Integrity — persist attempt history, answers, score, retry history and verify RLS.
3. Sprint 2 — Organizations — membership, roles, tenant isolation, invitations and data migration.
4. Sprint 3 — Classes — class lifecycle, enrollment, transfers and assignments.
5. Sprint 4 — Teacher dashboard.
6. Sprint 5 — Certification.
7. Sprint 6 — E2E quality.
8. Sprint 7 — Pilot.
9. Sprint 8 — Monetization.
10. Sprint 9 — Scale/admin/analytics.
11. Sprint 10 — Expansion.

## Current status

Sprint 1 attempt persistence is implemented and protected by a unique (student_id, learning_step_id, attempt_number) index.

The first Sprint 2 foundation is live:

- organizations
- organization_members
- tenant-aware RLS
- owner/admin/teacher/student membership roles
- private membership/ownership helpers
- classes and class_students with tenant-aware RLS
- assignments.organization_id with tenant-aware assignment RLS
- student update protection preventing reassignment across tenant/class/teacher boundaries

No existing users were migrated into an organization yet. This is deliberate: the next step is to connect the existing teacher/student relationship and class model without creating an unsafe implicit tenant.

## Current blockers

- Existing `teacher_students` rows still need an explicit organization mapping before the legacy relationship can be retired.
- Historical repository schema definitions still require explicit reconciliation.
- Supabase Auth leaked-password protection is currently disabled.
- Teacher-facing organization/class/assignment UI is being connected incrementally; the Classes screen now consumes live organization/class data and can create both organizations and classes.

## Immediate next gate

Finish the organization → class → enrollment → assignment application flow, then explicitly map `teacher_students` into organization membership and retire legacy assignment authorization only after RLS regression coverage is in place.

Next: use the explicit teacher/student relationship mapping to place legacy relationships into an organization, then make the student/assignment screens organization-aware before expanding dashboard analytics.

## 2026-10-06 — legacy relationship mapping

The active database now supports explicit mapping of a `teacher_students` relationship into an organization. Mapping is never automatic: the teacher must select a specific relationship and target organization. The transactional function also creates the student's organization membership when needed, and the relationship remains unchanged if mapping fails.

The legacy relationship remains readable during transition. Legacy assignment authorization is not retired until the existing relationships are explicitly mapped and RLS regression coverage confirms the tenant path.

## Definition of done

A feature is done only when code is implemented, migrations are versioned when required, RLS/authorization are reviewed, loading/empty/error/retry states exist, automated tests cover critical behavior, the real target flow is verified, documentation is updated and no known regression remains.

## 2026-10-06 — isolamento de assignments e leitura de progresso

### Concluído nesta etapa

- TeacherStudentsScreen opera com organização selecionada e passa o tenant para o detalhe do aluno.
- TeacherStudentDetailScreen propaga organizationId para assignments.
- TeacherAssignActivityScreen consulta e cria assignments no contexto da organização.
- TeacherStudentAssignedActivitiesScreen consulta assignments no contexto da organização.
- StudentAssignmentsScreen usa a identidade autenticada (auth.currentUser.id) para carregar os próprios assignments, em vez de nome persistido localmente.
- AssignmentService filtra leituras remotas por organização quando o contexto está disponível.
- Para usuários autenticados, falhas remotas de assignments não retornam silenciosamente dados de SharedPreferences.
- Atualizações e cancelamentos remotos confirmam a linha alterada.
- Leitura de progresso de outro aluno não cai mais em estado local persistido quando a sessão está autenticada e a consulta remota falha.

### Validação pendente

- Executar flutter analyze e testes Flutter no ambiente de desenvolvimento.
- Fazer validação E2E com duas organizações para comprovar que professor/aluno de uma organização não enxergam assignments da outra.
- Revisar progress/certificate RLS para aposentar definitivamente dependências legadas de teacher_students.


## 2026-10-06 — transição RLS dos dados de aprendizagem

A migração 20261006124247_harden_learning_data_tenant_transition atualizou attempts, student_step_progress, student_submissions e certificates para reconhecer organization_id nas relações teacher_students mapeadas. Relações ainda não mapeadas permanecem no caminho legado durante a transição.

Estado verificado: 2 relacionamentos ativos, 0 mapeados e 2 não mapeados. A retirada definitiva do legado fica bloqueada até o mapeamento explícito, teste E2E de isolamento entre organizações e nova rodada de Security Advisor.

Security Advisor: permanece apenas auth_leaked_password_protection; nenhum novo alerta de RLS apareceu.


## 2026-10-06 — propagação do contexto de organização nas telas de aprendizagem

A auditoria das telas derivadas de `TeacherStudentDetailScreen` identificou que o contexto `organizationId` já estava presente na seleção do aluno e nas atribuições, mas não era propagado para Progresso e Certificado.

Correção aplicada:
- `TeacherStudentAssignedActivitiesScreen` recebe explicitamente `organizationId`.
- `TeacherStudentProgressScreen` recebe `organizationId` e o repassa ao serviço de progresso.
- `TeacherCertificateSignoffScreen` recebe `organizationId` e o repassa às operações de leitura/eligibilidade/emissão.
- `LearningPathProgressService` valida a relação ativa professor → aluno → organização antes de devolver progresso remoto para uma visão de professor.
- `CertificateService` aplica a mesma validação ao calcular elegibilidade e progresso usado na emissão.
- `SubmissionService.getSubmissionsForStudent` valida a relação ativa na organização quando a chamada parte do professor.

Importante: as tabelas de progresso e submissions ainda não possuem `organization_id` próprio. Portanto esta etapa reforça o contexto na camada de serviço e depende das políticas RLS tenant-aware já implantadas. A separação física por tenant dos dados históricos continua como etapa posterior caso a plataforma precise suportar o mesmo aluno compartilhado entre organizações com dados de aprendizagem independentes.

Validação de qualidade: os arquivos foram revisados após a alteração via GitHub. O ambiente disponível nesta sessão não possui execução local confirmada do Flutter analyzer/test suite; portanto não declarar testes Flutter como aprovados até rodar no ambiente de desenvolvimento.


## 2026-10-06 — fechamento da propriedade tenant-aware de evidências e certificados

A auditoria do fluxo de evidência encontrou e corrigiu dois pontos de tenancy: leitura de arquivos privados de submissions no Storage e propriedade de certificados. O Storage agora exige organização compatível para relações mapeadas; certificados passaram a registrar `organization_id` e exigir o mesmo tenant na emissão/leitura do professor.

A emissão de certificado agora exige organização explícita no serviço e o banco é a autoridade final. O fluxo de verificação pública por código permanece público apenas para certificados não revogados.

Próximo gate: validação E2E em ambiente Flutter real (analyzer/testes e fluxo aluno → submission → revisão → certificado), pois essa execução ainda não foi confirmada nesta sessão.


### 2026-10-06 — Teacher/student tenant boundary hardening

- New organization-scoped teacher/student relationships can no longer be created with a null `organization_id` by a teacher who already belongs to an organization.
- Organization-scoped inserts require the actor to be owner/admin/teacher in that organization and the target student to be a student member of the same organization.
- Existing legacy null relationships remain temporarily readable only for the explicit migration window; no automatic mapping was performed.
- Live policy was verified after application. Security Advisor remains at the known single warning: leaked-password protection disabled due to current plan constraint.
- Versioned migration: `20261006143000_harden_teacher_student_insert_tenant_boundary.sql`.

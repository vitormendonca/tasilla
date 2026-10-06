# TASILLA V1 Master Plan

## Product north star

School → Teachers → Classes/Students → learning → evidence → review → competency → certification.

Independent Teacher → Students → Classes/Learning → evidence → review → certification.

TASILLA supports two paying account families: School and Independent Teacher. Student is the end user.

## Execution order

1. Sprint 0 — Foundation and audit.
2. Sprint 1 — Integrity.
3. Sprint 2 — Organizations / multi-tenancy.
4. Sprint 3 — Classes.
5. Sprint 4 — Teacher dashboard.
6. Sprint 5 — Certification.
7. Sprint 6 — E2E quality.
8. Sprint 7 — Pilot.
9. Sprint 8 — Monetization.
10. Sprint 9 — Scale/admin/analytics.
11. Sprint 10 — Expansion.

## Current status — 2026-10-06

### Completed foundation

- Three global account roles: School, Teacher and Student.
- School onboarding owns the Organization; Teacher does not need an Organization to operate independently.
- Teacher can belong to a School and continue using Independent Teacher context.
- `organization_id IS NULL` is the intentional independent scope; non-null is School scope.
- The same Teacher/Student pair can coexist in independent and School scopes without one relationship overwriting the other.
- Server-side entitlements enforce School Teacher/Student limits and Independent Teacher Student limits.
- School → Teacher invitation flow is tenant-aware and invitation identity is bound to the authenticated Auth email.
- School operational dashboard exposes real Teacher, invite, Student and Class metrics.
- School can create a Class only by selecting a Teacher belonging to the same School.
- Teacher Students UI exposes an explicit Independent Teacher context plus each School context.
- Email login enforces the selected Teacher/School global role.
- Multi-tenant, dual-context, invitation identity and School Class regressions have passed.
- Current Security Advisor result contains only the deferred leaked-password-protection warning.

### Current V1 gates

1. Finish School management UX: invitation revoke/resend semantics, Teacher/Student lists and Class management lifecycle.
2. Audit Teacher Classes UI so it no longer offers School Organization creation and so independent-vs-School class behavior is explicit.
3. Verify assignment/progress/submission/certificate behavior in both supported scopes; older code was built during the previous organization-migration interpretation.
4. Complete Teacher Dashboard around real operational data.
5. Run end-to-end School → Teacher → Student and Independent Teacher → Student flows.
6. Update certification for Independent Teacher issuance where product rules permit it.
7. Complete pilot readiness, billing, admin and launch documentation.

### Superseded migration assumption

Earlier Sprint 2 work treated `teacher_students.organization_id IS NULL` as a temporary legacy state that should eventually be mapped into an Organization. That assumption is superseded.

Do not automatically map or retire NULL relationships. A NULL relationship is valid when it represents Independent Teacher scope. Historical sections below that refer to “legacy NULL relationships” document the earlier transition and must not be used as the current architecture rule.

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




## 2026-10-06 — Current tenancy and security checkpoint

Current rule:
- Independent Teacher relationship: `teacher_students.organization_id IS NULL`.
- School relationship: `teacher_students.organization_id IS NOT NULL`.
- A Teacher may use both simultaneously.
- Global account role and Organization membership role remain separate concepts.

Verified regressions:
- tenant isolation: 9/9;
- Teacher dual-scope relationship behavior: 3/3;
- invitation identity: 5/5;
- School Class creation for same-tenant Teacher: 2/2.

Invitation identity no longer depends on client-maintained `profiles.email_normalized`; it is checked against the authenticated Auth identity.

Security Advisor after these changes reports only the known leaked-password-protection warning, deferred under the current plan constraint.

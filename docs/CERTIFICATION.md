# TASILLA — Certification Standard

## V1 competency model
Certification evaluates four skills independently:
- Listening
- Reading
- Speaking
- Writing

Each skill must satisfy the documented threshold. Speaking and Writing require teacher-reviewed evidence; teacher approval is authoritative for certification evidence.

## Certificate
A certificate contains a unique code and must support public verification without exposing unnecessary student data. It must distinguish valid and revoked certificates.

## Integrity rules
- Certification eligibility is computed from persisted evidence.
- Client-side state cannot grant a certificate.
- Certificate issuance must be auditable.
- Public verification must not expose private student records.
- Final exam requirements must be explicit and versioned when enabled.


## 2026-10-06 — certificação tenant-aware

Antes da emissão real de certificados, a tabela `certificates` passou a possuir `organization_id`. A emissão agora exige uma organização explícita e a política de INSERT exige que o emissor seja professor/owner/admin na mesma organização do aluno, com membership `student` do aluno. A leitura de professor também é limitada ao tenant; a verificação pública por código permanece independente da organização.

O banco não possuía certificados emitidos no momento da alteração, portanto não houve backfill histórico. O serviço Flutter passou a persistir `organization_id`, exigir tenant na emissão e filtrar a consulta do certificado por organização quando esse contexto estiver disponível.

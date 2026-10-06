# TASILLA — Product

## Positioning
TASILLA is a learning platform with three explicit account types: School, Teacher and Student. Schools and independent Teachers are the paying customers; Students are learning end users.

## Account model
- School: owns a school workspace/organization, manages Teachers and Students, and is constrained by its subscription entitlements.
- Teacher: may operate independently or as a member of a School. An independent Teacher can register/manage Students up to the limit of the Teacher plan.
- Student: learns, completes activities, submits evidence, tracks progress and receives certificates.

## Commercial hierarchy
School → Teachers → Students

Independent path:
Teacher → Students

A Teacher does not need to belong to a School.

## Core workflow
School/Teacher → classes → students → learning activities → evidence → teacher review → competency consolidation → approval → certificate → public verification.

## V1 focus
- Three explicit authentication/onboarding experiences
- Guided A1 learning path
- Teacher/student relationship
- School teacher management
- Classes and assignments
- Progress and evidence
- Listening, Reading, Speaking and Writing competencies
- Teacher review
- Verifiable certification
- Plan-based Teacher/Student limits

## Product principle
The authoritative identity, entitlement and learning state must be persisted in Supabase. UI checks are not authorization.

## Definition of Done
A feature is complete only when code, database/RLS, error states, tests, real flow validation and documentation are updated without regression.

# TASILLA — Architecture

## Client
Flutter Web / Dart. The client may use local demo data when Supabase configuration is absent, but production flows must use the persisted backend.

## Backend
Supabase Auth + PostgreSQL + Row Level Security. Supabase is the source of truth for identity, relationships, progress, attempts, submissions, reviews and certificates.

## Authorization
Authorization is enforced by PostgreSQL RLS and backend constraints, not by hidden UI controls. Teacher access is limited to authorized students/classes and organization boundaries must be enforced when multi-tenancy is enabled.

## Data flow
Auth → profile → organization/class membership → learning activity → attempt/submission → teacher review → progress/competency → certificate → public verification.

## Important boundary
Never expose service-role/secret credentials in the Flutter client. Publishable/anon credentials are client-safe only when paired with correct RLS.

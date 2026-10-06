# TASILLA

TASILLA is a Flutter learning platform being evolved from an MVP into a B2B product for teachers, language schools and educational organizations. Students are the end users.

## Product direction

The core workflow is:

School → organization → teacher → class → students → learning → evidence → teacher review → competency consolidation → approval → certificate → QR/code → public verification.

The first commercial validation scope is A1.

## Current capabilities

- Flutter Web application.
- Supabase authentication and persistence.
- Teacher/student profiles and relationships.
- Guided A1 learning path.
- Progress and level-check attempts.
- Teacher assignments.
- Speaking and writing submissions.
- Teacher review and approval.
- Four-skill certificate eligibility.
- Certificate issuance and public verification data.
- Automated tests around the certification gate.
- Local demo fallback when Supabase configuration is absent.

## Architecture

The Flutter client uses Supabase through the application services layer. The database is protected with Row Level Security.

Supabase project used by the TASILLA application:

- Project ref: dgkstqbrclbmrudailfz
- Region: us-east-1

The exact active schema and migration reconciliation are documented in docs/SCHEMA_RECONCILIATION.md.

## Important development rule

The active Supabase database and the repository migration history are currently not identical. Do not blindly replay the original MVP migration against the active project.

Schema changes must be inspected against the live database, implemented as forward migrations, protected by RLS and authorization, verified with SQL tests, reflected in Flutter services/models, and documented.

## Running locally

Install Flutter, then:

flutter pub get
flutter run -d chrome

With Supabase:

flutter run -d chrome --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY

If Supabase values are not provided, the app can use local MVP/demo data.

## Validation

Useful checks:

dart analyze lib test tool
dart run tool\verify_learning_path.dart

## Documentation

- docs/PRODUCT.md — product positioning and target customer.
- docs/ROADMAP.md — execution roadmap.
- docs/ARCHITECTURE.md — application architecture.
- docs/SUPABASE.md — database/security notes.
- docs/CERTIFICATION.md — certification standard.
- docs/CONTENT.md — content contract and launch scope.
- docs/BILLING.md — planned B2B billing.
- docs/SCHEMA_RECONCILIATION.md — live database versus repository migration findings.
- docs/TASILLA_V1_MASTER_PLAN.md — end-to-end execution order.

## Next engineering gate

Finish schema reconciliation first. Then execute Sprint 1 against the existing attempts/progress model, preserving historical answers, scores, status and retries without creating a duplicate assessment table.

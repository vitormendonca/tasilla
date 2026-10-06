# TASILLA Billing

## Paying account types
TASILLA has two commercial account families and one end-user account:
- Teacher: can subscribe independently and manage Students up to the plan entitlement.
- School: can subscribe as an organization and manage Teachers up to the plan entitlement; School plans may also impose aggregate Student or other usage limits.
- Student: end user; not the subscription owner in V1.

## Entitlement model
Limits must be persisted and enforced server-side. Never hard-code commercial limits in Flutter.

Core entitlements:
- Teacher plan: max_students and feature flags.
- School plan: max_teachers, optional max_students, and feature flags.
- School membership determines which Teachers operate inside the organization.
- Independent Teacher relationships remain valid without an organization.

## Planned commercial model
- Free/demo: evaluation limits.
- Teacher Pro: independent Teacher with a controlled Student limit.
- School: organization with controlled Teacher/Student limits, classes and reporting.
- School+/Business: higher limits, administration and support.

Prices and exact limits remain product decisions until pilot validation.

## Billing lifecycle
1. Select plan.
2. Checkout.
3. Trusted webhook updates subscription.
4. Persist subscription and entitlements.
5. Backend/RLS/RPC enforces limits.
6. UI reflects persisted entitlements.
7. Handle renewal, cancellation, failed payment and downgrade.

## Definition of done
Billing is complete only after checkout, webhook, entitlement enforcement, limit exhaustion, renewal, cancellation, failure and recovery are tested end-to-end.

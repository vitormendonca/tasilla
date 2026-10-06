# TASILLA Billing

## Positioning

TASILLA is a B2B product for teachers, language schools and educational organizations. Students are the end users; the paying customer is normally the teacher or organization.

## Planned commercial model

Initial plans should remain simple:

- Free/demo: limited usage for evaluation.
- Teacher Pro: one teacher with a controlled student limit.
- School: organization, multiple teachers, classes and reporting.
- School+/Business: higher limits, administration and support.

Prices and limits are product decisions to validate during the pilot, not hard-coded assumptions.

## Billing architecture

The production flow must be:

1. Select plan.
2. Checkout with payment provider.
3. Provider creates/updates subscription.
4. Webhook is received by a trusted backend.
5. Subscription state is persisted.
6. Backend enforces limits.
7. UI reflects the persisted entitlement.
8. Renewal, cancellation, failed payment and downgrade are handled explicitly.

Never rely on client-side plan checks for authorization or limits.

## Current database foundation

The original repository schema already defines plans and subscriptions. The active Supabase project must be reconciled with that baseline before billing is enabled.

## Definition of done

Billing is not complete until checkout, webhook handling, subscription state, limits, failure states, cancellation and recovery have been tested end-to-end.

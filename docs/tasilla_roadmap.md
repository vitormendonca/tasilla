# TASILLA — Roadmap Guide

*Last updated: 2026-07-15. This is the live, consolidated roadmap. It supersedes the*
*roadmap section in `tasilla_development_guide.md` (§8), which predates the MVP pieces landing.*

---

## The one goal

> **Issue one real A1 certificate to one real student** — a certificate that means exactly
> what `tasilla_a1_certification_standard.md` says it means.

Every phase below is measured against that. Anything that doesn't serve it is deferred.

---

## Where we are right now

The 5-piece **Teacher Review Loop** (`mvp_spec.md`) is code-complete and merged. The MVP is
**one page and one end-to-end test away from done**.

| Layer | State |
|---|---|
| Assessment engine (scored, gated quizzes + audio) | ✅ shipped |
| Supabase auth (student access code + teacher email) + RLS | ✅ shipped |
| Submissions: speaking recording, writing typed + handwritten photo | ✅ shipped |
| Teacher review queue (approve / request redo) | ✅ shipped |
| Per-skill scoring + certificate eligibility gate | ✅ shipped |
| Teacher certificate sign-off screen | ✅ shipped |
| **Public verification page `/verify/{code}`** | ❌ **not built** |
| **End-to-end loop run on real data** | ❌ **not done** |

---

## Phase 0 — Close the MVP  ← **YOU ARE HERE**

The gap between "5 pieces merged" and "MVP done."

- [ ] **Public certificate verification page** — `/verify/{certificate_code}`, no login,
      employer-facing. Shows level, issue date, per-skill scores, issuing teacher, proven
      can-do statements. Lookup already exists in `certificate_service.dart:394`; only the
      page is missing.
- [ ] **Run the loop end-to-end on real data** — one student records speaking + submits
      writing → teacher hears/reads/approves → all 4 skills clear 70% independently → final
      exam passed → teacher signs off → certificate issues → verify link resolves.
- [ ] **Audio integrity** — fix filename/transcript alignment, register audio assets in
      `pubspec.yaml`, confirm the player works against the real ElevenLabs files.

**Definition of done:** the honest MVP paragraph in `mvp_spec.md §7` is literally true when
demonstrated live.

---

## Phase 1 — First real students (beta)

- [ ] Provision 3–5 real students (see `provisioning_students.md`)
- [ ] Run a real cohort through EXP 001–020 in demo/live mode
- [ ] Collect friction: where students stall, where teachers hesitate to approve
- [ ] Fix the top 3 issues the beta surfaces — nothing speculative

---

## Phase 2 — Trust & money (v1.1)

Make the certificate sellable without manual fulfillment.

- [ ] **Stripe webhook** → automatic access unlock tied to a specific account
      (today's Payment Links are manual-fulfillment only)
- [ ] In-app certificate paywall: $9 standalone / unlimited on paid plans
- [ ] Tie subscription tier limits (student/teacher counts) to real account state

---

## Phase 3 — Content depth (v1.2)

Raise the ceiling from "20 solid lessons" to a full A1 track.

- [ ] Rewrite EXP 021–040 to the Unit 1–2 quality bar
- [ ] Write the ~130 missing Skill Path exercises
      (Listening +11, Speaking +16, Reading +15, Vocabulary +11, Grammar +7)
- [ ] Replace templated quiz questions in the 18 reinforcements, 6 reviews, 3 checkpoints
- [ ] Build the multi-format final exam (dictation, gap-fill, production)
- [ ] Raise the certificate bar back to **10 speaking + 10 writing** once content supports it
      (MVP honestly ships at the lower number the 20 lessons allow)

---

## Phase 4 — Reference standard (v2)

- [ ] Full certification-standard implementation
- [ ] The 20-topic content restructure
- [ ] A2 track (same CEFR structure, no architectural change)
- [ ] Onboarding flow

---

## Backlog / ideas (not scheduled)

- Multi-language tracks (Portuguese, Spanish) — revisit after English A1→B2 is complete
- Push notifications for homework
- App-store release (web-first for now)
- Local pricing power parity (Stripe) per market
- Pro trial period before falling back to Free
- Login identity messaging (teacher/school connection)
- Logo

---

## How to use this guide

1. **Work top-down.** Don't start a phase until the one above is demonstrably done.
2. **Every phase ends in a demo,** not a merged PR — the loop must be *seen* working.
3. **Before any release:** `flutter analyze` clean + visual review of both themes +
   dark/light screenshots for every new screen (per dev guide §9).
4. When reality diverges from this file, **update this file** — it is the source of truth
   for "what's next," and the dev guide is the source of truth for "how we build."

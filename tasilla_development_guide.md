# TASILLA — Development Guide

**Teachers And Schools International Language Learning Application**

This is the single source of truth for how we build TASILLA. Every decision here was made deliberately. When in doubt, come back to this document.

---

## 1. What TASILLA is

An English learning app built by a real teacher, where the teacher is the center of the experience — not an afterthought. Students follow a structured CEFR-aligned path; teachers assign, review, and validate real progress.

**The differentiator:** human teacher validation. Duolingo has no teacher. iTalki has no structured path. TASILLA has both.

**Target user (v1):** Brazilian adult students learning English with a private teacher or small school. Interface in English.

**Long-term vision:** TASILLA = Teachers And Schools International **Language** Learning Application. English is the first language, not the only one. When a second language is added (Portuguese, Spanish, etc.), the same CEFR structure, certification standard, and teacher model apply — no architectural changes needed today. Just avoid hardcoding the word "English" in places that represent the language being learned (use the track's language field instead).

---

## 2. Product principles

1. **The teacher is the gatekeeper.** Speaking and writing are validated by a human, never only by the app.
2. **The certificate must mean something.** A TASILLA A1 certificate = real CEFR A1, verifiable by employers. (See `tasilla_a1_certification_standard.md`)
3. **Quality over quantity.** 20 solid lessons beat 70 half-finished ones. Never ship templated filler content.
4. **Every screen has one job.** No screen tries to do two things.
5. **Progress must be visible and honest.** Students feel momentum; teachers see truth.
6. **Level is integral, never partial.** No skill advances to A2 until ALL 5 skills complete A1 (checkpoints + final exam). Fast students get A1 enrichment content, not early A2 access. This keeps the certificate simple and credible for employers.

---

## 3. Design system (approved — do not deviate)

### Colors

| Token | Dark | Light |
|---|---|---|
| Canvas | `#161618` | `#FAFAF8` |
| Surface | `#242426` | `#F0EEE8` |
| Border | `#2C2C2E` | `#E4E2DC` |
| Text | `#F5F5F0` | `#1A1A1A` |
| Muted | `#48484A` | `#AEAAA2` |

### Semantic colors — the only other colors allowed

| Color | Hex | Meaning |
|---|---|---|
| Green | `#34C759` | Correct · Done · Pass |
| Yellow | `#FFFC42` | Pending · In progress · Attention (text darkens to `#7A7200` on light) |
| Red | `#FF453A` | Wrong · Review · Overdue |

**Primary action:** white button on dark theme, black button on light theme. Never a colored button.

### Rules
- No decoration. Every pixel has a function.
- No purple, teal, blue, or per-skill colors. Removed permanently.
- Headings: `FontWeight.w300`, large, tight letter-spacing (-0.5)
- Section labels: 9px, `FontWeight.w600`, uppercase, letter-spacing ~1.6
- Progress bars: 2–3px thin lines, no rounded pill bars
- Status: small 6–8px dot indicators, not icon boxes
- Radius: 10–14px on cards, 8–10px on buttons
- Minimal AppBars: no elevation, muted small title

### Voice & tone
- Tagline: "Learn English with your teacher."
- Short, warm, direct copy. No exclamation marks in UI.

---

## 4. Tech stack

- **Flutter/Dart** — mobile + web from one codebase
- **Supabase** — auth, PostgreSQL, RLS, storage (free tier covers launch)
- **Vercel** — web hosting + domains (tasilla.app primary, tasilla.com redirects)
- **ElevenLabs** — TTS for lesson audio (free tier covers all A1 scripts)
- **GitHub** — repo; deploys auto via Vercel on push to main

### Project structure (lib/)
```
config/     — supabase config
data/       — content: a1_learning_experience_data.dart is the master content engine
models/     — data models (immutable, const constructors)
screens/    — student/, teacher/, activity screens (listening, reading, etc.)
services/   — auth, progress, assignments (all async, SharedPreferences local)
theme/      — app_theme.dart (TASILLA system), theme_controller.dart
widgets/    — shared UI components
```

### Code conventions
- Theme colors: hardcode the TASILLA palette per-screen via `isDark` check (current pattern) — later consolidate into AppTheme extensions
- Legacy aliases in AppTheme (brandRed, warning, success, info, accentPurple) exist for backwards compat — do not use in new code; use semantic names
- All progress stored via `LearningPathProgressService` (SharedPreferences now, Supabase later)
- Every screen refresh must call `_loadProgress()` after returning from navigation

---

## 5. Content architecture

**Master engine:** `a1_learning_experience_data.dart` generates 70 experiences from 40 core seeds.

```
4 UNITS, 12 cycles, ordered by unlock:
UNIT 1 Foundation      EXP 001–010  ← STRONG content, v1-ready
UNIT 2 Personal Life   EXP 011–020  ← STRONG content, v1-ready
UNIT 3 Everyday        EXP 021–030  ← needs content rewrite
UNIT 4 Independence    EXP 031–040  ← needs content rewrite
+ 18 reinforcement (templated — rewrite before exposing)
+ 6 reviews, 3 checkpoints, 2 portfolio tasks, 1 final exam
```

**Audio:** 19 scripts written in code, ~2,000 chars total. Files go in `assets/audio/a1/` with exact names from `tasilla_audio_checklist.md`. Path convention: `assets/audio/a1/a1_exp_0XX_topic.mp3`.

**Content quality bar:**
- Recurring characters (Anna, Lucas, Emma, Leo…) — keeps immersion
- Questions test English, never the app ("What is the minimum exam score?" = forbidden)
- 3–5 quiz questions per lesson (current: 1 — needs expansion)
- Every lesson maps to a CEFR can-do statement

---

## 6. Pricing model (freemium, fully self-service)

No sales team — every tier except Enterprise is self-service via Stripe Payment Links, live as of July 2026.

| | Free | Pro | Business | Business+ | Scale |
|---|---|---|---|---|---|
| Students | up to 3 | up to 25 | up to 100 | up to 500 | 501–1,000 |
| Teachers | 1 | 1 | up to 5 | up to 20 | up to 40 |
| Levels | A1 only | All | All | All | All |
| Certificates | $9 each (standalone) | Unlimited | Unlimited | Unlimited + batch verify | Unlimited + batch verify |
| Price | Free | $14/mo | $59/mo | $149/mo | $249/mo |

Over 1,000 students → Enterprise, hidden/manual (`hello@tasilla.com`), no button on the site.

**Current limitation:** the $9 standalone certificate and all subscriptions are fulfilled manually today — Stripe Payment Links work, but there's no webhook automatically unlocking access. Automating this requires Supabase live (v1.1) so a payment can be tied to a specific account.

## 7. Certification standard (summary)

Full spec: `tasilla_a1_certification_standard.md`

- All 4 skills gated independently at 70% — no averaging across skills
- 10 speaking + 10 writing submissions, all teacher-approved
- Checkpoints are hard gates
- Multi-format final exam (dictation, gap-fill, production) — 75% overall, every section ≥ 65%
- Teacher final sign-off required
- Certificate lists proven CEFR can-do statements + unique ID + verification link

---

## 8. Roadmap

### v1 — Launch (current focus)
- [x] Rename codebase to TASILLA
- [x] Design system in app_theme.dart
- [x] Login screen (approved dark + light)
- [x] Student home screen
- [~] All remaining screens restyled (bulk applied — visual review pending)
- [x] Generate 19→25 audio scripts written and improved (v2 checklist); 25 files generated via ElevenLabs API script
- [ ] Fix audio filename/transcript alignment (renames + transcript matching — in progress)
- [ ] Register audio assets in pubspec.yaml, verify player works
- [x] Landing page live at tasilla.com (teacher-first, pricing, certificate showcase)
- [x] Domains connected: tasilla.com (site), app.tasilla.com + tasilla.app (Flutter app)
- [x] Stripe payment links live for Pro/Business/Business+/Scale + standalone certificate
- [ ] Limit v1 to EXP 001–020 (hide templated reinforcements/units 3–4)
- [ ] Beta with 3–5 real students (demo mode is fine)

### v1.0.5 — Assessment engine (NEW — prerequisite, found July 2026)
Discovered that quizzes render as read-only text today; "Complete" buttons mark steps done unconditionally with no scoring. This must be built before selling certificates carries integrity. See `tasilla_a1_certification_standard.md` section 8 for full detail.
- [ ] Interactive quiz: tappable options, right/wrong feedback (green/red), score calculation
- [ ] Score-gated completion (70% per skill minimum, per certification standard)
- [ ] Real audio playback in the listening section (currently hardcoded "Audio pending generation" regardless of file existence)
- [ ] Wire the 5 Skill Paths (Listening/Speaking/Reading/Vocabulary/Grammar) to their real data files — currently falls back to a placeholder for all of them

### v1.1 — Trust
- [ ] Supabase live (auth, progress, assignments)
- [ ] Teacher review flow for speaking/writing submissions
- [ ] Audio recording for speaking tasks
- [ ] Automated in-app certificate paywall ($9 standalone / unlimited on paid plans) via Stripe webhook — today's Payment Links are manual-fulfillment only

### v1.2 — Content depth
- [ ] Rewrite EXP 021–040 to the Unit 1–2 quality bar
- [ ] Write the ~130 missing Skill Path exercises (see `tasilla_a1_content_completion_roadmap.md`): Listening +11, Speaking +16, Reading +15, Vocabulary +11, Grammar +7
- [ ] Replace templated quiz questions in 18 reinforcements, 6 reviews, 3 checkpoints, and the final exam with real English-testing content
- [ ] Multi-format final exam (dictation, gap-fill, production)

### v2 — Reference standard
- [ ] Full certification standard implementation
- [ ] Certificate with ID + public verification page
- [ ] Onboarding flow, A2 track

### Backlog / ideas
- Identity messaging on login (teacher/school connection)
- Logo (bookmark concept explored — revisit later)
- Push notifications for homework
- App stores (web-first for now)
- Local pricing power parity (Stripe) for different markets
- Trial period for Pro before falling back to Free
- Multi-language support (Portuguese, Spanish, etc.) — same platform, new content tracks; revisit when English A1→B2 is complete

---

## 9. Working agreements

- **Design changes:** propose → visualize → approve → then code. Never code unapproved design.
- **Content changes:** must pass the quality bar in section 5.
- **Claude Code (terminal)** executes on files; **Claude (chat)** decides direction, architecture, and design.
- Before any release: `flutter analyze` clean + visual review of both themes.
- Screenshots of both dark and light for every new screen.

---

*Last updated: July 2026 — added pricing model, level progression policy (integral, not per-skill), multi-language vision note, assessment engine gap (v1.0.5), and review cadence documentation.*

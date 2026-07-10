# TASILLA — A1 Certification Standard

**Purpose:** Make the TASILLA A1 certificate a trustworthy reference for employers and schools — a credential that proves real, internationally-aligned CEFR A1 competence, not just app completion.

**Core principle:**
> The TASILLA A1 certificate is issued only when a learner demonstrates, across all four skills, the CEFR A1 can-do statements — with speaking and writing validated by a human teacher, and a multi-format final exam that cannot be passed by guessing.

---

## 1. The four-skill rule (non-negotiable)

CEFR A1 requires minimum competence in **all four skills**. A high reading score can never compensate for weak speaking. Each skill is measured and gated separately.

| Skill | How it is measured | Minimum to pass |
|---|---|---|
| Listening | Audio comprehension + dictation | 70% |
| Reading | Short-text comprehension | 70% |
| Speaking | Recorded tasks, **teacher-graded** | 70% + teacher approval |
| Writing | Short written tasks, **teacher-graded** | 70% + teacher approval |

**Rule:** every skill must independently clear its minimum. No overall average can rescue a failing skill.

---

## 2. Human validation (the TASILLA differentiator)

Multiple-choice can never prove someone *speaks* English. This is what separates TASILLA from automated-certificate apps.

- **Speaking:** at least 10 recorded submissions across the track, each reviewed by the teacher. Teacher marks each pass / needs-redo. Final speaking checkpoint must be teacher-approved.
- **Writing:** at least 10 written submissions, teacher-reviewed, same pass / redo flow.
- The teacher is the final gatekeeper of the certificate. The app prepares the evidence; the teacher signs off.

---

## 3. Progression & unlock logic

Difficulty rises in four units. Each step unlocks only when the previous is completed.

```
UNIT 1 — Foundation        EXP 001–010   (greetings, personal info, countries, numbers)
   └─ Review 1  →  Checkpoint 1 (gate: must pass to continue)
UNIT 2 — Personal Life     EXP 011–020   (family, describing people, likes, routine)
   └─ Review 2–3  →  Checkpoint 2 (gate)
   └─ Portfolio Task 1 (teacher-graded speaking + writing)
UNIT 3 — Everyday          EXP 021–030   (time/days, places, shopping, classroom)
   └─ Review 4–5  →  Checkpoint 3 (gate)
UNIT 4 — Independence      EXP 031–040   (work/study, messages, integration)
   └─ Review 6
   └─ Portfolio Task 2 (teacher-graded speaking + writing)
        ↓
   FINAL EXAM (multi-format, supervised)
        ↓
   CERTIFICATE (only if ALL gates below are met)
```

**Checkpoints are hard gates** — a weak checkpoint blocks progression until redone. This guarantees no one reaches the exam without the foundations.

---

## 4. Final exam — guessing-proof

A 3-option multiple-choice test passed at 75% leaves too much room for luck. The A1 final exam mixes formats so it tests production, not recognition:

- Listening comprehension (multiple choice + **dictation**)
- Reading comprehension
- **Sentence ordering / gap-fill** (no options to guess from)
- **Short writing task** (teacher-graded)
- **Short speaking task** (teacher-graded)

**Anti-fraud measures:**
- Single supervised session, timestamped
- Limited attempts (not infinite retries)
- Speaking/writing portions tied to the learner's verified submissions

**Pass mark: 75% overall AND every section ≥ 65%.**

---

## 5. Updated certificate criteria

| Criterion | Current | New standard |
|---|---|---|
| Completion rate | 90% | 90% |
| Overall average | 75% | 75% |
| Final exam score | 75% | 75% + every section ≥ 65% |
| **Minimum per skill** | 65% | **70% — all four, independently** |
| Speaking submissions | 10 | 10, **all teacher-approved** |
| Writing submissions | 10 | 10, **all teacher-approved** |
| All reviews completed | yes | yes |
| All checkpoints completed | yes | yes (hard gates) |
| **Portfolio tasks** | — | **2, teacher-approved** |
| **Teacher final sign-off** | — | **required** |

---

## 6. What the certificate states (CEFR mapping)

The certificate explicitly lists the CEFR A1 can-do statements the learner has proven. This is the credibility layer for employers — they see exactly what the holder can do.

The learner can:
1. Introduce themselves and recognize basic greetings
2. Share and understand simple personal information
3. Talk about family and people using simple language
4. Describe basic daily routines
5. Use numbers, time and days in simple contexts
6. Express likes, dislikes and preferences
7. Identify places in town and simple directions
8. Follow classroom instructions and learning language
9. Handle simple shopping and ordering situations
10. Talk simply about work and study
11. Understand and write short messages and notices
12. Integrate core A1 skills in familiar situations

Each statement is mapped to the specific lessons, checkpoints and exam sections that prove it.

---

## 7. Certificate metadata (for employer verification)

To be a reference standard, each certificate should carry:
- Unique certificate ID
- Learner name + verified identity
- Issue date
- Issuing teacher name + signature
- Per-skill scores (listening / reading / speaking / writing)
- Final exam score
- CEFR alignment statement
- A public verification link (employer can confirm authenticity)

---

## Implementation priority

1. Enforce the four-skill independent gate (70% each) in the certificate logic
2. Build the teacher sign-off flow for speaking/writing submissions
3. Rebuild the final exam as multi-format (add dictation, gap-fill, production)
4. Add the CEFR can-do mapping to the certificate output
5. Add certificate ID + verification metadata
6. (Later) public verification page for employers

---

## 8. Critical engineering gap found (July 2026) — the standard has no engine yet

Auditing the live code (`student_learning_step_screen.dart`) revealed that **none of the above is enforceable today**. This section documents the gap so it isn't lost before implementation.

**What actually happens right now, for every lesson/reinforcement/review/checkpoint/portfolio/final-test in the A1 Roadmap:**
- Content (objective, vocabulary, grammar, listening script, reading text, quiz questions, writing/speaking prompts, rubric) renders as **read-only text**.
- Quiz questions display as static text with non-interactive option chips — no tap handler, no selection state, no correct/incorrect feedback.
- A single button ("Complete Review", "Complete Checkpoint", etc.) calls `markStepCompleted(id)` **unconditionally** — it does not check any answer, compute any score, or gate on performance in any way.
- The listening section always displays the hardcoded text "Audio pending generation" regardless of whether the MP3 file actually exists — the 25 real ElevenLabs audio files generated in July 2026 do not play anywhere in this screen today.
- The 5 separate Skill Paths (Listening/Speaking/Reading/Vocabulary/Grammar, each 12 lessons + 4 reviews + 1 final test) don't resolve to any experience object at all — they fall back to a hardcoded placeholder: *"Development activity placeholder. Real questions, audio, recording or reading content will be connected to this step later."* The existing skill-specific data files (`listening_data.dart`, `vocabulary_data.dart`, etc.) are not wired into this screen.

**Consequence:** a student can open any checkpoint — including certificate-gating ones — without reading anything, and mark it complete. As written today, the certificate has no assessment engine behind it, independent of how good the question content is.

**This makes the assessment engine a prerequisite, not a parallel task, to selling certificates.** Priority order:

1. **Interactive quiz** — tappable options, immediate right/wrong feedback using the semantic colors (green/red), score calculation per attempt
2. **Score-gated completion** — a step only marks complete when the student's score meets the required threshold (70% per skill, per this standard); failing returns the student to retry, not a free pass
3. **Real audio playback** — the listening section must play the actual file at `audioPath` (with the file-existence check already identified in the audio alignment work) instead of showing a static "pending" message
4. **Wire the 5 Skill Paths to real content** — connect `listening_data.dart`, `vocabulary_data.dart`, `reading_data.dart`, `speaking_data.dart`, `homework_data.dart` to the step screen so these paths stop falling back to the placeholder
5. Only after 1–4 exist does writing the 130 missing exercises (per the Content Completion Roadmap) translate into a real, gated, certifiable course

---

## 9. Review cadence — two different rhythms today

Two systems exist, with two different review rhythms. Documenting both so content writing matches the right cadence per system.

**A1 Roadmap (the main 70-step track):** reviews are NOT every 3 lessons. The real rhythm from `_buildA1LearningExperiences()`:
```
Lessons 1–10   → 4 reinforcements → Review 1 → Checkpoint 1
Lessons 11–20  → 5 reinforcements → Review 2
Lessons 21–30  → 5 reinforcements → Review 3 → Checkpoint 2
Lessons 31–40  → 4 reinforcements → Reviews 4, 5, 6 → Checkpoint 3 → 2 Portfolios → Final Exam
```
Roughly one review per 10 lessons, not per 3.

**The 5 Skill Paths (Listening/Speaking/Reading/Vocabulary/Grammar):** this is where the "every 3 lessons, one review of the previous 3" pattern actually lives, from `_buildSkillPath()`:
```
Lesson 1, 2, 3   → Review (covers lessons 1–3)
Lesson 4, 5, 6   → Review (covers lessons 4–6)
Lesson 7, 8, 9   → Review (covers lessons 7–9)
Lesson 10, 11, 12 → Review (covers lessons 10–12)
→ Final Test
```
**Caveat:** today this is only a scheduling pattern — the review's title is templated ("Review lessons 1 to 3") but no logic actually pulls the specific vocabulary/grammar from those 3 lessons into the review's content. The Content Completion Roadmap's per-skill review rows were written by hand to match this cadence; the code does not do this automatically. If a real content-linking mechanism is ever built, it should still follow this same 3-lesson rhythm to stay consistent with what's already scheduled.

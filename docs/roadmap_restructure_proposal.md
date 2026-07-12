# TASILLA — Roadmap Restructure Proposal

**Status:** Proposal. Nothing coded until approved (per working agreement: propose → approve → code).

**Decisions already made (by you):**
- One lesson = one skill. Not all-in-one.
- 5 skills per topic: Vocabulary, Grammar, Listening, Speaking, Reading.
- Mixed cross-skill review every 3 topics (roadmap only).
- Skill Paths and Roadmap are two routes through the SAME lessons. Completing a
  lesson in either marks it complete in both (same `learning_step_id`).

---

## 1. Key finding: Units 3–4 already do this

Auditing the current 40 core experiences, Units 3 and 4 ALREADY follow clean
5-skill topic cycles:

| Topic | Speaking | Vocab | Listening | Reading | Writing |
|---|---|---|---|---|---|
| Café / Ordering | 21 Order a Drink | 22 Cafe Vocabulary | 23 Prices and Numbers | 24 Read a Menu | 25 Short Order Message |
| Directions / Places | 26 Ask for Directions | 27 Places in Town | 28 Travel Information | 29 Signs and Notices | 30 Write Simple Directions |
| Work / Study | 31 Work and Study | 32 Jobs and Study Words | 33 Work/Study Conversations | 34 Short Messages | 35 Write a Short Message |

**Units 1–2 do NOT.** They have repeated skills, no clean topic cycles, and three
`mixed` experiences (10 Foundation Challenge, 18 My Life Story, 20 Personal Life
Challenge).

**Implication:** this is not a ground-up restructure. It is (a) reshaping Units 1–2
to match the pattern Units 3–4 already use, and (b) making the lesson screen render
only the primary skill instead of everything.

**Note on the 5th skill:** the current data uses `writing` as the 5th slot, not
`grammar`. The proposal below keeps Writing as a lesson skill (it is one of the four
CEFR-gated skills and needs 10 teacher-reviewed submissions per the standard).
Grammar is treated as embedded in the Vocabulary/Use-of-English lesson, which matches
the existing `vocabularyUseOfEnglish` enum. **If you want Grammar as its own 6th
lesson per topic, say so — it changes counts below.**

---

## 2. Proposed A1 structure

**8 topics × 5 skill-lessons = 40 core lessons** (same count as today — no content lost)

| Unit | Topic | The 5 lessons (Speaking / Vocab / Listening / Reading / Writing) |
|---|---|---|
| **1 — Foundation** | 1. Introductions | Introducing Yourself · Greetings & Basic Words · Meeting Anna · Personal Information · My Basic Profile |
| | 2. Identity | Simple Conversation · Countries & Nationalities · Numbers and Age · Mini Profile Reading · Write About Yourself |
| **2 — Personal Life** | 3. People | Describing People · My Family · Talking About Someone · People Around Me · Describe a Person |
| | 4. Routine | Things I Like · Simple Present Questions · My Daily Routine · Days and Time · My Activities |
| **3 — Everyday** | 5. Café / Ordering | Order a Drink · Cafe Vocabulary · Prices and Numbers · Read a Menu · Short Order Message |
| | 6. Places | Ask for Directions · Places in Town · Travel Information · Signs and Notices · Write Simple Directions |
| **4 — Independence** | 7. Work / Study | Work and Study · Jobs and Study Words · Work/Study Conversations · Short Messages · Write a Short Message |
| | 8. Integration | A1 Presentation Prep · A1 Grammar Patterns · A1 Conversation Listening · Make Simple Arrangements · Final Written Profile |

**Every topic runs the same cycle:** Vocabulary → Grammar-in-context → Listening →
Speaking → Reading → Writing, ordered so receptive skills precede productive ones.

### Where the mixed reviews go (every 3 topics)

```
Topics 1–3  → MIXED REVIEW A  (cross-skill, covers introductions/identity/people)
Topics 4–6  → MIXED REVIEW B  (cross-skill, covers routine/café/places)
Topics 7–8  → MIXED REVIEW C  (cross-skill, covers work/study/integration)
```

3 mixed reviews. Each pulls vocabulary, grammar, listening and reading from its
3-topic block into one integrated assessment — testing *use*, not recall.

### The three `mixed` experiences that exist today

10 Foundation Challenge, 18 My Life Story, 20 Personal Life Challenge become the
**mixed reviews**. They are already integrative by design — this is what they were
for. No content wasted; they just move to their correct structural role.

---

## 3. Full roadmap sequence (A1)

```
UNIT 1 — Foundation
  Topic 1: Introductions      (5 lessons)
  Topic 2: Identity           (5 lessons)
  Topic 3: People             (5 lessons)
  → MIXED REVIEW A
  → CHECKPOINT 1              (hard gate — per certification standard §3)

UNIT 2 — Personal Life
  Topic 4: Routine            (5 lessons)
  Topic 5: Café / Ordering    (5 lessons)
  Topic 6: Places             (5 lessons)
  → MIXED REVIEW B
  → CHECKPOINT 2              (hard gate)
  → PORTFOLIO TASK 1          (teacher-graded speaking + writing)

UNIT 3 — Independence
  Topic 7: Work / Study       (5 lessons)
  Topic 8: Integration        (5 lessons)
  → MIXED REVIEW C
  → CHECKPOINT 3              (hard gate)
  → PORTFOLIO TASK 2          (teacher-graded speaking + writing)

  → FINAL EXAM                (multi-format, supervised)
  → CERTIFICATE
```

**Totals:** 40 core lessons + 3 mixed reviews + 3 checkpoints + 2 portfolios + 1 final
exam = **49 roadmap steps**.

Today it is 70 steps (40 core + 18 reinforcements + 6 reviews + 3 checkpoints + 2
portfolios + 1 final exam). **The 18 reinforcements are the difference.**

### What happens to the 18 reinforcements?

Two options — **needs your call:**

**(a) Drop them from the roadmap.** They become optional extra practice, surfaced in
the Skill Paths instead. Roadmap = 49 steps, tighter, every step is a real lesson.

**(b) Keep them, one per topic.** 8 reinforcements (one after each topic's 5 lessons),
dropping from 18 to 8. Roadmap = 57 steps. Preserves the "smart reinforcement" idea
without bloating.

I lean **(b)** — a short reinforcement after each topic cycle reinforces before moving
on, and the roadmap header already advertises "smart reinforcement" as a feature.

---

## 4. Skill Paths after this change

Each skill path is simply **its skill's lessons, in topic order**:

- **Vocabulary path:** the 8 vocabulary lessons (one per topic) + reviews every 3
- **Listening path:** the 8 listening lessons + reviews every 3
- **Speaking / Reading / Writing:** same shape

**This kills the current duplication.** Today `listening_data.dart`,
`vocabulary_data.dart` etc. hold SEPARATE content that is unwired and shows a
placeholder. Under this proposal they are deleted — the skill paths read from the same
`a1LearningExperiences` list, filtered by `primarySkill`. One source of truth.

**Completion is shared automatically.** Because both routes use the same
`learning_step_id`, finishing "Listening: Café" in the Listening path marks it done in
the roadmap too. No sync logic needed — it falls out of the existing
`student_step_progress` table design.

**Skill-path reviews stay per-skill and every-3-lessons**, exactly as the certification
standard §9 describes. The roadmap's mixed reviews are additional and roadmap-only.

---

## 5. What changes in the code

| Area | Change |
|---|---|
| `student_learning_step_screen.dart` | Render ONLY the primary skill's blocks. A listening lesson shows vocabulary + grammar + listening + its questions — not reading/writing/speaking too. |
| `a1_learning_experience_data.dart` | Reorder Units 1–2 into topic cycles. Retag the 3 `mixed` experiences as reviews. Remove auto-generated listening/reading questions from non-primary skills. |
| `learning_path_data.dart` | Build roadmap steps as: topic cycles → mixed review every 3 topics → checkpoints/portfolios/exam. |
| Skill path builders | Filter `a1LearningExperiences` by `primarySkill` instead of reading the separate `*_data.dart` files. |
| `listening_data.dart`, `vocabulary_data.dart`, `reading_data.dart`, `speaking_data.dart`, `homework_data.dart` | **Delete.** Superseded — these are the unwired placeholder files. |

---

## 6. The content bug this fixes

Today, EXP-001 (a *speaking* lesson) auto-generates a listening question
("What is the main idea?" → Anna/Maria/Julia) and a reading question ("What does the
text help the student understand?" → Anna/Maria/Julia) — **and the reading text is
about Lucas, who isn't even an option.** The question is unanswerable.

This happens because `_listeningBlockFor()` and `_readingBlockFor()` mechanically
generate questions from the seed's `checkOptions` regardless of relevance.

Under single-skill lessons, **a speaking lesson has no listening or reading questions
at all** — the bug disappears structurally, not by patching the generator.

**This is why the restructure must land before score-gating (Step 4 of the assessment
engine).** Gating on unanswerable questions would lock every student out of lesson 1.

---

## 7. Open questions for you

1. **Grammar:** its own 6th lesson per topic, or embedded in the Vocabulary lesson as
   today? (Proposal assumes embedded; a 6th lesson makes it 48 core lessons.)
2. **Reinforcements:** drop entirely (a), or 8 — one per topic (b)? (I lean b.)
3. **Writing as a skill lesson:** kept as the 5th skill above. Confirm — or should
   Writing only appear in portfolio tasks?

Answer those three and I will write the implementation spec.

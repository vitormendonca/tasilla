# Spec — Single-Skill Lesson Rendering

**Goal:** a lesson renders ONLY the content for its own skill. A speaking lesson shows no
listening questions. A reading lesson shows no speaking task.

**Why now:** this must land BEFORE score-gating (assessment engine Step 4). Today EXP-001
(a *speaking* lesson) auto-generates a reading question whose text is about **Lucas** but
whose only options are **Anna / Maria / Julia** — the correct answer is not present. Turn
on gating against that and every student is permanently locked out of lesson 1.

**Scope:** rendering + question generation only. This does NOT restructure content into the
new 20-topic grid (separate, larger job). It makes the CURRENT 40 lessons render correctly.

---

## 1. The bug, precisely

`student_learning_step_screen.dart`, `_experienceContent()` (~line 138) builds its section
list from *what blocks exist on the experience*, never from `primarySkill`:

```dart
if (experience.listeningBlock != null)  _listeningSection(...),
if (experience.readingBlock != null)    _textSection(...),
if (experience.quizBlock != null)       _questionsSection(...),
if (experience.writingTask != null)     _writingSection(...),
if (experience.speakingTask != null)    _speakingSection(...),
```

And `a1_learning_experience_data.dart` **auto-generates** listening and reading blocks for
experiences that never should have had them — `_listeningBlockFor()` and `_readingBlockFor()`
mechanically build questions from the seed's `checkOptions`, regardless of whether that seed
is even a listening or reading lesson.

Result: a speaking lesson gets a listening block ("What is the main idea?" → Anna/Maria/Julia)
and a reading block whose question is unanswerable.

**Two fixes are needed. Fixing only the screen leaves garbage in the data; fixing only the
data leaves the screen willing to render garbage if it reappears.**

---

## 2. Fix A — data layer: stop generating foreign-skill blocks

In `a1_learning_experience_data.dart`:

- `_listeningBlockFor(seed)` returns a `ListeningBlock` **only if** the seed's
  `primarySkill == LearningSkill.listening` **or** the seed explicitly provides an
  `audioScript`. Otherwise return `null`.
- `_readingBlockFor(seed)` returns a `ReadingBlock` **only if** the seed's
  `primarySkill == LearningSkill.reading` **or** the seed explicitly provides a
  `readingText`. Otherwise return `null`.

**Rationale for the "or explicitly provides" clause:** a few lessons legitimately carry
supporting content outside their primary skill (e.g. EXP-034 Short Messages is a *reading*
lesson that also has a real, hand-written audio script). Explicit content is intentional;
*generated* content is the bug. Keep the former, kill the latter.

**Also:** the auto-generated `listeningQuestions` / `readingQuestions` (built from
`checkOptions`) should only be generated when the block itself is legitimate. When a lesson
has an explicit script/text but is not that skill's lesson, render the content WITHOUT
auto-generated questions — supporting material, not assessment.

---

## 3. Fix B — screen layer: render by primary skill

In `student_learning_step_screen.dart`, `_experienceContent()`:

Sections split into **always shown** and **skill-gated**:

**Always shown (context for any lesson):**
- Objective (`canDoStatement`)
- Start / introduction text
- Vocabulary blocks — *supporting: you can't read a menu without knowing "price"*
- Grammar blocks — *supporting: recognition only. Grammar is TAUGHT in the grammar track.*

**Skill-gated (shown only when it matches `experience.primarySkill`):**

| primarySkill | Show |
|---|---|
| `listening` | listening block + its questions |
| `reading` | reading block + its questions |
| `speaking` | speaking task + rubric |
| `writing` | writing task + rubric |
| `vocabularyUseOfEnglish` | quiz block (the vocab/use-of-English questions) |
| `mixed` | **everything** — reviews/checkpoints/exams are integrative by design |

**Important:** `mixed` must keep rendering all blocks. The mixed reviews, checkpoints,
portfolio tasks and final exam are *supposed* to be cross-skill. Do not gate them.

**The quiz block:** currently every experience has one. Under this change it renders for
`vocabularyUseOfEnglish` and `mixed` lessons. For other skills, that skill's own questions
(listening questions, reading questions) serve as the assessment instead.

---

## 4. Suggested implementation

```dart
Widget _experienceContent(BuildContext context, LearningExperience experience, {...}) {
  final skill = experience.primarySkill;
  final isMixed = skill == LearningSkill.mixed;

  bool shows(LearningSkill s) => isMixed || skill == s;

  final sections = <Widget>[
    _textSection('Objective', experience.canDoStatement, ...),
    if (experience.introductionText.trim().isNotEmpty)
      _textSection('Start', experience.introductionText, ...),

    // Always: supporting context
    if (experience.vocabularyBlocks.isNotEmpty)
      _vocabularySection(experience.vocabularyBlocks, ...),
    if (experience.grammarBlocks.isNotEmpty)
      _grammarSection(experience.grammarBlocks, ...),

    // Skill-gated
    if (experience.listeningBlock != null && shows(LearningSkill.listening))
      _listeningSection(experience.listeningBlock!, ...),
    if (experience.readingBlock != null && shows(LearningSkill.reading))
      _readingSection(experience.readingBlock!, ...),
    if ((experience.quizBlock?.questions.isNotEmpty ?? false)
        && shows(LearningSkill.vocabularyUseOfEnglish))
      _questionsSection(experience.quizBlock!, ...),
    if (experience.writingTask != null && shows(LearningSkill.writing))
      _writingSection(experience.writingTask!, ...),
    if (experience.speakingTask != null && shows(LearningSkill.speaking))
      _speakingSection(experience.speakingTask!, ...),

    if ((experience.rubric?.criteria.isNotEmpty ?? false)
        && (shows(LearningSkill.writing) || shows(LearningSkill.speaking)))
      _rubricSection(experience.rubric!, ...),
  ];
  ...
}
```

**Note:** an experience may still *carry* supporting content outside its skill (EXP-034's
audio script). Under this change that content is not rendered on the lesson screen — it
belongs to a different skill's lesson. When content is restructured into the 20-topic grid,
that script moves to the listening lesson for its topic. **Flag any such orphaned content
during implementation rather than silently dropping it.**

---

## 5. Interaction with the assessment engine

The engine (Steps 1–3, already built) aggregates scores across `_sectionResults` keyed
`'quiz'`, `'listening'`, `'reading'`. After this change, a given lesson populates **at most
one** of those keys (except `mixed`, which may populate several).

That is correct and desirable: it is exactly what makes the certification standard's
"four skills gated independently, never averaged" rule fall out naturally rather than
needing to be engineered.

**Step 4's `totalQuestions == 0` edge case becomes load-bearing:** speaking and writing
lessons now have NO auto-gradable questions at all. They must not be blocked by the score
gate — they gate on teacher approval instead. Verify this path explicitly.

---

## 6. Verification

After implementing, check in the running app:

| Lesson | Expect |
|---|---|
| EXP-001 Introducing Yourself (`speaking`) | Objective, vocabulary, grammar, **speaking task + rubric**. NO listening block. NO reading block. NO quiz. |
| EXP-002 Greetings (`listening`) | Objective, vocab, grammar, **listening block + its questions**. Nothing else. |
| EXP-005 Personal Information (`reading`) | **Reading text + reading questions**. No speaking/writing. |
| EXP-006 Asking Basic Questions (`vocabularyUseOfEnglish`) | **Quiz block**. No listening/reading blocks. |
| EXP-010 Foundation Challenge (`mixed`) | **Everything** — this one is integrative by design. |
| Final Exam (`mixed`) | **Everything**, including the 5 English questions + listening + dictation. |

**The specific bug is fixed when:** EXP-001 no longer shows "What does the text help the
student understand? → Anna / Maria / Julia" — because it no longer shows a reading section
at all.

---

## 7. Out of scope

- Restructuring content into the 20-topic × 6-skill grid (separate, much larger job)
- Writing new lessons
- Real review logic
- Skill path wiring
- Writing upload (Mode B)

This spec makes the CURRENT content render correctly so the score gate can be switched on
safely. Nothing more.

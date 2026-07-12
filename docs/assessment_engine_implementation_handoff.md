# Assessment Engine — Implementation Handoff for Claude Code

**Companion to:** `tasilla_assessment_engine_spec.md` (the full spec). Read that first.
This file is the sequenced build order and the deltas now that Supabase is live.

**Context that changed since the spec was written:**
- Supabase is now live and configured. The `student_step_progress` table exists
  **with the `score numeric(4,3)` column already created** — so §5's flagged
  blocker ("confirm the score column exists") is RESOLVED. No DB migration needed.
- Student login now creates a real Supabase session (via derived access-code
  credentials). So `SupabaseBootstrap.client` is non-null and authenticated for a
  logged-in student, meaning RLS-protected writes to `student_step_progress` will
  succeed. The persistence half of the engine can be tested for real.

**The target file is unchanged from the spec's assumptions (verified against the
current pushed HEAD):**
- `lib/screens/student/student_learning_step_screen.dart`
  - `_completeStep()` (currently ~line 29) still calls `markStepCompleted`
    unconditionally with no score check.
  - `_questionsSection()` (currently ~line 251) still renders options as static
    `Wrap` chips with no `onTap`.
  - `_listeningSection()` (currently ~line 228) renders listening content; its
    questions also need interactivity.

---

## Build order (verify `flutter analyze` clean between each step)

### Step 1 — `InteractiveQuizSection` widget (isolated, testable)
Create `lib/widgets/interactive_quiz_section.dart` exactly per spec §3.
- Stateful. Holds `Map<String,String> selectedAnswers`.
- Only `QuestionType.multipleChoice` gets tap handling; other types render as
  static text with a muted "not yet interactive" note (do NOT fake-grade them).
- Tap → lock answer → green if `== correctAnswer`, red if not (and reveal the
  correct one in green). Show `explanations[question.id]` if present.
- Fire `onResultChanged(QuizSectionResult)` after every tap.
- Use only `AppTheme.semanticGreen` / `AppTheme.semanticRed`. No new colors.

Add its unit/widget tests (spec §7) before wiring it in.

### Step 2 — Wire it into the quiz block only
In `student_learning_step_screen.dart`, replace the body of `_questionsSection`
with an `InteractiveQuizSection`. Store its result in
`_sectionResults['quiz']`. Leave listening/reading untouched this step.

### Step 3 — Extend to listening + reading questions
Same widget, keyed `_sectionResults['listening']` and `_sectionResults['reading']`.
Give each a distinct `ValueKey` so attempts reset independently.

### Step 4 — Score gate in `_completeStep`
Per spec §4:
- Add `_combinedScore` and `_allSectionsAnswered` getters.
- Edge case: `totalQuestions == 0` → treat as pass (writing/speaking-only steps
  gate on teacher review, not this engine).
- If not all answered → inline "answer all questions first", do not proceed.
- If `_combinedScore < threshold` (threshold = `experience.passingScore ??
  widget.step.passingScore`) → set `_attemptedAndFailed`, show retry UI, do NOT
  call `markStepCompleted`.
- If pass → `recordStepAttempt(passed: true)` then `markStepCompleted`.
- Retry UI resets via an incrementing attempt counter feeding the widget Key.
- Record failed attempts too (`passed: false`) for history.

### Step 5 — Persistence
Add `recordStepAttempt` to `learning_path_progress_service.dart` per spec §5.
Because Supabase is live, TEST this for real:
- Log in as `test-student-2`, pass a quiz, then check Supabase Table Editor →
  `student_step_progress` → the row should have the real `score` value.
- Fail a quiz → row status `review_needed`, score below threshold, step NOT
  marked complete in the roadmap.

### Step 6 — Manual verification matrix
- A lesson, pass path → completes, score saved.
- A lesson, fail-then-retry path → blocked, then completes after passing.
- A checkpoint → same gate applies (no special-casing; same `_completeStep`).
- A writing/speaking-only step → not blocked by scoring (no questions present).

---

## Explicitly OUT of scope (do not touch in this work)
- Real audio playback (still shows script text; separate spec).
- Wiring the 5 Skill Paths to their data files (separate work).
- Teacher review flow for writing/speaking submissions (separate spec).
- Any content authoring (new questions/scripts).

## Commit guidance
Commit per logical step, not one giant commit. Suggested messages:
- "add InteractiveQuizSection widget with tap-to-answer feedback"
- "wire interactive quiz into learning step screen"
- "score-gate step completion against passingScore"
- "persist per-step scores to Supabase student_step_progress"

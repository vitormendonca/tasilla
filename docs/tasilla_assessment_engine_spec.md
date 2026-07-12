# TASILLA — Assessment Engine Spec (v1.0.5, phase 1)

**Scope:** Steps 1–3 of the priority order in `tasilla_a1_certification_standard.md` §8:
1. Interactive quiz (tap, immediate feedback, score calculation)
2. Score-gated completion (retry instead of free pass)
3. Persist real scores (extend existing Supabase wiring)

**Explicitly out of scope for this pass** (tracked separately, do not touch here):
- Real audio playback (`audioPath` file-existence check + player) — depends on the audio filename/transcript alignment work already in progress
- Wiring the 5 Skill Paths to `listening_data.dart` / `vocabulary_data.dart` / `reading_data.dart` / `speaking_data.dart` / `homework_data.dart`
- Any new content (quiz questions, audio scripts) — this spec only changes how existing content is rendered and scored

**Repo state this spec was written against:** `github.com/vitormendonca/tasilla`, `main`, as pulled 2026-07-09.

---

## 1. Why this is a narrower gap than it looks

The model layer is already ahead of the UI, so this is not "build an assessment engine from zero":

- `LearningExperience` already has `passingScore` (default `0.75`), `attempts`, `completed`, `needsReview` (`lib/models/learning_experience.dart`)
- `LearningPathStep` already has `passingScore` (default `0.75`) (`lib/models/learning_path_step.dart`)
- `ActivityQuestion` already has a `correctAnswer` field and models `multipleChoice`, `textInput`, `trueFalse`, `dictation`, `fillBlank`, `reorderSentence` (`lib/models/activity_question.dart`) — only `multipleChoice` needs handling for this phase; the others render no differently today and can stay inert until their content exists
- `QuizBlock.explanations` (`Map<String, String>` keyed by question id) already exists for post-answer feedback text — reuse it, don't add a new field
- `ActivityStatus` enum already models `pending / inProgress / completed / reviewNeeded / submitted / approved / rejected / locked` with a `countsAsCompleted` getter — reuse this for the writing/speaking review flow, don't invent new states
- `LearningPathProgressService` already talks to Supabase (`student_step_progress` table, with local `SharedPreferences` fallback) and already has `recordLevelCheckAttempt(level, score, passed, answers)` — the pattern to extend already exists, it's just scoped to level checks only

**What's actually missing:** the UI never asks a question interactively, never computes a score, and never checks one against `passingScore` before calling `markStepCompleted`.

---

## 2. The core rule (from the certification standard, §1 and §3)

- Auto-gradable skills (listening, reading, vocabulary/use-of-English via multiple choice): **70% to pass**, computed per experience from its own questions (quizBlock + listeningBlock.listeningQuestions + readingBlock.readingQuestions combined)
- Writing and speaking tasks: **never auto-graded**. Submitting sets status to `submitted`; only a teacher action (existing/future teacher review flow, not in this spec) can move it to `approved`. A step whose only tasks are writing/speaking should not be blocked by this engine's scoring — it should be blocked by teacher approval, which is separately modeled via `ActivityStatus`
- Checkpoints are **hard gates** (§3): the checkpoint experience's own quiz score must clear `passingScore`, exactly like a lesson, before `markStepCompleted` is allowed
- Mixed experiences (reviews, the foundation challenge, final exam) with both auto-gradable questions and writing/speaking tasks: the auto-gradable portion gates the "practice" completion; the teacher-reviewed portion gates certificate eligibility separately (already modeled by `requiresTeacherReview` on `LearningExperience`) — **do not conflate the two** in this phase. This spec only makes the auto-gradable half real.

---

## 3. New widget: `InteractiveQuizSection`

**File:** `lib/widgets/interactive_quiz_section.dart` (new)

Replaces the static rendering currently done by `_questionsSection`, `_listeningSection`'s question part, and the reading question part in `student_learning_step_screen.dart`. One reusable stateful widget, since the same tap/lock/feedback pattern is needed in three places today and will be needed again for the Skill Paths later.

### Props
```dart
class InteractiveQuizSection extends StatefulWidget {
  final String sectionTitle;           // 'Questions' / 'Listening comprehension' / 'Reading comprehension'
  final List<ActivityQuestion> questions;
  final Map<String, String> explanations; // from QuizBlock.explanations, empty map if none
  final ValueChanged<QuizSectionResult> onResultChanged;
  // called on every answer change, not just at the end — see §4
}

class QuizSectionResult {
  final int answeredCount;
  final int correctCount;
  final int totalCount;
  final bool allAnswered;
  const QuizSectionResult({...});
  double get score => totalCount == 0 ? 0 : correctCount / totalCount;
}
```

### Behavior
- Only `QuestionType.multipleChoice` gets tap handling this phase. Other types render their prompt + options as plain text (current behavior) with a small muted "not yet interactive" note — do not silently pretend they're gradable.
- State: `Map<String, String> selectedAnswers` (question id → chosen option), keyed per question, held in `State`.
- Tap an option:
  - If that question already has a selection, ignore further taps (answer locked once chosen — no changing your mind after seeing the color, consistent with "guessing-proof" intent from the standard)
  - Otherwise, record the selection, then immediately render that option green (`AppTheme.semanticGreen`) if it matches `correctAnswer`, or red (`AppTheme.semanticRed`) if not — and if wrong, also highlight the correct option green so the student sees it
  - Show the explanation text under the question if `explanations[question.id]` is non-empty, once answered
- After every tap, call `widget.onResultChanged` with the recomputed `QuizSectionResult` so the parent screen always has a live score without needing a "submit" step
- Use existing design tokens only: `AppTheme.semanticGreen` / `semanticRed`, no new colors, 10–14px radius on chips (existing `_contentChip` pattern), no new animation library

---

## 4. Changes to `student_learning_step_screen.dart`

### State additions
```dart
final Map<String, QuizSectionResult> _sectionResults = {}; // keyed by section name: 'quiz', 'listening', 'reading'
bool _attemptedAndFailed = false;
```

### Score aggregation
Add a method that merges all `_sectionResults` into one combined score:
```dart
double get _combinedScore {
  final totalCorrect = _sectionResults.values.fold(0, (sum, r) => sum + r.correctCount);
  final totalQuestions = _sectionResults.values.fold(0, (sum, r) => sum + r.totalCount);
  if (totalQuestions == 0) return 1.0; // no auto-gradable content on this step — don't block on nothing
  return totalCorrect / totalQuestions;
}

bool get _allSectionsAnswered => _sectionResults.values.every((r) => r.allAnswered);
```

**Important edge case:** a step with only a writing/speaking task and no quiz/listening/reading questions must not be blocked by this logic (`totalQuestions == 0` → treat as passing, gate via `requiresTeacherReview` / submission status instead, which is unchanged in this phase).

### `_completeStep` rewrite
Current behavior: unconditionally calls `markStepCompleted`. New behavior:

```dart
Future<void> _completeStep() async {
  if (widget.alreadyCompleted || isSaving) {
    Navigator.pop(context, false);
    return;
  }

  final experience = getA1LearningExperienceById(widget.step.id);
  final threshold = experience?.passingScore ?? widget.step.passingScore;

  if (!_allSectionsAnswered) {
    // show inline message: "Answer all questions before completing this step."
    // do not proceed
    return;
  }

  if (_combinedScore < threshold) {
    setState(() { _attemptedAndFailed = true; });
    // show retry UI (see below) — do NOT call markStepCompleted
    return;
  }

  setState(() { isSaving = true; });
  await LearningPathProgressService.recordStepAttempt(
    stepId: widget.step.id,
    score: _combinedScore,
    passed: true,
  );
  await LearningPathProgressService.markStepCompleted(widget.step.id);
  if (!mounted) return;
  Navigator.pop(context, true);
}
```

### Retry UI
When `_attemptedAndFailed` is true, replace the primary button with:
- A message using existing muted/red text style: `"Score: XX% — needs YY% to pass. Review and try again."`
- A "TRY AGAIN" button (same visual weight as the primary button, but using `AppTheme.semanticRed` as accent, not the primary white/black) that calls a `_resetAttempt()` method: clears `_sectionResults`, `_attemptedAndFailed`, forces `InteractiveQuizSection` to reset its internal `selectedAnswers` (give the widget a `Key` derived from an attempt counter so Flutter rebuilds it fresh — e.g. `ValueKey('quiz_attempt_$_attemptNumber')`)
- Still call `recordStepAttempt` with `passed: false` on a failed attempt, so attempt history exists even for failures (needed for teacher visibility later, and for the standard's "limited attempts" anti-fraud note in §4 — this spec does not implement an attempt cap, but the recorded history is what a future cap would read from)

---

## 5. Changes to `learning_path_progress_service.dart`

Add a new method, parallel to the existing `recordLevelCheckAttempt` but scoped to a single step rather than a whole level:

```dart
static Future<void> recordStepAttempt({
  required String stepId,
  required double score,
  required bool passed,
}) async {
  await _recordRemoteStepAttempt(stepId: stepId, score: score, passed: passed);
}

static Future<void> _recordRemoteStepAttempt({
  required String stepId,
  required double score,
  required bool passed,
}) async {
  final client = SupabaseBootstrap.client;
  final studentId = await _remoteStudentId();
  if (client == null || studentId == null) return;

  try {
    await client.from('student_step_progress').upsert({
      'student_id': studentId,
      'learning_step_id': stepId,
      'status': passed ? 'completed' : 'review_needed',
      'score': score,
      'validated_by_level_check': false,
      'completed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'student_id,learning_step_id');
  } catch (error) {
    debugPrint('Remote step attempt recording failed: $error');
  }
}
```

**Database note (flag for whoever owns Supabase migrations, not part of the Dart change):** the `student_step_progress` table needs a `score` numeric column added if it doesn't already have one — this spec assumes it needs to be added. Confirm against the live schema before merging; do not guess the column already exists.

---

## 6. What does NOT change in this phase

- `_developmentExercise`'s fallback path for experiences with no matching `LearningExperience` (the `experience == null` branch, still showing the "Development activity placeholder" text) — that's the Skill Path gap, tracked separately
- `_listeningSection`'s audio rendering — script text stays as-is; no player added yet
- Writing/speaking task rendering (`_writingSection`, `_speakingSection`) — unchanged, still read-only prompts; teacher review flow is a separate spec
- The roadmap screen (`student_a1_roadmap_screen.dart`) — it already reads from `completedStepIds`, which this spec still populates the same way (via `markStepCompleted`), so no changes needed there
- No new enum values, no new top-level model classes beyond the one widget-local `QuizSectionResult`

---

## 7. Test coverage to add

`test/learning_path_data_test.dart` already exists — add a sibling or extend it with:
- A pure-Dart unit test for the score-aggregation math (`_combinedScore` logic) using a fake `QuizSectionResult` set — no widget test framework needed for this part
- A widget test for `InteractiveQuizSection`: tap wrong option → verify it renders red and the correct option renders green; tap right option → verify green only; verify a locked question ignores a second tap
- A widget test for `student_learning_step_screen.dart`: verify `_completeStep` does NOT call `markStepCompleted` when score is below threshold, and DOES when at/above threshold

---

## 8. Rollout order (do in this sequence, verify `flutter analyze` clean between each)

1. `InteractiveQuizSection` widget, unit-tested in isolation
2. Wire it into `student_learning_step_screen.dart` for the quiz block only (leave listening/reading sections as-is temporarily)
3. Extend to listening and reading question sections
4. Add `_combinedScore` / `_allSectionsAnswered` / retry flow to `_completeStep`
5. Add `recordStepAttempt` to the progress service (coordinate DB column check first)
6. Full manual pass: one lesson (auto-pass path), one lesson (fail-then-retry path), one checkpoint (verify hard-gate behavior matches lessons — no special-casing needed since the same `_completeStep` logic runs for every `LearningPathStepType`)

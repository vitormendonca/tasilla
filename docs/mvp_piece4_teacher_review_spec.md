# MVP Piece 4 — Teacher Review Screen

**Depends on:** Piece 1 (`student_submissions` table + `submissions` storage bucket) — DONE.

**Why this before the submission features:** build the destination before things start
flowing to it. When Pieces 2 and 3 ship, there is already somewhere for submissions to land
and a way to verify they arrived.

**This is the heart of the product.** Your certification standard says: *"Multiple-choice can
never prove someone speaks English... The teacher is the final gatekeeper of the certificate.
The app prepares the evidence; the teacher signs off."* This screen IS that gatekeeping.

---

## 1. New service: `submission_service.dart`

`lib/services/submission_service.dart`

```dart
class Submission {
  final String id;
  final String studentId;
  final String studentName;        // joined from profiles
  final String learningStepId;
  final String stepTitle;          // resolved from a1LearningExperiences
  final String skill;              // 'speaking' | 'writing'
  final String submissionType;     // 'audio' | 'text' | 'file'
  final String? textContent;
  final String? filePath;
  final String status;             // 'submitted' | 'approved' | 'rejected'
  final String? teacherFeedback;
  final DateTime submittedAt;
}
```

**Methods:**

| Method | Purpose |
|---|---|
| `getPendingSubmissions()` | All `status = 'submitted'` for the teacher's linked students, newest first. RLS handles the filtering — do NOT filter by teacher in the query; the policy already does. |
| `getSubmissionsForStudent(studentId)` | All submissions for one student, any status |
| `getSignedUrl(filePath)` | Storage signed URL for audio/file playback. Bucket is private — a direct URL will 403. Use `client.storage.from('submissions').createSignedUrl(path, 3600)`. |
| `approveSubmission(id, feedback)` | `update status = 'approved'`. **Do NOT set `reviewed_by` / `reviewed_at` from Dart — the DB trigger sets them.** Setting them client-side will be overwritten anyway. |
| `rejectSubmission(id, feedback)` | `update status = 'rejected'` + feedback |

**Important:** the DB trigger (`enforce_submission_review_authority`) will RAISE an exception
if a non-teacher tries to approve. Catch that and surface it as a real error, not a silent
failure.

---

## 2. New screen: `teacher_review_screen.dart`

`lib/screens/teacher/teacher_review_screen.dart`

### Entry point
Add a 5th `_actionTile` to `teacher_home_screen.dart`, matching the existing pattern exactly:

```dart
_actionTile(
  icon: Icons.rate_review_outlined,
  title: 'Review',
  subtitle: 'Listen to speaking and read writing submissions. Approve or request a redo.',
  onTap: () => _openScreen(context, const TeacherReviewScreen()),
  textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
),
```

Place it **above** 'Progress' (the coming-soon one) — review is the more important action.

### Layout

**Header** — same visual language as `student_a1_roadmap_screen`'s header:
- Label: `REVIEW QUEUE`
- Count chips: `N pending` · `N approved` · `N needs redo`

**Filter row** — chips: `All` · `Speaking` · `Writing`

**The list** — one card per pending submission:
- Student name
- Lesson title + skill chip (use `AppTheme` semantic colors, no new ones)
- Time since submitted ("2 hours ago")
- Tap → opens the detail view

**Empty state:** "No submissions waiting for review." — not an error, a good state.

---

## 3. Submission detail view

`teacher_submission_detail_screen.dart` (or a modal — either is fine).

### Content by type

| `submissionType` | Render |
|---|---|
| `audio` | Reuse **`lesson_audio_player.dart`** (already built and tested). Feed it the signed URL. |
| `text` | The `textContent`, in a readable serif/body style. Selectable. |
| `file` | Image → inline preview. PDF/DOCX → filename + "Open" button (opens the signed URL in a new tab). Do not attempt inline PDF rendering for MVP. |

### The rubric — this is the point

Show the lesson's `Rubric.criteria` **beside** the submission, not buried below it. The
rubric is already modelled (`Rubric`, `RubricCriterion` with `title` + `description`) and is
already attached to speaking/writing experiences.

A teacher grading against explicit criteria is what makes the assessment defensible. Without
the rubric visible, approval is just vibes.

### Actions

Two buttons:
- **Approve** — primary style (the existing dark/white button)
- **Request redo** — `AppTheme.semanticRed` accent

Both open a feedback text field first. **Feedback is required for redo, optional for
approve.** A student told "redo this" with no reason has learned nothing.

On success: pop back to the queue, remove the item from the pending list, show a brief
confirmation.

---

## 4. Student side — seeing the result

Small addition to the student lesson screen (`student_learning_step_screen.dart`).

When a speaking/writing lesson has a submission, show its status instead of the submit
button:

| Status | Show |
|---|---|
| `submitted` | Muted chip: "Waiting for teacher review" |
| `approved` | Green chip: "Approved" + the teacher's feedback if any |
| `rejected` | Red chip: "Needs redo" + the feedback (**required**, so it will be there) + a "Try again" button that clears the submission and lets them resubmit |

**The lesson still counts as complete when submitted, not when approved.** Do not block the
student's progression on the teacher's queue — a student should never be stuck because their
teacher is on holiday. Approval gates the **certificate**, not the roadmap.

---

## 5. Out of scope for this piece

- Actually recording audio (Piece 2)
- Actually submitting writing (Piece 3)
- Certificate issuance (Piece 5)
- Bulk approve
- Notifications/email

**How to test with no submission features yet:** insert a row directly via SQL, pointing at
a file you upload manually through the Supabase Storage UI. Verify the teacher can see it,
play it, and approve it. That proves the loop before Pieces 2–3 exist.

```sql
-- test row (swap in a real student_id from your profiles table)
insert into public.student_submissions
  (student_id, learning_step_id, skill, submission_type, text_content)
values
  ('PASTE_STUDENT_UUID', 'A1-EXP-001', 'writing', 'text',
   'Hello. My name is Ana. I am from Peru. I am twenty years old.');
```

---

## 6. Definition of done

A teacher logs in, opens Review, sees a pending writing submission from their student, reads
it against the rubric, types feedback, approves it. The student opens that lesson and sees
"Approved" with the feedback.

That loop working — even with a manually inserted row — is the whole product in miniature.

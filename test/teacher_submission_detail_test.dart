import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/data/a1_content_loader.dart';
import 'package:tasilla/screens/teacher/teacher_submission_detail_screen.dart';
import 'package:tasilla/services/submission_service.dart';

Submission _textSubmission({
  String status = 'submitted',
  String? feedback,
  String learningStepId = 'A1-EXP-016',
}) {
  return Submission(
    id: 'sub-1',
    studentId: 'student-1',
    studentName: 'Ana',
    learningStepId: learningStepId,
    stepTitle: Submission.stepTitleFor(learningStepId),
    skill: 'writing',
    submissionType: 'text',
    textContent: 'Hello. My name is Ana. I am from Peru.',
    filePath: null,
    status: status,
    teacherFeedback: feedback,
    submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );
}

/// The screen is a lazily-built ListView, so a tall viewport is needed for the
/// feedback card below the fold to exist at all. The width stays under the
/// 900px wide-layout threshold, exercising the stacked layout.
Future<void> _pumpDetail(WidgetTester tester, Submission submission) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(home: TeacherSubmissionDetailScreen(submission: submission)),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadA1Content();
  });
  testWidgets('shows the student work and the lesson rubric together', (
    tester,
  ) async {
    await _pumpDetail(tester, _textSubmission());

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('My Activities'), findsOneWidget);
    expect(
      find.text('Hello. My name is Ana. I am from Peru.'),
      findsOneWidget,
    );

    // The rubric is the point of the screen — without it, approval is vibes.
    expect(find.text('Rubric'), findsOneWidget);
    expect(find.text('A1 clarity'), findsOneWidget);
    expect(find.text('Task completion'), findsOneWidget);
    expect(find.text('Accuracy'), findsOneWidget);
  });

  testWidgets('a redo without feedback is blocked before it reaches the database', (
    tester,
  ) async {
    await _pumpDetail(tester, _textSubmission());

    await tester.tap(find.byKey(const ValueKey('submission_reject_button')));
    await tester.pump();

    expect(
      find.text('Feedback is required when you ask for a redo.'),
      findsOneWidget,
    );
  });

  testWidgets('typing feedback clears the redo validation error', (
    tester,
  ) async {
    await _pumpDetail(tester, _textSubmission());

    await tester.tap(find.byKey(const ValueKey('submission_reject_button')));
    await tester.pump();
    expect(
      find.text('Feedback is required when you ask for a redo.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('submission_feedback_field')),
      'Add two more sentences about your country.',
    );
    await tester.pump();

    expect(
      find.text('Feedback is required when you ask for a redo.'),
      findsNothing,
    );
  });

  testWidgets('the feedback field owns the whole box it draws', (tester) async {
    await _pumpDetail(tester, _textSubmission());

    final field = find.byKey(const ValueKey('submission_feedback_field'));
    final card = find.byKey(const ValueKey('submission_feedback_card'));

    final fieldBox = tester.getRect(field);
    final cardBox = tester.getRect(card);

    // The field's border and padding live in its own InputDecoration, so its
    // hit target IS the drawn box and it fills the card's content width. Wrap
    // it in a padded, bordered Container instead and the drawn box grows while
    // the hit target stays inset — leaving a dead band inside the visible
    // border where clicks and drag-selection miss the editable.
    const cardPadding = 18.0;
    const cardBorder = 1.0;
    final contentWidth =
        cardBox.width - (cardPadding * 2) - (cardBorder * 2);

    expect(
      fieldBox.width,
      moreOrLessEquals(contentWidth, epsilon: 0.5),
      reason:
          'the feedback field should span the card content width; a narrower '
          'field means a wrapper is drawing the box the field does not own',
    );

    // And every corner of that drawn box focuses the field.
    EditableText editable() => tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );

    for (final corner in <Offset>[
      fieldBox.topLeft + const Offset(3, 3),
      fieldBox.bottomRight + const Offset(-3, -3),
    ]) {
      await tester.tapAt(corner);
      await tester.pump();

      expect(
        editable().focusNode.hasFocus,
        isTrue,
        reason: 'tapping $corner inside the drawn box should focus the field',
      );

      editable().focusNode.unfocus();
      await tester.pump();
    }
  });

  testWidgets('an existing review pre-fills its feedback', (tester) async {
    await _pumpDetail(
      tester,
      _textSubmission(status: 'approved', feedback: 'Well done, Ana.'),
    );

    expect(find.text('Well done, Ana.'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
  });

  testWidgets('a lesson with no rubric says so rather than showing nothing', (
    tester,
  ) async {
    // Reinforcement lessons are practice, never certificate evidence, so they
    // carry no rubric. A submission should still render rather than break.
    await _pumpDetail(tester, _textSubmission(learningStepId: 'A1-REF-001'));

    expect(find.text('Rubric'), findsOneWidget);
    expect(find.textContaining('no rubric attached'), findsOneWidget);
  });
}

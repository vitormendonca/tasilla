import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/models/learning_enums.dart';
import 'package:tasilla/models/learning_path_step.dart';
import 'package:tasilla/screens/student/student_learning_step_screen.dart';
import 'package:tasilla/services/submission_service.dart';

/// A writing lesson that a teacher reviews.
const LearningPathStep _writingStep = LearningPathStep(
  id: 'A1-EXP-016',
  skillId: 'a1_roadmap',
  title: 'My Activities',
  description: 'Write about what you do.',
  level: 'A1',
  type: LearningPathStepType.lesson,
  activityKind: ActivityKind.coreActivity,
  skillTitle: 'A1 Road Map',
  order: 16,
);

Submission _submission({required String status, String? feedback}) {
  return Submission(
    id: 'sub-1',
    studentId: 'student-1',
    studentName: 'Ana',
    learningStepId: 'A1-EXP-016',
    stepTitle: 'My Activities',
    skill: 'writing',
    submissionType: 'text',
    textContent: 'Hello. My name is Ana.',
    filePath: null,
    status: status,
    teacherFeedback: feedback,
    submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );
}

/// The lesson is a lazily-built ListView, so anything below the fold is never
/// constructed. A tall viewport renders the whole page, which keeps both
/// findsOneWidget and findsNothing assertions honest.
Future<void> _pumpStep(
  WidgetTester tester, {
  required Submission submission,
}) async {
  tester.view.physicalSize = const Size(1000, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: StudentLearningStepScreen(
        step: _writingStep,
        alreadyCompleted: false,
        initialSubmission: submission,
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('a pending submission shows it is waiting for the teacher', (
    tester,
  ) async {
    await _pumpStep(tester, submission: _submission(status: 'submitted'));

    expect(find.text('Waiting for teacher review'), findsOneWidget);
    expect(find.text('Teacher feedback'), findsNothing);
    expect(
      find.byKey(const ValueKey('submission_try_again_button')),
      findsNothing,
    );
  });

  testWidgets('an approved submission shows the approval and its feedback', (
    tester,
  ) async {
    await _pumpStep(
      tester,
      submission: _submission(status: 'approved', feedback: 'Well done, Ana.'),
    );

    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Teacher feedback'), findsOneWidget);
    expect(find.text('Well done, Ana.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('submission_try_again_button')),
      findsNothing,
    );
  });

  testWidgets('a rejected submission shows the reason and a way back in', (
    tester,
  ) async {
    await _pumpStep(
      tester,
      submission: _submission(
        status: 'rejected',
        feedback: 'Add two more sentences about your country.',
      ),
    );

    expect(find.text('Needs redo'), findsOneWidget);
    expect(
      find.text('Add two more sentences about your country.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('submission_try_again_button')),
      findsOneWidget,
    );
  });

  testWidgets('try again dismisses the status card so the work can be redone', (
    tester,
  ) async {
    await _pumpStep(
      tester,
      submission: _submission(status: 'rejected', feedback: 'Try once more.'),
    );

    await tester.tap(
      find.byKey(const ValueKey('submission_try_again_button')),
    );
    await tester.pump();

    expect(find.text('Needs redo'), findsNothing);
    expect(
      find.byKey(const ValueKey('submission_try_again_button')),
      findsNothing,
    );
  });

  testWidgets(
    'a rejected submission still leaves the lesson completable — approval '
    'gates the certificate, not the roadmap',
    (tester) async {
      await _pumpStep(
        tester,
        submission: _submission(status: 'rejected', feedback: 'Try once more.'),
      );

      expect(find.text('COMPLETE LESSON'), findsOneWidget);
    },
  );
}

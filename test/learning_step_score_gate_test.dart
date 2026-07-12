import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/data/a1_learning_experience_data.dart';
import 'package:tasilla/data/learning_path_data.dart';
import 'package:tasilla/screens/student/student_learning_step_screen.dart';

void main() {
  Future<void> pumpStep(
    WidgetTester tester,
    String stepId,
    Future<void> Function(String) onCompleted,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final step = a1RoadmapSteps.firstWhere((step) => step.id == stepId);
    await tester.pumpWidget(
      MaterialApp(
        home: StudentLearningStepScreen(
          step: step,
          alreadyCompleted: false,
          onMarkStepCompleted: onCompleted,
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tapCompletionButton(WidgetTester tester) async {
    final button = find.text('COMPLETE LESSON');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  testWidgets('blocks completion until every question is answered', (
    tester,
  ) async {
    var completionCalls = 0;
    await pumpStep(tester, 'A1-EXP-006', (_) async {
      completionCalls++;
    });

    await tapCompletionButton(tester);

    expect(
      find.text('Answer all questions before completing this step.'),
      findsOneWidget,
    );
    expect(completionCalls, 0);
  });

  testWidgets('failed score shows retry and does not complete', (tester) async {
    var completionCalls = 0;
    const stepId = 'A1-EXP-006';
    await pumpStep(tester, stepId, (_) async {
      completionCalls++;
    });
    final questions = getA1LearningExperienceById(stepId)!.quizBlock!.questions;

    for (final question in questions) {
      final wrong = question.options.firstWhere(
        (option) => option != question.correctAnswer,
      );
      await tester.tap(find.text(wrong).last);
      await tester.pump();
    }
    await tapCompletionButton(tester);

    expect(find.textContaining('needs 75% to pass'), findsOneWidget);
    expect(find.text('TRY AGAIN'), findsOneWidget);
    expect(completionCalls, 0);

    await tester.tap(find.text('TRY AGAIN'));
    await tester.pump();

    expect(find.text('TRY AGAIN'), findsNothing);
    expect(find.text('COMPLETE LESSON'), findsOneWidget);
  });

  testWidgets('passing score completes the lesson', (tester) async {
    var completionCalls = 0;
    const stepId = 'A1-EXP-006';
    await pumpStep(tester, stepId, (_) async {
      completionCalls++;
    });
    final questions = getA1LearningExperienceById(stepId)!.quizBlock!.questions;

    for (final question in questions) {
      await tester.tap(find.text(question.correctAnswer).last);
      await tester.pump();
    }
    await tapCompletionButton(tester);
    await tester.pumpAndSettle();

    expect(completionCalls, 1);
  });

  testWidgets(
    'speaking lesson with no gradable questions is not score-blocked',
    (tester) async {
      var completionCalls = 0;
      await pumpStep(tester, 'A1-EXP-001', (_) async {
        completionCalls++;
      });

      await tapCompletionButton(tester);
      await tester.pumpAndSettle();

      expect(completionCalls, 1);
    },
  );
}

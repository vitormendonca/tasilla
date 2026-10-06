import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/data/a1_content_loader.dart';
import 'package:tasilla/data/learning_path_data.dart';
import 'package:tasilla/screens/student/student_learning_step_screen.dart';
import 'package:tasilla/models/activity_question.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadA1Content();
  });
  Future<void> pumpStep(
    WidgetTester tester,
    String stepId,
    Future<void> Function(String) onCompleted,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final step = getA1RoadmapSteps().firstWhere((step) => step.id == stepId);
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

  Future<void> tapVisibleText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
  }

  bool usesTextEntry(ActivityQuestion question) =>
      question.type == QuestionType.textInput ||
      question.type == QuestionType.dictation ||
      (question.type == QuestionType.fillBlank && question.options.isEmpty);

  Future<void> answerQuestion(
    WidgetTester tester,
    ActivityQuestion question,
    String answer,
  ) async {
    if (usesTextEntry(question)) {
      final field = find.byKey(ValueKey('answer_${question.id}'));
      await tester.ensureVisible(field);
      await tester.pump();
      await tester.enterText(field, answer);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      return;
    }
    final optionIndex = question.options.indexOf(answer);
    final option = find.byKey(
      ValueKey('answer_${question.id}_$optionIndex'),
    );
    await tester.ensureVisible(option);
    await tester.pump();
    await tester.tap(option);
    await tester.pump();
  }

  Future<void> tapCompletionButton(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('COMPLETE LESSON'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('COMPLETE LESSON'));
    await tester.pump();
  }

  testWidgets('blocks completion until every question is answered', (
    tester,
  ) async {
    var completionCalls = 0;
    await pumpStep(tester, 'A1-T02-VOC', (_) async {
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
    const stepId = 'A1-T02-VOC';
    await pumpStep(tester, stepId, (_) async {
      completionCalls++;
    });
    final experience = getA1LearningExperienceById(stepId)!;
    final questions = experience.quizBlock!.questions;

    for (final question in questions) {
      final wrong = question.options.firstWhere(
        (option) => option != question.correctAnswer,
      );
      await answerQuestion(tester, question, wrong);
    }
    await tapCompletionButton(tester);

    expect(
      find.textContaining('needs ${(experience.passingScore * 100).round()}% to pass'),
      findsOneWidget,
    );
    expect(find.text('TRY AGAIN'), findsOneWidget);
    expect(completionCalls, 0);

    await tester.tap(find.text('TRY AGAIN'));
    await tester.pump();

    expect(find.text('TRY AGAIN'), findsNothing);
    expect(find.text('COMPLETE LESSON'), findsOneWidget);
  });

  testWidgets('passing score completes the lesson', (tester) async {
    var completionCalls = 0;
    const stepId = 'A1-T02-VOC';
    await pumpStep(tester, stepId, (_) async {
      completionCalls++;
    });
    final questions = getA1LearningExperienceById(stepId)!.quizBlock!.questions;

    for (final question in questions) {
      await answerQuestion(tester, question, question.correctAnswer);
    }
    await tapCompletionButton(tester);
    await tester.pumpAndSettle();

    expect(completionCalls, 1);
  });

  testWidgets(
    'speaking lesson with no gradable questions is not score-blocked',
    (tester) async {
      var completionCalls = 0;
      await pumpStep(tester, 'A1-T01-SPE', (_) async {
        completionCalls++;
      });

      await tapCompletionButton(tester);
      await tester.pumpAndSettle();

      expect(completionCalls, 1);
    },
  );
}

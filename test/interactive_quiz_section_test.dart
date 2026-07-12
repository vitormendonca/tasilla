import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/models/activity_question.dart';
import 'package:tasilla/theme/app_theme.dart';
import 'package:tasilla/widgets/interactive_quiz_section.dart';

void main() {
  const question = ActivityQuestion(
    id: 'q1',
    type: QuestionType.multipleChoice,
    question: 'What is the capital of France?',
    options: ['London', 'Paris'],
    correctAnswer: 'Paris',
  );

  Color? colorOf(WidgetTester tester, String label) {
    final text = tester.widget<Text>(find.text(label));
    return text.style?.color;
  }

  Future<QuizSectionResult> pumpSection(
    WidgetTester tester, {
    List<ActivityQuestion> questions = const [question],
    Map<String, String> explanations = const {},
  }) async {
    late QuizSectionResult latestResult;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveQuizSection(
            sectionTitle: 'Questions',
            questions: questions,
            explanations: explanations,
            onResultChanged: (result) => latestResult = result,
          ),
        ),
      ),
    );
    await tester.pump();
    return latestResult;
  }

  testWidgets('tapping the wrong option renders it red and reveals the correct option in green', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text('London'));
    await tester.pump();

    expect(colorOf(tester, 'London'), AppTheme.semanticRed);
    expect(colorOf(tester, 'Paris'), AppTheme.semanticGreen);
  });

  testWidgets('tapping the correct option renders only it green', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text('Paris'));
    await tester.pump();

    expect(colorOf(tester, 'Paris'), AppTheme.semanticGreen);
    expect(colorOf(tester, 'London'), isNot(AppTheme.semanticRed));
  });

  testWidgets('a locked question ignores further taps', (tester) async {
    final result = await pumpSection(tester);
    expect(result.allAnswered, false);

    await tester.tap(find.text('London'));
    await tester.pump();
    expect(colorOf(tester, 'London'), AppTheme.semanticRed);

    await tester.tap(find.text('Paris'));
    await tester.pump();

    // Selection stays locked to the first tap: Paris does not turn red/selected-wrong,
    // it was already shown green as the revealed correct answer.
    expect(colorOf(tester, 'London'), AppTheme.semanticRed);
    expect(colorOf(tester, 'Paris'), AppTheme.semanticGreen);
  });

  testWidgets('calls onResultChanged with the recomputed score after every tap', (tester) async {
    QuizSectionResult? latest;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveQuizSection(
            sectionTitle: 'Questions',
            questions: const [question],
            explanations: const {},
            onResultChanged: (result) => latest = result,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(latest!.totalCount, 1);
    expect(latest!.answeredCount, 0);

    await tester.tap(find.text('Paris'));
    await tester.pump();

    expect(latest!.answeredCount, 1);
    expect(latest!.correctCount, 1);
    expect(latest!.allAnswered, true);
    expect(latest!.score, 1.0);
  });

  testWidgets('shows the explanation once the question is answered', (tester) async {
    await pumpSection(
      tester,
      explanations: const {'q1': 'Paris has been the capital since 987 AD.'},
    );

    expect(find.text('Paris has been the capital since 987 AD.'), findsNothing);

    await tester.tap(find.text('Paris'));
    await tester.pump();

    expect(find.text('Paris has been the capital since 987 AD.'), findsOneWidget);
  });

  testWidgets('non-multiple-choice questions render as static text with a not-yet-interactive note', (tester) async {
    const textQuestion = ActivityQuestion(
      id: 'q2',
      type: QuestionType.textInput,
      question: 'Write a sentence using "hello".',
      correctAnswer: 'hello',
    );

    await pumpSection(tester, questions: const [textQuestion]);

    expect(find.text('Not yet interactive'), findsOneWidget);
  });
}

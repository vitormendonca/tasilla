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

  testWidgets(
    'tapping the wrong option renders it red and reveals the correct option in green',
    (tester) async {
      await pumpSection(tester);

      await tester.tap(find.text('London'));
      await tester.pump();

      expect(colorOf(tester, 'London'), AppTheme.semanticRed);
      expect(colorOf(tester, 'Paris'), AppTheme.semanticGreen);
    },
  );

  testWidgets('tapping the correct option renders only it green', (
    tester,
  ) async {
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

  testWidgets(
    'calls onResultChanged with the recomputed score after every tap',
    (tester) async {
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
      expect(latest!.answers, const {'q1': 'Paris'});
    },
  );

  testWidgets('shows the explanation once the question is answered', (
    tester,
  ) async {
    await pumpSection(
      tester,
      explanations: const {'q1': 'Paris has been the capital since 987 AD.'},
    );

    expect(find.text('Paris has been the capital since 987 AD.'), findsNothing);

    await tester.tap(find.text('Paris'));
    await tester.pump();

    expect(
      find.text('Paris has been the capital since 987 AD.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'reorder-sentence questions render as static text with a not-yet-interactive note',
    (tester) async {
      const reorderQuestion = ActivityQuestion(
        id: 'q2',
        type: QuestionType.reorderSentence,
        question: 'Put the words in the correct order.',
        words: ['am', 'I', 'happy'],
        correctAnswer: 'I am happy',
      );

      await pumpSection(tester, questions: const [reorderQuestion]);

      expect(find.text('Not yet interactive'), findsOneWidget);
    },
  );

  testWidgets('true/false questions get tap grading like multiple choice', (
    tester,
  ) async {
    const trueFalse = ActivityQuestion(
      id: 'tf1',
      type: QuestionType.trueFalse,
      question: 'Paris is the capital of France.',
      options: ['True', 'False'],
      correctAnswer: 'True',
    );
    QuizSectionResult? latest;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveQuizSection(
            sectionTitle: 'Questions',
            questions: const [trueFalse],
            explanations: const {},
            onResultChanged: (result) => latest = result,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(latest!.totalCount, 1);

    await tester.tap(find.text('False'));
    await tester.pump();

    expect(colorOf(tester, 'False'), AppTheme.semanticRed);
    expect(colorOf(tester, 'True'), AppTheme.semanticGreen);
    expect(latest!.correctCount, 0);
    expect(latest!.allAnswered, true);
  });

  testWidgets('text-input questions are graded like the listening screen', (
    tester,
  ) async {
    const textQuestion = ActivityQuestion(
      id: 'ti1',
      type: QuestionType.textInput,
      question: 'How does Anna go to work?',
      correctAnswer: 'By bus',
    );
    QuizSectionResult? latest;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveQuizSection(
            sectionTitle: 'Reading comprehension',
            questions: const [textQuestion],
            explanations: const {},
            onResultChanged: (result) => latest = result,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(latest!.totalCount, 1);
    expect(latest!.allAnswered, false);

    await tester.enterText(
      find.byKey(const ValueKey('answer_ti1')),
      '  by bus ',
    );
    await tester.tap(find.byTooltip('Check answer'));
    await tester.pump();

    expect(find.text('Correct'), findsOneWidget);
    expect(latest!.correctCount, 1);
    expect(latest!.allAnswered, true);
  });

  testWidgets('dictation accepts normalized text and contributes to score', (
    tester,
  ) async {
    const dictation = ActivityQuestion(
      id: 'dictation-1',
      type: QuestionType.dictation,
      question: 'Type what you hear.',
      correctAnswer: 'Hello, my name is Anna.',
    );
    QuizSectionResult? latest;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveQuizSection(
            sectionTitle: 'Dictation',
            questions: const [dictation],
            explanations: const {},
            onResultChanged: (result) => latest = result,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(latest!.totalCount, 1);
    expect(latest!.allAnswered, false);

    await tester.enterText(
      find.byKey(const ValueKey('answer_dictation-1')),
      '  hello my name is anna  ',
    );
    await tester.tap(find.byTooltip('Check answer'));
    await tester.pump();

    expect(find.text('Correct'), findsOneWidget);
    expect(latest!.correctCount, 1);
    expect(latest!.allAnswered, true);
  });

  testWidgets('fill blank locks a wrong answer and reveals the correction', (
    tester,
  ) async {
    const fillBlank = ActivityQuestion(
      id: 'fill-1',
      type: QuestionType.fillBlank,
      question: 'I ___ a student.',
      correctAnswer: 'am',
    );
    QuizSectionResult? latest;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveQuizSection(
            sectionTitle: 'Grammar',
            questions: const [fillBlank],
            explanations: const {},
            onResultChanged: (result) => latest = result,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byKey(const ValueKey('answer_fill-1')), 'is');
    await tester.tap(find.byTooltip('Check answer'));
    await tester.pump();

    expect(find.text('Correct answer: am'), findsOneWidget);
    expect(latest!.answeredCount, 1);
    expect(latest!.correctCount, 0);
    expect(latest!.allAnswered, true);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('answer_fill-1')))
          .enabled,
      false,
    );
  });
}

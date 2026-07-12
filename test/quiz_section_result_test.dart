import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/widgets/interactive_quiz_section.dart';

double _combinedScore(Iterable<QuizSectionResult> results) {
  final totalCorrect = results.fold(0, (sum, r) => sum + r.correctCount);
  final totalQuestions = results.fold(0, (sum, r) => sum + r.totalCount);
  if (totalQuestions == 0) return 1.0;
  return totalCorrect / totalQuestions;
}

bool _allAnswered(Iterable<QuizSectionResult> results) =>
    results.every((r) => r.allAnswered);

void main() {
  test('score getter divides correct by total, guarding zero questions', () {
    const empty = QuizSectionResult(
      answeredCount: 0,
      correctCount: 0,
      totalCount: 0,
      allAnswered: true,
    );
    const partial = QuizSectionResult(
      answeredCount: 4,
      correctCount: 3,
      totalCount: 4,
      allAnswered: true,
    );

    expect(empty.score, 0);
    expect(partial.score, 0.75);
  });

  test('combining sections with no auto-gradable questions is treated as passing', () {
    const writingOnly = QuizSectionResult(
      answeredCount: 0,
      correctCount: 0,
      totalCount: 0,
      allAnswered: true,
    );

    expect(_combinedScore([writingOnly]), 1.0);
    expect(_allAnswered([writingOnly]), true);
  });

  test('combining quiz + listening + reading sections folds correct/total across all of them', () {
    const quiz = QuizSectionResult(
      answeredCount: 5,
      correctCount: 4,
      totalCount: 5,
      allAnswered: true,
    );
    const listening = QuizSectionResult(
      answeredCount: 3,
      correctCount: 2,
      totalCount: 3,
      allAnswered: true,
    );
    const reading = QuizSectionResult(
      answeredCount: 2,
      correctCount: 2,
      totalCount: 2,
      allAnswered: true,
    );

    final combined = _combinedScore([quiz, listening, reading]);
    expect(combined, closeTo(8 / 10, 0.0001));
    expect(_allAnswered([quiz, listening, reading]), true);
  });

  test('a section that is not fully answered makes the whole set unanswered', () {
    const quiz = QuizSectionResult(
      answeredCount: 5,
      correctCount: 4,
      totalCount: 5,
      allAnswered: true,
    );
    const listening = QuizSectionResult(
      answeredCount: 1,
      correctCount: 1,
      totalCount: 3,
      allAnswered: false,
    );

    expect(_allAnswered([quiz, listening]), false);
  });
}

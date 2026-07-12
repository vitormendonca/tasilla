import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/data/a1_learning_experience_data.dart';
import 'package:tasilla/data/learning_path_data.dart';
import 'package:tasilla/models/learning_enums.dart';
import 'package:tasilla/screens/student/student_learning_step_screen.dart';

void main() {
  test(
    'foreign supporting blocks do not get generated assessment questions',
    () {
      final speaking = getA1LearningExperienceById('A1-EXP-001')!;
      final listening = getA1LearningExperienceById('A1-EXP-002')!;
      final reading = getA1LearningExperienceById('A1-EXP-005')!;
      final mixed = getA1LearningExperienceById('A1-EXP-010')!;

      expect(speaking.primarySkill, LearningSkill.speaking);
      expect(speaking.listeningBlock, isNotNull);
      expect(speaking.listeningBlock!.listeningQuestions, isEmpty);
      expect(speaking.readingBlock, isNotNull);
      expect(speaking.readingBlock!.readingQuestions, isEmpty);

      expect(listening.listeningBlock, isNotNull);
      expect(listening.listeningBlock!.listeningQuestions, isNotEmpty);
      expect(reading.readingBlock, isNotNull);
      expect(reading.readingBlock!.readingQuestions, isNotEmpty);
      expect(mixed.listeningBlock!.listeningQuestions, isNotEmpty);
    },
  );

  testWidgets('speaking lesson renders only its skill-specific activity', (
    tester,
  ) async {
    final step = a1RoadmapSteps.firstWhere((step) => step.id == 'A1-EXP-001');

    await tester.pumpWidget(
      MaterialApp(
        home: StudentLearningStepScreen(step: step, alreadyCompleted: false),
      ),
    );

    final experience = getA1LearningExperienceById('A1-EXP-001')!;
    expect(find.text(experience.speakingTask!.speakingPrompt), findsOneWidget);
    expect(find.text('Listening comprehension'), findsNothing);
    expect(find.text('Reading comprehension'), findsNothing);
    expect(find.text('Questions'), findsNothing);
    expect(
      find.text('What does the text help the student understand?'),
      findsNothing,
    );
  });

  testWidgets('mixed lesson retains all integrative sections', (tester) async {
    final step = a1RoadmapSteps.firstWhere((step) => step.id == 'A1-EXP-010');

    await tester.pumpWidget(
      MaterialApp(
        home: StudentLearningStepScreen(step: step, alreadyCompleted: false),
      ),
    );

    expect(find.text('Listening comprehension'), findsOneWidget);
    expect(find.text('Questions'), findsOneWidget);
    expect(find.text('Writing'), findsOneWidget);
    expect(find.text('Speaking'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/data/a1_content_loader.dart';
import 'package:tasilla/data/learning_path_data.dart';
import 'package:tasilla/models/learning_enums.dart';
import 'package:tasilla/screens/student/student_learning_step_screen.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadA1Content();
  });
  test(
    'foreign-skill blocks are not generated at all (full separation)',
    () {
      final speaking = getA1LearningExperienceById('A1-T01-SPE')!;
      final listening = getA1LearningExperienceById('A1-T01-LIS')!;
      final reading = getA1LearningExperienceById('A1-T01-REA')!;
      final mixed = getA1LearningExperienceById('A1-MIX-A')!;

      // A single-skill speaking lesson carries no listening or reading block,
      // even if its seed holds an audio script / reading text (orphaned content
      // for a future lesson on the same topic). Spec v2 revokes v1's "empty but
      // present" blocks.
      expect(speaking.primarySkill, LearningSkill.speaking);
      expect(speaking.listeningBlock, isNull);
      expect(speaking.readingBlock, isNull);

      expect(listening.listeningBlock, isNotNull);
      expect(listening.listeningBlock!.listeningQuestions, isNotEmpty);
      expect(reading.readingBlock, isNotNull);
      expect(reading.readingBlock!.readingQuestions, isNotEmpty);
      expect(mixed.listeningBlock!.listeningQuestions, isNotEmpty);
    },
  );

  testWidgets(
    'a listening lesson renders no vocabulary or grammar section',
    (tester) async {
      // EXP-002 "Greetings" is a listening lesson whose seed still carries
      // generated vocabulary blocks. Under full separation the lesson renders
      // only listening content — no vocab chips, no grammar.
      final experience = getA1LearningExperienceById('A1-T01-LIS')!;
      expect(experience.primarySkill, LearningSkill.listening);
      expect(experience.vocabularyBlocks, isEmpty);

      final step = a1RoadmapSteps.firstWhere((step) => step.id == 'A1-T01-LIS');

      await tester.pumpWidget(
        MaterialApp(
          home: StudentLearningStepScreen(step: step, alreadyCompleted: false),
        ),
      );

      expect(find.text('Listening'), findsOneWidget);
      expect(find.text('Vocabulary'), findsNothing);
      expect(find.text('Grammar'), findsNothing);
    },
  );

  testWidgets('speaking lesson renders only its skill-specific activity', (
    tester,
  ) async {
    final step = a1RoadmapSteps.firstWhere((step) => step.id == 'A1-T01-SPE');

    await tester.pumpWidget(
      MaterialApp(
        home: StudentLearningStepScreen(step: step, alreadyCompleted: false),
      ),
    );

    final experience = getA1LearningExperienceById('A1-T01-SPE')!;
    expect(find.text(experience.speakingTask!.speakingPrompt), findsOneWidget);
    expect(find.text('Listening comprehension'), findsNothing);
    expect(find.text('Reading comprehension'), findsNothing);
    expect(find.text('Questions'), findsNothing);
    expect(
      find.text('What does the text help the student understand?'),
      findsNothing,
    );
  });

  testWidgets('vocabulary lesson renders its own core sections', (tester) async {
    final step = getA1RoadmapSteps().firstWhere((step) => step.id == 'A1-T01-VOC');

    await tester.pumpWidget(
      MaterialApp(
        home: StudentLearningStepScreen(step: step, alreadyCompleted: false),
      ),
    );

    expect(find.text('Vocabulary'), findsOneWidget);
    expect(find.text('Listening comprehension'), findsNothing);
    expect(find.text('Reading comprehension'), findsNothing);
  });
}

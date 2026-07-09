import 'learning_enums.dart';

class HomeworkActivity {
  final String id;
  final String title;
  final String description;
  final String level;
  final String levelId;
  final String cycleId;
  final LearningSkill skill;
  final ActivityKind activityKind;
  final String cefrLevel;
  final String canDoStatement;
  final double passingScore;

  // Instruction shown before the question.
  final String instruction;

  // Main homework question.
  final String question;

  // Answer options shown to the student.
  final List<String> options;

  // Correct answer used to check the student response.
  final String correctAnswer;

  const HomeworkActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    this.levelId = 'a1',
    this.cycleId = '',
    this.skill = LearningSkill.writing,
    this.activityKind = ActivityKind.coreActivity,
    this.cefrLevel = 'A1',
    this.canDoStatement = '',
    this.passingScore = 0.75,
    required this.instruction,
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

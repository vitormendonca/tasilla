import 'activity_question.dart';
import 'learning_enums.dart';

class LearningActivity {
  final String id;
  final String levelId;
  final String cycleId;
  final String title;
  final String description;
  final String cefrLevel;
  final String canDoStatement;
  final LearningSkill skill;
  final ActivityKind activityKind;
  final double passingScore;
  final List<ActivityQuestion> questions;
  final String? audioPath;
  final String? textContent;
  final String? instructions;

  const LearningActivity({
    required this.id,
    required this.levelId,
    required this.cycleId,
    required this.title,
    required this.description,
    required this.cefrLevel,
    required this.canDoStatement,
    required this.skill,
    required this.activityKind,
    required this.passingScore,
    this.questions = const [],
    this.audioPath,
    this.textContent,
    this.instructions,
  });
}

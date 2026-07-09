import 'activity_question.dart';
import 'learning_enums.dart';

class VocabularyQuiz {
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

  // Questions connected to this vocabulary quiz.
  final List<ActivityQuestion> questions;

  const VocabularyQuiz({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    this.levelId = 'a1',
    this.cycleId = '',
    this.skill = LearningSkill.vocabularyUseOfEnglish,
    this.activityKind = ActivityKind.coreActivity,
    this.cefrLevel = 'A1',
    this.canDoStatement = '',
    this.passingScore = 0.75,
    required this.questions,
  });
}

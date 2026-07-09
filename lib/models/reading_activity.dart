import 'activity_question.dart';
import 'learning_enums.dart';

class ReadingActivity {
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

  // Main reading text shown to the student.
  final String text;

  // Questions connected to this reading activity.
  final List<ActivityQuestion> questions;

  const ReadingActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    this.levelId = 'a1',
    this.cycleId = '',
    this.skill = LearningSkill.reading,
    this.activityKind = ActivityKind.coreActivity,
    this.cefrLevel = 'A1',
    this.canDoStatement = '',
    this.passingScore = 0.75,
    required this.text,
    required this.questions,
  });
}

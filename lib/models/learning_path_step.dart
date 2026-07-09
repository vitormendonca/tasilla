import 'learning_enums.dart';

enum LearningPathStepType {
  lesson,
  reinforcement,
  review,
  checkpoint,
  portfolio,
  finalTest,
}

class LearningPathStep {
  final String id;
  final String level;
  final String skillId;
  final String skillTitle;
  final String title;
  final String description;
  final LearningPathStepType type;
  final String levelId;
  final String cycleId;
  final LearningSkill skill;
  final ActivityKind activityKind;
  final String cefrLevel;
  final String canDoStatement;
  final double passingScore;
  final int order;
  final int? lessonNumber;
  final int? reviewNumber;

  const LearningPathStep({
    required this.id,
    required this.level,
    required this.skillId,
    required this.skillTitle,
    required this.title,
    required this.description,
    required this.type,
    this.levelId = '',
    this.cycleId = '',
    this.skill = LearningSkill.mixed,
    this.activityKind = ActivityKind.coreActivity,
    this.cefrLevel = '',
    this.canDoStatement = '',
    this.passingScore = 0.75,
    required this.order,
    this.lessonNumber,
    this.reviewNumber,
  });
}

extension LearningPathStepTypeLabel on LearningPathStepType {
  String get label {
    switch (this) {
      case LearningPathStepType.lesson:
        return 'Lesson';
      case LearningPathStepType.reinforcement:
        return 'Reinforcement';
      case LearningPathStepType.review:
        return 'Review';
      case LearningPathStepType.checkpoint:
        return 'Checkpoint';
      case LearningPathStepType.portfolio:
        return 'Portfolio';
      case LearningPathStepType.finalTest:
        return 'Final Test';
    }
  }
}

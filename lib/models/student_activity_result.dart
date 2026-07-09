import 'learning_enums.dart';

class StudentActivityResult {
  final String studentId;
  final String activityId;
  final String levelId;
  final String cycleId;
  final LearningSkill skill;
  final ActivityKind activityKind;
  final double score;
  final int attempts;
  final ActivityStatus status;
  final bool needsReview;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const StudentActivityResult({
    required this.studentId,
    required this.activityId,
    required this.levelId,
    required this.cycleId,
    required this.skill,
    required this.activityKind,
    required this.score,
    required this.attempts,
    required this.status,
    required this.needsReview,
    this.startedAt,
    this.completedAt,
  });
}

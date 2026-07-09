import '../models/learning_activity.dart';
import '../models/learning_enums.dart';
import '../models/student_activity_result.dart';

class SkillProgressSummary {
  final LearningSkill skill;
  final int totalActivities;
  final int completedActivities;
  final int scoredActivities;
  final int reviewNeededActivities;
  final double completionRate;
  final double averageScore;

  const SkillProgressSummary({
    required this.skill,
    required this.totalActivities,
    required this.completedActivities,
    required this.scoredActivities,
    required this.reviewNeededActivities,
    required this.completionRate,
    required this.averageScore,
  });
}

class LevelProgressSummary {
  final String levelId;
  final int totalActivities;
  final int completedActivities;
  final int scoredActivities;
  final int reviewNeededActivities;
  final double completionRate;
  final double overallAverage;
  final Map<LearningSkill, SkillProgressSummary> skillProgress;

  const LevelProgressSummary({
    required this.levelId,
    required this.totalActivities,
    required this.completedActivities,
    required this.scoredActivities,
    required this.reviewNeededActivities,
    required this.completionRate,
    required this.overallAverage,
    required this.skillProgress,
  });
}

class LevelProgressService {
  const LevelProgressService._();

  static LevelProgressSummary calculateProgress({
    required String levelId,
    required List<LearningActivity> activities,
    required Iterable<StudentActivityResult> results,
  }) {
    final levelActivities = activities
        .where((activity) => activity.levelId == levelId)
        .toList();
    final levelResults = results
        .where((result) => result.levelId == levelId)
        .toList();
    final resultsByActivityId = {
      for (final result in levelResults) result.activityId: result,
    };
    final completedActivities = levelActivities.where((activity) {
      return resultsByActivityId[activity.id]?.status.countsAsCompleted ??
          false;
    }).length;
    final scoredResults = levelResults.where(_hasScore).toList();
    final reviewNeededActivities = levelResults
        .where(_needsReview)
        .map((result) => result.activityId)
        .toSet()
        .length;
    final totalActivities = levelActivities.length;
    final skillProgress = calculateSkillProgress(
      levelId: levelId,
      activities: levelActivities,
      results: levelResults,
    );

    return LevelProgressSummary(
      levelId: levelId,
      totalActivities: totalActivities,
      completedActivities: completedActivities,
      scoredActivities: scoredResults.length,
      reviewNeededActivities: reviewNeededActivities,
      completionRate: _rate(completedActivities, totalActivities),
      overallAverage: _average(scoredResults.map((result) => result.score)),
      skillProgress: skillProgress,
    );
  }

  static Map<LearningSkill, SkillProgressSummary> calculateSkillProgress({
    required String levelId,
    required List<LearningActivity> activities,
    required Iterable<StudentActivityResult> results,
  }) {
    final summaries = <LearningSkill, SkillProgressSummary>{};
    final levelActivities = activities
        .where((activity) => activity.levelId == levelId)
        .toList();
    final levelResults = results
        .where((result) => result.levelId == levelId)
        .toList();
    final resultsByActivityId = {
      for (final result in levelResults) result.activityId: result,
    };

    for (final skill in LearningSkill.values) {
      final skillActivities = levelActivities
          .where((activity) => activity.skill == skill)
          .toList();

      if (skillActivities.isEmpty) {
        continue;
      }

      final completedSkillActivities = skillActivities.where((activity) {
        return resultsByActivityId[activity.id]?.status.countsAsCompleted ??
            false;
      }).length;
      final skillResults = skillActivities
          .map((activity) => resultsByActivityId[activity.id])
          .whereType<StudentActivityResult>()
          .toList();
      final scoredResults = skillResults.where(_hasScore).toList();
      final reviewNeededActivities = skillResults.where(_needsReview).length;

      summaries[skill] = SkillProgressSummary(
        skill: skill,
        totalActivities: skillActivities.length,
        completedActivities: completedSkillActivities,
        scoredActivities: scoredResults.length,
        reviewNeededActivities: reviewNeededActivities,
        completionRate: _rate(completedSkillActivities, skillActivities.length),
        averageScore: _average(scoredResults.map((result) => result.score)),
      );
    }

    return summaries;
  }

  static LevelProgressSummary calculateProgressFromCompletedIds({
    required String levelId,
    required List<LearningActivity> activities,
    required Set<String> completedActivityIds,
  }) {
    final levelActivities = activities
        .where((activity) => activity.levelId == levelId)
        .toList();
    final completedActivities = levelActivities
        .where((activity) => completedActivityIds.contains(activity.id))
        .length;
    final skillProgress = <LearningSkill, SkillProgressSummary>{};

    for (final skill in LearningSkill.values) {
      final skillActivities = levelActivities
          .where((activity) => activity.skill == skill)
          .toList();

      if (skillActivities.isEmpty) {
        continue;
      }

      final completedSkillActivities = skillActivities
          .where((activity) => completedActivityIds.contains(activity.id))
          .length;

      skillProgress[skill] = SkillProgressSummary(
        skill: skill,
        totalActivities: skillActivities.length,
        completedActivities: completedSkillActivities,
        scoredActivities: 0,
        reviewNeededActivities: 0,
        completionRate: _rate(completedSkillActivities, skillActivities.length),
        averageScore: 0,
      );
    }

    return LevelProgressSummary(
      levelId: levelId,
      totalActivities: levelActivities.length,
      completedActivities: completedActivities,
      scoredActivities: 0,
      reviewNeededActivities: 0,
      completionRate: _rate(completedActivities, levelActivities.length),
      overallAverage: 0,
      skillProgress: skillProgress,
    );
  }

  static bool _hasScore(StudentActivityResult result) {
    return result.attempts > 0 && result.status != ActivityStatus.pending;
  }

  static bool _needsReview(StudentActivityResult result) {
    return result.needsReview ||
        result.status == ActivityStatus.reviewNeeded ||
        result.status == ActivityStatus.rejected;
  }

  static double _rate(int value, int total) {
    if (total == 0) {
      return 0;
    }

    return value / total;
  }

  static double _average(Iterable<double> scores) {
    final scoreList = scores.toList();

    if (scoreList.isEmpty) {
      return 0;
    }

    final total = scoreList.fold<double>(0, (sum, score) => sum + score);
    return total / scoreList.length;
  }
}

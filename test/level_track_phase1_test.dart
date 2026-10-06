import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/data/a1_content_loader.dart';
import 'package:tasilla/data/level_track_data.dart';
import 'package:tasilla/models/learning_activity.dart';
import 'package:tasilla/models/learning_enums.dart';
import 'package:tasilla/models/student_activity_result.dart';
import 'package:tasilla/services/level_progress_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadA1Content();
  });

  test('A1 level track matches the current 149-experience package', () {
    expect(a1LevelTrack.id, 'a1');
    expect(a1LevelTrack.totalCoreActivities, 100);
    expect(a1LevelTrack.totalReinforcementActivities, 0);
    expect(a1LevelTrack.totalReviews, 42);
    expect(a1LevelTrack.totalCheckpoints, 4);
    expect(a1LevelTrack.totalPortfolioTasks, 2);
    expect(a1LevelTrack.totalFinalExams, 1);
    expect(a1LevelTrack.totalLearningExperiences, 149);
    expect(getA1LearningExperiences(), hasLength(149));
    expect(a1LearningCycles, hasLength(12));
    expect(a1CertificateCriteria.minimumCompletionRate, 0.90);
    expect(a1CertificateCriteria.minimumOverallAverage, 0.75);
    expect(a1CertificateCriteria.minimumFinalExamScore, 0.75);
    expect(a1CertificateCriteria.minimumSkillAverage, 0.65);
  });

  test('A1 package preserves skill and certification activity structure', () {
    final activities = getA1LearningActivities();
    int count(ActivityKind kind) => activities.where((a) => a.activityKind == kind).length;
    expect(activities, hasLength(149));
    expect(count(ActivityKind.coreActivity), 100);
    expect(count(ActivityKind.reinforcementActivity), 0);
    expect(count(ActivityKind.review), 42);
    expect(count(ActivityKind.checkpoint), 4);
    expect(count(ActivityKind.portfolioTask), 2);
    expect(count(ActivityKind.finalExam), 1);

    final coreSkills = activities
        .where((a) => a.activityKind == ActivityKind.coreActivity)
        .map((a) => a.skill)
        .toSet();
    expect(coreSkills, containsAll([
      LearningSkill.listening,
      LearningSkill.reading,
      LearningSkill.vocabularyUseOfEnglish,
      LearningSkill.writing,
      LearningSkill.speaking,
    ]));
    expect(activities.every((a) =>
      a.levelId == 'a1' &&
      a.cycleId.isNotEmpty &&
      a.cefrLevel == 'A1' &&
      a.canDoStatement.isNotEmpty), true);
  });

  test('current content resolves representative core and review experiences', () {
    final listening = getA1LearningExperienceById('A1-T01-LIS')!;
    final speaking = getA1LearningExperienceById('A1-T01-SPE')!;
    final writing = getA1LearningExperienceById('A1-T01-WRI')!;
    final mixed = getA1LearningExperienceById('A1-MIX-A')!;

    expect(listening.primarySkill, LearningSkill.listening);
    expect(listening.listeningBlock?.listeningQuestions, hasLength(5));
    expect(speaking.primarySkill, LearningSkill.speaking);
    expect(speaking.speakingTask?.requiresTeacherReview, true);
    expect(speaking.rubric?.criteria, hasLength(4));
    expect(writing.primarySkill, LearningSkill.writing);
    expect(writing.writingTask?.requiresTeacherReview, true);
    expect(mixed.primarySkill, LearningSkill.mixed);
    expect(mixed.listeningBlock, isNotNull);
    expect(mixed.readingBlock, isNotNull);
    expect(mixed.speakingTask, isNotNull);
    expect(mixed.writingTask, isNotNull);
  });

  test('level progress calculates completion, scores and review needs', () {
    final activities = getA1LearningActivities();
    final listening = activities.firstWhere((a) => a.skill == LearningSkill.listening);
    final speaking = activities.firstWhere((a) => a.skill == LearningSkill.speaking);
    final review = activities.firstWhere((a) => a.activityKind == ActivityKind.review);

    final summary = LevelProgressService.calculateProgress(
      levelId: 'a1',
      activities: activities,
      results: [
        _resultFor(listening, score: 0.8, status: ActivityStatus.completed),
        _resultFor(speaking, score: 0.6, status: ActivityStatus.reviewNeeded, needsReview: true),
        _resultFor(review, score: 0.9, status: ActivityStatus.submitted),
      ],
    );

    expect(summary.totalActivities, 149);
    expect(summary.completedActivities, 2);
    expect(summary.scoredActivities, 3);
    expect(summary.reviewNeededActivities, 1);
    expect(summary.completionRate, closeTo(2 / 149, 0.0001));
    expect(summary.overallAverage, closeTo((0.8 + 0.6 + 0.9) / 3, 0.0001));
  });

  test('completed IDs do not invent certificate scores', () {
    final activities = getA1LearningActivities();
    final first = activities.first;
    final summary = LevelProgressService.calculateProgressFromCompletedIds(
      levelId: 'a1',
      activities: activities,
      completedActivityIds: {first.id},
    );
    expect(summary.completedActivities, 1);
    expect(summary.scoredActivities, 0);
    expect(summary.overallAverage, 0);
  });
}

StudentActivityResult _resultFor(
  LearningActivity activity, {
  required double score,
  required ActivityStatus status,
  bool needsReview = false,
}) => StudentActivityResult(
  studentId: 'student_1',
  activityId: activity.id,
  levelId: activity.levelId,
  cycleId: activity.cycleId,
  skill: activity.skill,
  activityKind: activity.activityKind,
  score: score,
  attempts: 1,
  status: status,
  needsReview: needsReview,
);

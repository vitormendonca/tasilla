import 'dart:io';

import 'package:tasilla/data/a1_learning_experience_data.dart';
import 'package:tasilla/data/level_track_data.dart';
import 'package:tasilla/data/learning_path_data.dart';
import 'package:tasilla/models/learning_activity.dart';
import 'package:tasilla/models/learning_enums.dart';
import 'package:tasilla/models/learning_path_step.dart';
import 'package:tasilla/models/student_activity_result.dart';
import 'package:tasilla/services/level_progress_service.dart';

void main() {
  _verifyA1LaunchRoadmap();
  _verifySharedSkillPaths();
  _verifyPhase1LevelTrack();
  _verifyA1ContentPackageDetails();
  _verifyPhase1Progress();

  stdout.writeln('Learning path data verified.');
}

void _verifyA1ContentPackageDetails() {
  final exp001 = getA1LearningExperienceById('A1-EXP-001');
  final exp010 = getA1LearningExperienceById('A1-EXP-010');
  final exp011 = getA1LearningExperienceById('A1-EXP-011');
  final exp020 = getA1LearningExperienceById('A1-EXP-020');
  final firstReinforcement = getA1LearningExperienceById('A1-REF-001');

  _expect(exp001 != null, 'A1-EXP-001 should exist.');
  _expect(exp010 != null, 'A1-EXP-010 should exist.');
  _expect(exp011 != null, 'A1-EXP-011 should exist.');
  _expect(exp020 != null, 'A1-EXP-020 should exist.');
  _expect(firstReinforcement != null, 'A1-REF-001 should exist.');
  _expect(exp001!.title == 'Introducing Yourself', 'EXP 001 title mismatch.');
  _expect(
    exp001.listeningBlock?.audioPath ==
        'assets/audio/a1/a1_exp_001_meeting_anna.mp3',
    'EXP 001 planned audio path mismatch.',
  );
  _expect(
    exp001.readingBlock?.readingText.contains('My name is Lucas') ?? false,
    'EXP 001 package reading text should be present.',
  );
  _expect(
    exp001.quizBlock?.questions.length == 2,
    'EXP 001 should keep package comprehension questions.',
  );
  _expect(
    exp010!.primarySkill == LearningSkill.mixed,
    'EXP 010 should be an integrated foundation challenge.',
  );
  _expect(exp011!.title == 'My Family', 'EXP 011 title mismatch.');
  _expect(
    exp011.listeningBlock?.audioPath ==
        'assets/audio/a1/a1_exp_011_my_family.mp3',
    'EXP 011 planned audio path mismatch.',
  );
  _expect(
    exp011.readingBlock?.readingText.contains('My name is Emma') ?? false,
    'EXP 011 package reading text should be present.',
  );
  _expect(
    exp020!.primarySkill == LearningSkill.mixed,
    'EXP 020 should be an integrated personal life challenge.',
  );
  _expect(
    exp020.listeningBlock?.audioPath ==
        'assets/audio/a1/a1_exp_020_personal_life_challenge.mp3',
    'EXP 020 planned audio path mismatch.',
  );
  _expect(
    exp020.quizBlock?.questions.length == 4,
    'EXP 020 should keep integrated challenge questions.',
  );
  for (var number = 11; number <= 20; number++) {
    final id = 'A1-EXP-${number.toString().padLeft(3, '0')}';
    final experience = getA1LearningExperienceById(id);
    _expect(experience != null, '$id should exist.');
    _expect(
      experience!.listeningBlock?.audioStatus == 'pending_generation',
      '$id should keep audio pending.',
    );
    _expect(
      experience.listeningBlock?.audioScript.trim().isNotEmpty ?? false,
      '$id should render a listening fallback script.',
    );
    _expect(
      experience.readingBlock?.readingText.trim().isNotEmpty ?? false,
      '$id should render reading content.',
    );
    _expect(
      (experience.quizBlock?.questions.length ?? 0) >= 2,
      '$id should include comprehension questions.',
    );
    _expect(
      experience.writingTask?.writingPrompt.trim().isNotEmpty ?? false,
      '$id should include a writing prompt.',
    );
    _expect(
      experience.speakingTask?.speakingPrompt.trim().isNotEmpty ?? false,
      '$id should include a speaking prompt.',
    );
    _expect(experience.passingScore == 0.75, '$id passing score mismatch.');
  }
  _expect(
    firstReinforcement!.title.contains('Verb To Be Mastery'),
    'First reinforcement should follow package title.',
  );
}

void _verifyA1LaunchRoadmap() {
  final roadSteps = getA1RoadmapSteps();
  final core = _stepsForKind(roadSteps, ActivityKind.coreActivity);
  final reinforcements = _stepsForKind(
    roadSteps,
    ActivityKind.reinforcementActivity,
  );
  final reviews = _stepsForKind(roadSteps, ActivityKind.review);
  final checkpoints = _stepsForKind(roadSteps, ActivityKind.checkpoint);
  final portfolio = _stepsForKind(roadSteps, ActivityKind.portfolioTask);
  final finalExams = _stepsForKind(roadSteps, ActivityKind.finalExam);

  _expect(
    roadSteps.length == a1LaunchExperienceLimit,
    'A1 launch Road Map should expose only EXP 001 to 020.',
  );
  _expect(
    core.length == a1LaunchExperienceLimit,
    'A1 launch Road Map should have 20 core experiences.',
  );
  _expect(
    reinforcements.isEmpty,
    'A1 launch Road Map should hide templated reinforcements.',
  );
  _expect(reviews.isEmpty, 'A1 launch Road Map should hide draft reviews.');
  _expect(
    checkpoints.isEmpty,
    'A1 launch Road Map should hide draft checkpoints.',
  );
  _expect(portfolio.isEmpty, 'A1 launch Road Map should hide portfolio tasks.');
  _expect(finalExams.isEmpty, 'A1 launch Road Map should hide the final exam.');
  _expect(roadSteps.first.id == 'A1-EXP-001', 'First A1 experience mismatch.');
  _expect(
    roadSteps.last.id == 'A1-EXP-020',
    'Last launch A1 experience mismatch.',
  );
}

void _verifySharedSkillPaths() {
  for (final skill in learningSkillDefinitions) {
    final skillSteps = getLearningPathStepsBySkill(skill.id);
    _expect(skillSteps.isNotEmpty, '${skill.id} should expose A1 experiences.');
    _expect(
      skillSteps.every((step) => getA1LearningExperienceById(step.id) != null),
      '${skill.id} should only reference authored A1 experiences.',
    );
  }
}

void _verifyPhase1LevelTrack() {
  final activities = getA1LearningActivities();
  final coreActivities = activities
      .where((activity) => activity.activityKind == ActivityKind.coreActivity)
      .toList();
  final reinforcements = activities
      .where(
        (activity) =>
            activity.activityKind == ActivityKind.reinforcementActivity,
      )
      .toList();
  final reviews = activities
      .where((activity) => activity.activityKind == ActivityKind.review)
      .toList();
  final checkpoints = activities
      .where((activity) => activity.activityKind == ActivityKind.checkpoint)
      .toList();
  final portfolio = activities
      .where((activity) => activity.activityKind == ActivityKind.portfolioTask)
      .toList();
  final finalExams = activities
      .where((activity) => activity.activityKind == ActivityKind.finalExam)
      .toList();
  final coreSkills = coreActivities.map((activity) => activity.skill).toSet();

  _expect(
    a1LevelTrack.totalLearningExperiences == 70,
    'A1 official track should describe 70 learning experiences.',
  );
  _expect(
    a1LearningExperiences.length == 70,
    'A1 LearningExperience mock data should have 70 items.',
  );
  _expect(a1LearningCycles.length == 12, 'A1 should keep 12 topic cycles.');
  _expect(coreActivities.length == 40, 'A1 should bridge 40 core activities.');
  _expect(reinforcements.length == 18, 'A1 should bridge 18 reinforcements.');
  _expect(reviews.length == 6, 'A1 should bridge 6 mixed reviews.');
  _expect(checkpoints.length == 3, 'A1 should bridge 3 checkpoints.');
  _expect(portfolio.length == 2, 'A1 should bridge 2 portfolio tasks.');
  _expect(finalExams.length == 1, 'A1 should have one final exam activity.');
  _expect(
    coreSkills.containsAll({
      LearningSkill.listening,
      LearningSkill.reading,
      LearningSkill.vocabularyUseOfEnglish,
      LearningSkill.writing,
      LearningSkill.speaking,
    }),
    'A1 core activities should cover the five official skills.',
  );
  _expect(
    activities.every(
      (activity) =>
          activity.levelId == 'a1' &&
          activity.cycleId.isNotEmpty &&
          activity.cefrLevel == 'A1' &&
          activity.canDoStatement.isNotEmpty &&
          activity.passingScore == 0.75,
    ),
    'Every A1 activity should have Phase 1 metadata.',
  );
}

void _verifyPhase1Progress() {
  final activities = getA1LearningActivities();
  final listening = activities.firstWhere(
    (activity) => activity.skill == LearningSkill.listening,
  );
  final speaking = activities.firstWhere(
    (activity) => activity.skill == LearningSkill.speaking,
  );
  final review = activities.firstWhere(
    (activity) => activity.activityKind == ActivityKind.review,
  );

  final summary = LevelProgressService.calculateProgress(
    levelId: 'a1',
    activities: activities,
    results: [
      _resultFor(listening, score: 0.8, status: ActivityStatus.completed),
      _resultFor(
        speaking,
        score: 0.6,
        status: ActivityStatus.reviewNeeded,
        needsReview: true,
      ),
      _resultFor(review, score: 0.9, status: ActivityStatus.submitted),
    ],
  );

  _expect(summary.totalActivities == 70, 'Progress should see 70 activities.');
  _expect(
    summary.completedActivities == 2,
    'Progress should count completed/submitted activities only.',
  );
  _expect(summary.scoredActivities == 3, 'Progress should count real scores.');
  _expect(
    summary.reviewNeededActivities == 1,
    'Progress should count review-needed activities.',
  );

  final fromCompletedIds =
      LevelProgressService.calculateProgressFromCompletedIds(
        levelId: 'a1',
        activities: activities,
        completedActivityIds: {activities.first.id},
      );

  _expect(
    fromCompletedIds.overallAverage == 0,
    'Completed IDs should not create fake certificate scores.',
  );
}

List<LearningPathStep> _stepsForKind(
  List<LearningPathStep> steps,
  ActivityKind kind,
) {
  return steps.where((step) => step.activityKind == kind).toList();
}

StudentActivityResult _resultFor(
  LearningActivity activity, {
  required double score,
  required ActivityStatus status,
  bool needsReview = false,
}) {
  return StudentActivityResult(
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
}

void _expect(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

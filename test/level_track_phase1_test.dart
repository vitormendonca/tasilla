import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/data/a1_learning_experience_data.dart';
import 'package:tasilla/data/level_track_data.dart';
import 'package:tasilla/data/learning_path_data.dart';
import 'package:tasilla/models/learning_activity.dart';
import 'package:tasilla/models/learning_enums.dart';
import 'package:tasilla/models/learning_experience.dart';
import 'package:tasilla/models/student_activity_result.dart';
import 'package:tasilla/services/level_progress_service.dart';

void main() {
  test('A1 level track keeps the official certificate structure metadata', () {
    expect(a1LevelTrack.id, 'a1');
    expect(a1LevelTrack.totalCoreActivities, 40);
    expect(a1LevelTrack.totalReinforcementActivities, 18);
    expect(a1LevelTrack.totalReviews, 6);
    expect(a1LevelTrack.totalCheckpoints, 3);
    expect(a1LevelTrack.totalPortfolioTasks, 2);
    expect(a1LevelTrack.totalFinalExams, 1);
    expect(a1LevelTrack.totalLearningExperiences, 70);
    expect(a1CertificateCriteria.minimumCompletionRate, 0.90);
    expect(a1CertificateCriteria.minimumOverallAverage, 0.75);
    expect(a1CertificateCriteria.minimumFinalExamScore, 0.75);
    expect(a1CertificateCriteria.minimumSkillAverage, 0.65);
    expect(a1CertificateCriteria.minimumSpeakingSubmissions, 10);
    expect(a1CertificateCriteria.minimumWritingSubmissions, 10);
    expect(a1LearningCycles, hasLength(12));
    expect(a1LearningExperiences, hasLength(70));
  });

  test(
    'A1 source package retains the full certificate structure for later phases',
    () {
      final roadmapSteps = getA1RoadmapSteps();
      final activities = getA1LearningActivities();
      final coreActivities = activities
          .where(
            (activity) => activity.activityKind == ActivityKind.coreActivity,
          )
          .toList();
      final reinforcementActivities = activities
          .where(
            (activity) =>
                activity.activityKind == ActivityKind.reinforcementActivity,
          )
          .toList();
      final reviewActivities = activities
          .where((activity) => activity.activityKind == ActivityKind.review)
          .toList();
      final checkpointActivities = activities
          .where((activity) => activity.activityKind == ActivityKind.checkpoint)
          .toList();
      final portfolioActivities = activities
          .where(
            (activity) => activity.activityKind == ActivityKind.portfolioTask,
          )
          .toList();
      final finalExamActivities = activities
          .where((activity) => activity.activityKind == ActivityKind.finalExam)
          .toList();
      final coreSkills = coreActivities
          .map((activity) => activity.skill)
          .toSet();
      final integratedCoreActivities = coreActivities
          .where((activity) => activity.skill == LearningSkill.mixed)
          .toList();

      expect(roadmapSteps, hasLength(a1LaunchExperienceLimit));
      expect(activities, hasLength(70));
      expect(coreActivities, hasLength(40));
      expect(reinforcementActivities, hasLength(18));
      expect(reviewActivities, hasLength(6));
      expect(checkpointActivities, hasLength(3));
      expect(portfolioActivities, hasLength(2));
      expect(finalExamActivities, hasLength(1));
      expect(coreSkills, contains(LearningSkill.listening));
      expect(coreSkills, contains(LearningSkill.reading));
      expect(coreSkills, contains(LearningSkill.vocabularyUseOfEnglish));
      expect(coreSkills, contains(LearningSkill.writing));
      expect(coreSkills, contains(LearningSkill.speaking));
      expect(integratedCoreActivities, hasLength(3));
      expect(
        activities.every(
          (activity) =>
              activity.levelId == 'a1' &&
              activity.cycleId.isNotEmpty &&
              activity.cefrLevel == 'A1' &&
              activity.canDoStatement.isNotEmpty &&
              activity.passingScore == 0.75,
        ),
        true,
      );
    },
  );

  test('LearningExperience supports JSON-ready content and optional audio', () {
    final listening = a1LearningExperiences.firstWhere(
      (experience) => experience.primarySkill == LearningSkill.listening,
    );
    final decoded = LearningExperience.fromJson(listening.toJson());
    final portfolio = a1LearningExperiences.firstWhere(
      (experience) => experience.activityKind == ActivityKind.portfolioTask,
    );

    expect(decoded.id, listening.id);
    expect(decoded.status, LearningExperienceStatus.published);
    expect(decoded.listeningBlock?.audioScript, isNotEmpty);
    expect(decoded.hasPlannedAudio, true);
    expect(decoded.listeningBlock?.audioPath, startsWith('assets/audio/a1/'));
    expect(portfolio.requiresTeacherReview, true);
    expect(portfolio.rubric?.criteria, isNotEmpty);
  });

  test('A1 content package details are mapped into the first experiences', () {
    final exp001 = getA1LearningExperienceById('A1-EXP-001')!;
    final exp002 = getA1LearningExperienceById('A1-EXP-002')!;
    final exp010 = getA1LearningExperienceById('A1-EXP-010')!;
    final exp011 = getA1LearningExperienceById('A1-EXP-011')!;
    final exp020 = getA1LearningExperienceById('A1-EXP-020')!;
    final firstReinforcement = getA1LearningExperienceById('A1-REF-001')!;

    expect(exp001.title, 'Introducing Yourself');
    expect(exp001.primarySkill, LearningSkill.speaking);
    expect(exp001.secondarySkills, [
      LearningSkill.listening,
      LearningSkill.reading,
    ]);
    expect(exp001.difficultyLevel, 1);
    expect(exp001.estimatedMinutes, 10);
    expect(exp001.listeningBlock?.audioStatus, 'pending_generation');
    expect(
      exp001.listeningBlock?.audioPath,
      'assets/audio/a1/a1_exp_001_meeting_anna.mp3',
    );
    expect(exp001.listeningBlock?.audioScript, contains('My name is Anna'));
    expect(exp001.readingBlock?.readingText, contains('My name is Lucas'));
    expect(exp001.quizBlock?.questions, hasLength(2));
    expect(exp001.writingTask?.writingPrompt, contains('Introduce yourself'));
    expect(exp001.speakingTask?.maxRecordingSeconds, 45);

    expect(exp002.primarySkill, LearningSkill.listening);
    expect(exp002.listeningBlock?.numberOfSpeakers, 2);
    expect(exp010.primarySkill, LearningSkill.mixed);
    expect(exp010.quizBlock?.questions, hasLength(3));
    expect(exp011.title, 'My Family');
    expect(
      exp011.listeningBlock?.audioPath,
      'assets/audio/a1/a1_exp_011_my_family.mp3',
    );
    expect(exp011.readingBlock?.readingText, contains('My name is Emma'));
    expect(exp020.title, 'Personal Life Challenge');
    expect(exp020.primarySkill, LearningSkill.mixed);
    expect(
      exp020.listeningBlock?.audioPath,
      'assets/audio/a1/a1_exp_020_personal_life_challenge.mp3',
    );
    expect(exp020.quizBlock?.questions, hasLength(4));
    expect(exp020.speakingTask?.maxRecordingSeconds, 120);
    for (var number = 11; number <= 20; number++) {
      final id = 'A1-EXP-${number.toString().padLeft(3, '0')}';
      final experience = getA1LearningExperienceById(id)!;

      expect(
        experience.listeningBlock?.audioStatus,
        'pending_generation',
        reason: '$id should keep audio pending.',
      );
      expect(
        experience.listeningBlock?.audioScript.trim(),
        isNotEmpty,
        reason: '$id should render listening fallback script.',
      );
      expect(
        experience.readingBlock?.readingText.trim(),
        isNotEmpty,
        reason: '$id should render reading content.',
      );
      expect(
        experience.quizBlock?.questions.length,
        greaterThanOrEqualTo(2),
        reason: '$id should include comprehension questions.',
      );
      expect(
        experience.writingTask?.writingPrompt.trim(),
        isNotEmpty,
        reason: '$id should include a writing prompt.',
      );
      expect(
        experience.speakingTask?.speakingPrompt.trim(),
        isNotEmpty,
        reason: '$id should include a speaking prompt.',
      );
      expect(experience.passingScore, 0.75);
    }
    expect(firstReinforcement.title, contains('Verb To Be Mastery'));
  });

  test('level progress calculates completion, scores and review needs', () {
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

    expect(summary.totalActivities, 70);
    expect(summary.completedActivities, 2);
    expect(summary.scoredActivities, 3);
    expect(summary.reviewNeededActivities, 1);
    expect(summary.completionRate, closeTo(2 / 70, 0.0001));
    expect(summary.overallAverage, closeTo((0.8 + 0.6 + 0.9) / 3, 0.0001));

    final listeningProgress = summary.skillProgress[LearningSkill.listening]!;
    final speakingProgress = summary.skillProgress[LearningSkill.speaking]!;
    final mixedProgress = summary.skillProgress[LearningSkill.mixed]!;

    expect(listeningProgress.completedActivities, 1);
    expect(listeningProgress.averageScore, 0.8);
    expect(speakingProgress.completedActivities, 0);
    expect(speakingProgress.reviewNeededActivities, 1);
    expect(speakingProgress.averageScore, 0.6);
    expect(mixedProgress.completedActivities, 1);
  });

  test(
    'completed IDs calculate progress without inventing certificate scores',
    () {
      final activities = getA1LearningActivities();
      final firstActivity = activities.first;

      final summary = LevelProgressService.calculateProgressFromCompletedIds(
        levelId: 'a1',
        activities: activities,
        completedActivityIds: {firstActivity.id},
      );

      expect(summary.completedActivities, 1);
      expect(summary.scoredActivities, 0);
      expect(summary.overallAverage, 0);
      expect(
        summary.skillProgress[firstActivity.skill]!.completedActivities,
        1,
      );
      expect(summary.skillProgress[firstActivity.skill]!.scoredActivities, 0);
    },
  );
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

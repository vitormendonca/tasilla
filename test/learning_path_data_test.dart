import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/data/a1_learning_experience_data.dart';
import 'package:tasilla/data/learning_path_data.dart';
import 'package:tasilla/models/learning_enums.dart';
import 'package:tasilla/models/learning_path_step.dart';

void main() {
  test('A1 roadmap exposes the official 70-experience structure', () {
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

    expect(roadSteps, hasLength(70));
    expect(core, hasLength(40));
    expect(reinforcements, hasLength(18));
    expect(reviews, hasLength(6));
    expect(checkpoints, hasLength(3));
    expect(portfolio, hasLength(2));
    expect(finalExams, hasLength(1));

    expect(
      core.every((step) => step.type == LearningPathStepType.lesson),
      true,
    );
    expect(
      reinforcements.every(
        (step) => step.type == LearningPathStepType.reinforcement,
      ),
      true,
    );
    expect(
      checkpoints.every((step) => step.type == LearningPathStepType.checkpoint),
      true,
    );
    expect(
      portfolio.every((step) => step.type == LearningPathStepType.portfolio),
      true,
    );
    expect(finalExams.single.type, LearningPathStepType.finalTest);
    expect(roadSteps.first.id, 'A1-EXP-001');
    expect(roadSteps.last.id, 'A1-FINAL-EXAM');
    expect(
      roadSteps.every(
        (step) =>
            step.levelId == 'a1' &&
            step.skillId == a1RoadmapSkillId &&
            step.cefrLevel == 'A1' &&
            step.canDoStatement.isNotEmpty,
      ),
      true,
    );
  });

  test('legacy per-skill paths remain available for the MVP flow', () {
    final skillLessonIds = {
      for (final skill in learningSkillDefinitions)
        ...getLearningPathStepsBySkill(skill.id)
            .where((step) => step.type == LearningPathStepType.lesson)
            .map((step) => step.id),
    };

    for (final skill in learningSkillDefinitions) {
      final skillSteps = getLearningPathStepsBySkill(skill.id);
      final lessons = skillSteps
          .where((step) => step.type == LearningPathStepType.lesson)
          .toList();
      final reviews = skillSteps
          .where((step) => step.type == LearningPathStepType.review)
          .toList();
      final finals = skillSteps
          .where((step) => step.type == LearningPathStepType.finalTest)
          .toList();

      expect(lessons, hasLength(12));
      expect(reviews, hasLength(4));
      expect(finals, hasLength(1));
    }

    expect(skillLessonIds, contains('listening_a1_lesson_1'));
    expect(skillLessonIds, isNot(contains('A1-EXP-001')));
  });

  test('A1 certificate journey exposes package-backed EXP 001 to 020', () {
    final certificateSteps = getA1RoadmapSteps()
        .where(
          (step) =>
              step.activityKind == ActivityKind.coreActivity &&
              (step.lessonNumber ?? 0) >= 1 &&
              (step.lessonNumber ?? 0) <= 20,
        )
        .toList();

    expect(
      certificateSteps.map((step) => step.id),
      List.generate(
        20,
        (index) => 'A1-EXP-${(index + 1).toString().padLeft(3, '0')}',
      ),
    );
    expect(
      certificateSteps.every(
        (step) => getA1LearningExperienceById(step.id) != null,
      ),
      true,
    );
  });
}

List<LearningPathStep> _stepsForKind(
  List<LearningPathStep> steps,
  ActivityKind kind,
) {
  return steps.where((step) => step.activityKind == kind).toList();
}


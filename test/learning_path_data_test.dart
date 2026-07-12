import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/data/a1_learning_experience_data.dart';
import 'package:tasilla/data/learning_path_data.dart';
import 'package:tasilla/models/learning_enums.dart';
import 'package:tasilla/models/learning_path_step.dart';

void main() {
  test('A1 launch roadmap exposes only polished EXP 001 to 020', () {
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

    expect(roadSteps, hasLength(a1LaunchExperienceLimit));
    expect(core, hasLength(a1LaunchExperienceLimit));
    expect(reinforcements, isEmpty);
    expect(reviews, isEmpty);
    expect(checkpoints, isEmpty);
    expect(portfolio, isEmpty);
    expect(finalExams, isEmpty);

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
    expect(roadSteps.first.id, 'A1-EXP-001');
    expect(roadSteps.last.id, 'A1-EXP-020');
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

  test('skill paths reuse published A1 experiences', () {
    for (final skill in learningSkillDefinitions) {
      final skillSteps = getLearningPathStepsBySkill(skill.id);
      expect(skillSteps, isNotEmpty);
      expect(
        skillSteps.every(
          (step) => getA1LearningExperienceById(step.id) != null,
        ),
        true,
      );
      expect(skillSteps.every((step) => step.skillId == skill.id), true);
    }

    final listening = getLearningPathStepsBySkill('listening');
    expect(
      listening,
      contains(
        predicate<LearningPathStep>((step) {
          final experience = getA1LearningExperienceById(step.id)!;
          return experience.listeningBlock?.hasPlannedAudioPath ?? false;
        }),
      ),
    );
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

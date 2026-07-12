import '../models/learning_path_step.dart';
import '../models/learning_enums.dart';
import '../models/learning_experience.dart';
import 'a1_learning_experience_data.dart';

const String a1RoadmapSkillId = 'a1_roadmap';
const int a1LaunchExperienceLimit = 20;

class LearningSkillDefinition {
  final String id;
  final String title;
  final String description;

  const LearningSkillDefinition({
    required this.id,
    required this.title,
    required this.description,
  });
}

const List<LearningSkillDefinition> learningSkillDefinitions = [
  LearningSkillDefinition(
    id: 'listening',
    title: 'Listening',
    description: 'Audio comprehension, dictation and listening confidence.',
  ),
  LearningSkillDefinition(
    id: 'speaking',
    title: 'Speaking',
    description: 'Guided prompts, pronunciation practice and oral fluency.',
  ),
  LearningSkillDefinition(
    id: 'reading',
    title: 'Reading',
    description: 'Short texts, key vocabulary and comprehension practice.',
  ),
  LearningSkillDefinition(
    id: 'vocabulary',
    title: 'Vocabulary',
    description: 'Themed words, usage in context and cumulative review.',
  ),
  LearningSkillDefinition(
    id: 'homework',
    title: 'Grammar & Practice',
    description: 'Grammar patterns, sentence building and written practice.',
  ),
];

final List<LearningPathStep> a1RoadmapSteps =
    _buildA1RoadmapStepsFromExperiences();

final List<LearningPathStep> learningPathSteps = [
  for (final skill in learningSkillDefinitions) ..._buildSkillPath(skill),
  ...a1RoadmapSteps,
];

LearningSkillDefinition? getLearningSkillDefinition(String skillId) {
  for (final skill in learningSkillDefinitions) {
    if (skill.id == skillId) {
      return skill;
    }
  }

  return null;
}

List<LearningPathStep> getLearningPathStepsBySkill(String skillId) {
  final skill = _skillForSkillId(skillId);
  return _getA1LaunchExperiences()
      .where(
        (experience) =>
            experience.status == LearningExperienceStatus.published &&
            experience.primarySkill == skill,
      )
      .map((experience) => _skillPathStepFromExperience(experience, skillId))
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));
}

List<LearningPathStep> getA1RoadmapSteps() {
  return List.unmodifiable(a1RoadmapSteps);
}

List<LearningPathStep> _buildA1RoadmapStepsFromExperiences() {
  return _getA1LaunchExperiences().map(_roadmapStepFromExperience).toList()
    ..sort((a, b) => a.order.compareTo(b.order));
}

Iterable<LearningExperience> _getA1LaunchExperiences() {
  return getA1LearningExperiences().where((experience) {
    if (experience.activityKind != ActivityKind.coreActivity) {
      return false;
    }

    final number = _numberFromExperienceId(experience.id, 'A1-EXP-');
    return number != null && number <= a1LaunchExperienceLimit;
  });
}

LearningPathStep _roadmapStepFromExperience(LearningExperience experience) {
  return LearningPathStep(
    id: experience.id,
    level: experience.level,
    skillId: a1RoadmapSkillId,
    skillTitle: _skillTitleForRoadmap(experience),
    title: experience.title,
    description: experience.description,
    type: _stepTypeForExperienceKind(experience.activityKind),
    levelId: 'a1',
    cycleId: experience.unitId,
    skill: experience.primarySkill,
    activityKind: experience.activityKind,
    cefrLevel: experience.cefrLevel,
    canDoStatement: experience.canDoStatement,
    passingScore: experience.passingScore,
    order: experience.order,
    lessonNumber: experience.activityKind == ActivityKind.coreActivity
        ? _numberFromExperienceId(experience.id, 'A1-EXP-')
        : null,
    reviewNumber: experience.activityKind == ActivityKind.review
        ? _numberFromExperienceId(experience.id, 'A1-REV-')
        : null,
  );
}

LearningPathStep _skillPathStepFromExperience(
  LearningExperience experience,
  String skillId,
) {
  final definition = getLearningSkillDefinition(skillId);
  return LearningPathStep(
    id: experience.id,
    level: experience.level,
    skillId: skillId,
    skillTitle: definition?.title ?? experience.primarySkill.label,
    title: experience.title,
    description: experience.description,
    type: _stepTypeForExperienceKind(experience.activityKind),
    levelId: 'a1',
    cycleId: experience.unitId,
    skill: experience.primarySkill,
    activityKind: experience.activityKind,
    cefrLevel: experience.cefrLevel,
    canDoStatement: experience.canDoStatement,
    passingScore: experience.passingScore,
    order: experience.order,
    lessonNumber: experience.activityKind == ActivityKind.coreActivity
        ? _numberFromExperienceId(experience.id, 'A1-EXP-')
        : null,
    reviewNumber: experience.activityKind == ActivityKind.review
        ? _numberFromExperienceId(experience.id, 'A1-REV-')
        : null,
  );
}

LearningPathStepType _stepTypeForExperienceKind(ActivityKind kind) {
  switch (kind) {
    case ActivityKind.coreActivity:
      return LearningPathStepType.lesson;
    case ActivityKind.reinforcementActivity:
      return LearningPathStepType.reinforcement;
    case ActivityKind.review:
      return LearningPathStepType.review;
    case ActivityKind.checkpoint:
      return LearningPathStepType.checkpoint;
    case ActivityKind.portfolioTask:
      return LearningPathStepType.portfolio;
    case ActivityKind.finalExam:
      return LearningPathStepType.finalTest;
  }
}

String _skillTitleForRoadmap(LearningExperience experience) {
  if (experience.primarySkill == LearningSkill.mixed) {
    return 'Mixed Skills';
  }

  return experience.primarySkill.label;
}

int? _numberFromExperienceId(String id, String prefix) {
  if (!id.startsWith(prefix)) {
    return null;
  }

  return int.tryParse(id.substring(prefix.length));
}

List<LearningPathStep> _buildSkillPath(LearningSkillDefinition skill) {
  final steps = <LearningPathStep>[];
  int order = 1;

  for (int group = 1; group <= 4; group++) {
    for (int lessonInGroup = 1; lessonInGroup <= 3; lessonInGroup++) {
      final lessonNumber = ((group - 1) * 3) + lessonInGroup;

      steps.add(
        LearningPathStep(
          id: '${skill.id}_a1_lesson_$lessonNumber',
          level: 'A1',
          skillId: skill.id,
          skillTitle: skill.title,
          title: '${skill.title} Lesson $lessonNumber',
          description: _lessonDescription(skill.id, lessonNumber),
          type: LearningPathStepType.lesson,
          levelId: 'a1',
          cycleId: _cycleIdForLesson(lessonNumber),
          skill: _skillForSkillId(skill.id),
          activityKind: ActivityKind.coreActivity,
          cefrLevel: 'A1',
          canDoStatement: _canDoStatementForLesson(lessonNumber),
          passingScore: 0.75,
          order: order,
          lessonNumber: lessonNumber,
        ),
      );

      order++;
    }

    steps.add(
      LearningPathStep(
        id: '${skill.id}_a1_review_$group',
        level: 'A1',
        skillId: skill.id,
        skillTitle: skill.title,
        title: '${skill.title} Review $group',
        description: 'Review lessons ${((group - 1) * 3) + 1} to ${group * 3}.',
        type: LearningPathStepType.review,
        levelId: 'a1',
        cycleId: _cycleIdForLesson(group * 3),
        skill: _skillForSkillId(skill.id),
        activityKind: ActivityKind.review,
        cefrLevel: 'A1',
        canDoStatement:
            'Review and consolidate recent ${skill.title} practice.',
        passingScore: 0.75,
        order: order,
        reviewNumber: group,
      ),
    );

    order++;
  }

  steps.add(
    LearningPathStep(
      id: '${skill.id}_a1_final_test',
      level: 'A1',
      skillId: skill.id,
      skillTitle: skill.title,
      title: 'A1 ${skill.title} Final Test',
      description:
          'A stronger cumulative test for the full A1 ${skill.title} path.',
      type: LearningPathStepType.finalTest,
      levelId: 'a1',
      cycleId: 'a1_final',
      skill: _skillForSkillId(skill.id),
      activityKind: ActivityKind.finalExam,
      cefrLevel: 'A1',
      canDoStatement: 'Demonstrate A1 ${skill.title} ability.',
      passingScore: 0.75,
      order: order,
    ),
  );

  return steps;
}

String _cycleIdForLesson(int lessonNumber) {
  return 'a1_cycle_$lessonNumber';
}

LearningSkill _skillForSkillId(String skillId) {
  switch (skillId) {
    case 'listening':
      return LearningSkill.listening;
    case 'speaking':
      return LearningSkill.speaking;
    case 'reading':
      return LearningSkill.reading;
    case 'vocabulary':
      return LearningSkill.vocabularyUseOfEnglish;
    case 'homework':
      return LearningSkill.writing;
    default:
      return LearningSkill.mixed;
  }
}

String _canDoStatementForLesson(int lessonNumber) {
  switch (lessonNumber) {
    case 1:
      return 'Introduce yourself and recognize basic greetings.';
    case 2:
      return 'Share and understand simple personal information.';
    case 3:
      return 'Talk about family and people using simple language.';
    case 4:
      return 'Describe basic daily routines.';
    case 5:
      return 'Use numbers, time and days in simple contexts.';
    case 6:
      return 'Express likes, dislikes and preferences.';
    case 7:
      return 'Identify places in town and simple directions.';
    case 8:
      return 'Follow classroom instructions and learning language.';
    case 9:
      return 'Handle simple shopping and ordering situations.';
    case 10:
      return 'Talk simply about work and study.';
    case 11:
      return 'Understand and write short messages and notices.';
    case 12:
      return 'Integrate core A1 skills in familiar situations.';
    default:
      return 'Complete an A1 learning activity.';
  }
}

String _lessonDescription(String skillId, int lessonNumber) {
  switch (skillId) {
    case 'listening':
      return 'Listen, understand the main idea and answer short questions.';
    case 'speaking':
      return 'Practice a guided speaking prompt and build oral confidence.';
    case 'reading':
      return 'Read a short text and answer comprehension questions.';
    case 'vocabulary':
      return 'Learn themed vocabulary and use it in short sentences.';
    case 'homework':
      return 'Practice grammar and sentence structure with guided tasks.';
    default:
      return 'Complete the practice activity and keep moving forward.';
  }
}

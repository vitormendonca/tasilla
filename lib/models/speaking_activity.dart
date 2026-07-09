import 'learning_enums.dart';

class SpeakingActivity {
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
  final String prompt;
  final String targetLanguage;
  final String preparationTip;
  final List<String> checklist;

  const SpeakingActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    this.levelId = 'a1',
    this.cycleId = '',
    this.skill = LearningSkill.speaking,
    this.activityKind = ActivityKind.coreActivity,
    this.cefrLevel = 'A1',
    this.canDoStatement = '',
    this.passingScore = 0.75,
    required this.prompt,
    required this.targetLanguage,
    required this.preparationTip,
    required this.checklist,
  });
}

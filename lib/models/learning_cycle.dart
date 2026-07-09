import 'learning_enums.dart';

class LearningCycle {
  final String id;
  final String levelId;
  final int cycleNumber;
  final String title;
  final String canDoStatement;
  final List<String> targetLanguage;
  final List<LearningSkill> skillsIncluded;

  const LearningCycle({
    required this.id,
    required this.levelId,
    required this.cycleNumber,
    required this.title,
    required this.canDoStatement,
    required this.targetLanguage,
    required this.skillsIncluded,
  });
}

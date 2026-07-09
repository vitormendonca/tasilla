import 'certificate_criteria.dart';

class LevelTrack {
  final String id;
  final String title;
  final String level;
  final String description;
  final int totalCoreActivities;
  final int totalReinforcementActivities;
  final int totalReviews;
  final int totalCheckpoints;
  final int totalPortfolioTasks;
  final int totalFinalExams;
  final CertificateCriteria certificateCriteria;

  const LevelTrack({
    required this.id,
    required this.title,
    required this.level,
    required this.description,
    required this.totalCoreActivities,
    required this.totalReinforcementActivities,
    required this.totalReviews,
    required this.totalCheckpoints,
    required this.totalPortfolioTasks,
    required this.totalFinalExams,
    required this.certificateCriteria,
  });

  int get totalLearningExperiences {
    return totalCoreActivities +
        totalReinforcementActivities +
        totalReviews +
        totalCheckpoints +
        totalPortfolioTasks +
        totalFinalExams;
  }
}

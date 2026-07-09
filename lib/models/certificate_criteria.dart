class CertificateCriteria {
  final double minimumCompletionRate;
  final double minimumOverallAverage;
  final double minimumFinalExamScore;
  final double minimumSkillAverage;
  final int minimumSpeakingSubmissions;
  final int minimumWritingSubmissions;
  final bool requireAllReviewsCompleted;
  final bool requireAllCheckpointsCompleted;

  const CertificateCriteria({
    required this.minimumCompletionRate,
    required this.minimumOverallAverage,
    required this.minimumFinalExamScore,
    required this.minimumSkillAverage,
    required this.minimumSpeakingSubmissions,
    required this.minimumWritingSubmissions,
    required this.requireAllReviewsCompleted,
    required this.requireAllCheckpointsCompleted,
  });
}

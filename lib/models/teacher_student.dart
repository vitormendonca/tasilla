class TeacherStudent {
  final String id;
  final String studentId;
  final String name;
  final String level;

  final String classType; // Individual or Group
  final String classDay;
  final String classTime;
  final String frequency;
  final String format; // Online or Presential

  final int completed;
  final int reviewNeeded;
  final int average;

  final int listeningCompleted;
  final int listeningReviewNeeded;
  final int listeningAverage;

  final int vocabularyCompleted;
  final int vocabularyReviewNeeded;
  final int vocabularyAverage;

  final int readingCompleted;
  final int readingReviewNeeded;
  final int readingAverage;

  final int homeworkCompleted;
  final int homeworkReviewNeeded;
  final int homeworkAverage;

  const TeacherStudent({
    required this.id,
    required this.studentId,
    required this.name,
    required this.level,
    required this.classType,
    required this.classDay,
    required this.classTime,
    required this.frequency,
    required this.format,
    required this.completed,
    required this.reviewNeeded,
    required this.average,
    required this.listeningCompleted,
    required this.listeningReviewNeeded,
    required this.listeningAverage,
    required this.vocabularyCompleted,
    required this.vocabularyReviewNeeded,
    required this.vocabularyAverage,
    required this.readingCompleted,
    required this.readingReviewNeeded,
    required this.readingAverage,
    required this.homeworkCompleted,
    required this.homeworkReviewNeeded,
    required this.homeworkAverage,
  });
}

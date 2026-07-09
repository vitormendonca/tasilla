import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StudentProgressService {
  static const String _completedActivitiesKey = 'completed_activities';
  static const String _scoresKey = 'activity_scores';

  // This key needs to match the key used when the teacher assigns activities.
  // If your assign service uses another key, we only change this line later.
  static const String _assignedActivitiesKey = 'assigned_activities';

  static Future<List<String>> getCompletedActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final completedJson = prefs.getString(_completedActivitiesKey);

    if (completedJson == null) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(completedJson);
    return decoded.map((item) => item.toString()).toList();
  }

  static Future<void> markActivityAsCompleted({
    required String activityId,
    required String category,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final completedActivities = await getCompletedActivities();
    final progressId = '${category}_$activityId';

    if (!completedActivities.contains(progressId)) {
      completedActivities.add(progressId);
    }

    await prefs.setString(
      _completedActivitiesKey,
      jsonEncode(completedActivities),
    );
  }

  static Future<bool> isActivityCompleted({
    required String activityId,
    required String category,
  }) async {
    final completedActivities = await getCompletedActivities();
    final progressId = '${category}_$activityId';

    return completedActivities.contains(progressId);
  }

  static Future<void> saveActivityScore({
    required String activityId,
    required String category,
    required int score,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final scoresJson = prefs.getString(_scoresKey);
    Map<String, dynamic> scores = {};

    if (scoresJson != null) {
      scores = jsonDecode(scoresJson);
    }

    final progressId = '${category}_$activityId';

    scores[progressId] = score;

    await prefs.setString(_scoresKey, jsonEncode(scores));
  }

  static Future<int?> getActivityScore({
    required String activityId,
    required String category,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final scoresJson = prefs.getString(_scoresKey);

    if (scoresJson == null) {
      return null;
    }

    final Map<String, dynamic> scores = jsonDecode(scoresJson);
    final progressId = '${category}_$activityId';

    if (!scores.containsKey(progressId)) {
      return null;
    }

    return scores[progressId] as int;
  }

  static Future<Map<String, dynamic>> getAllScores() async {
    final prefs = await SharedPreferences.getInstance();

    final scoresJson = prefs.getString(_scoresKey);

    if (scoresJson == null) {
      return {};
    }

    return jsonDecode(scoresJson);
  }

  static Future<List<Map<String, dynamic>>> getAssignedActivities() async {
    final prefs = await SharedPreferences.getInstance();

    final assignedJson = prefs.getString(_assignedActivitiesKey);

    if (assignedJson == null) {
      return [];
    }

    final decoded = jsonDecode(assignedJson);

    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<int> getTotalCompletedActivities() async {
    final completedActivities = await getCompletedActivities();
    return completedActivities.length;
  }

  static Future<int> getCompletedActivitiesByCategory(String category) async {
    final completedActivities = await getCompletedActivities();

    return completedActivities
        .where((activityId) => activityId.startsWith('${category}_'))
        .length;
  }

  static Future<int> getAttemptedActivitiesByCategory(String category) async {
    final scores = await getAllScores();

    return scores.entries
        .where((entry) => entry.key.startsWith('${category}_'))
        .length;
  }

  static Future<int> getPendingActivitiesByCategory(String category) async {
    final assignedActivities = await getAssignedActivities();

    return assignedActivities.where((activity) {
      final activityCategory =
          activity['category']?.toString().toLowerCase().trim() ?? '';

      final status = activity['status']?.toString().toLowerCase().trim() ?? '';

      return activityCategory == category.toLowerCase().trim() &&
          (status == 'pending' || status == 'assigned');
    }).length;
  }

  static Future<int> getReviewNeededByCategory(String category) async {
    final attempted = await getAttemptedActivitiesByCategory(category);
    final completed = await getCompletedActivitiesByCategory(category);

    final reviewNeeded = attempted - completed;

    if (reviewNeeded < 0) {
      return 0;
    }

    return reviewNeeded;
  }

  static Future<int> getAverageScoreByCategory(String category) async {
    final scores = await getAllScores();

    final categoryScores = scores.entries
        .where((entry) => entry.key.startsWith('${category}_'))
        .map((entry) => entry.value as int)
        .toList();

    if (categoryScores.isEmpty) {
      return 0;
    }

    final total = categoryScores.fold<int>(0, (sum, score) => sum + score);

    return (total / categoryScores.length).round();
  }

  static Future<Map<String, int>> getProgressByCategory() async {
    final listeningCompleted = await getCompletedActivitiesByCategory(
      'listening',
    );
    final speakingCompleted = await getCompletedActivitiesByCategory(
      'speaking',
    );
    final vocabularyCompleted = await getCompletedActivitiesByCategory(
      'vocabulary',
    );
    final readingCompleted = await getCompletedActivitiesByCategory('reading');
    final homeworkCompleted = await getCompletedActivitiesByCategory(
      'homework',
    );

    return {
      'listening': listeningCompleted,
      'speaking': speakingCompleted,
      'vocabulary': vocabularyCompleted,
      'reading': readingCompleted,
      'homework': homeworkCompleted,
    };
  }

  static Future<Map<String, int>> getPendingByCategories() async {
    final listeningPending = await getPendingActivitiesByCategory('listening');
    final speakingPending = await getPendingActivitiesByCategory('speaking');
    final vocabularyPending = await getPendingActivitiesByCategory(
      'vocabulary',
    );
    final readingPending = await getPendingActivitiesByCategory('reading');
    final homeworkPending = await getPendingActivitiesByCategory('homework');

    return {
      'listening': listeningPending,
      'speaking': speakingPending,
      'vocabulary': vocabularyPending,
      'reading': readingPending,
      'homework': homeworkPending,
    };
  }

  static Future<Map<String, int>> getReviewNeededByCategories() async {
    final listeningReview = await getReviewNeededByCategory('listening');
    final speakingReview = await getReviewNeededByCategory('speaking');
    final vocabularyReview = await getReviewNeededByCategory('vocabulary');
    final readingReview = await getReviewNeededByCategory('reading');
    final homeworkReview = await getReviewNeededByCategory('homework');

    return {
      'listening': listeningReview,
      'speaking': speakingReview,
      'vocabulary': vocabularyReview,
      'reading': readingReview,
      'homework': homeworkReview,
    };
  }

  static Future<Map<String, int>> getAverageScoresByCategory() async {
    final listeningAverage = await getAverageScoreByCategory('listening');
    final speakingAverage = await getAverageScoreByCategory('speaking');
    final vocabularyAverage = await getAverageScoreByCategory('vocabulary');
    final readingAverage = await getAverageScoreByCategory('reading');
    final homeworkAverage = await getAverageScoreByCategory('homework');

    return {
      'listening': listeningAverage,
      'speaking': speakingAverage,
      'vocabulary': vocabularyAverage,
      'reading': readingAverage,
      'homework': homeworkAverage,
    };
  }

  static Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_completedActivitiesKey);
    await prefs.remove(_scoresKey);
  }
}

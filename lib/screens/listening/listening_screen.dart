import 'package:flutter/material.dart';

import '../../data/listening_data.dart';
import '../../models/listening_exercise.dart';
import '../../services/student_progress_service.dart';
import '../../theme/app_theme.dart';
import 'listening_exercise_screen.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  Map<String, int> exerciseScores = {};
  Map<String, bool> completedExercises = {};
  int completedNormalListeningExercises = 0;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final Map<String, int> loadedScores = {};
    final Map<String, bool> loadedCompleted = {};
    int normalCompletedCount = 0;

    for (final exercise in listeningExercises) {
      final score = await StudentProgressService.getActivityScore(
        activityId: exercise.id,
        category: 'listening',
      );
      final isCompleted = await StudentProgressService.isActivityCompleted(
        activityId: exercise.id,
        category: 'listening',
      );
      loadedScores[exercise.id] = score ?? -1;
      loadedCompleted[exercise.id] = isCompleted;
      final bool reviewExercise = isReviewExercise(exercise);
      if (!reviewExercise && isCompleted) normalCompletedCount++;
    }

    if (!mounted) return;

    setState(() {
      exerciseScores = loadedScores;
      completedExercises = loadedCompleted;
      completedNormalListeningExercises = normalCompletedCount;
    });
  }

  Future<void> openExercise(ListeningExercise exercise) async {
    final bool reviewExercise = isReviewExercise(exercise);
    final bool locked = isReviewLocked(exercise);

    if (reviewExercise && locked) {
      showLockedReviewMessage();
      return;
    }

    await Navigator.push(context, MaterialPageRoute(builder: (context) => ListeningExerciseScreen(exercise: exercise)));
    await loadProgress();
  }

  bool isReviewExercise(ListeningExercise exercise) {
    return exercise.id.contains('review') || exercise.level.toLowerCase().contains('review');
  }

  bool isReviewLocked(ListeningExercise exercise) {
    if (!isReviewExercise(exercise)) return false;
    return completedNormalListeningExercises < 3;
  }

  void showLockedReviewMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Complete 3 listening activities to unlock this review.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas      = isDark ? const Color(0xFF161618) : const Color(0xFFFAFAF8);
    final textPrimary = isDark ? const Color(0xFFF5F5F0) : const Color(0xFF1A1A1A);
    final textMuted   = isDark ? const Color(0xFF48484A) : const Color(0xFFAEAAA2);
    final surface     = isDark ? const Color(0xFF242426) : const Color(0xFFF0EEE8);
    final border      = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC);

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMuted),
        title: Text('Listening Practice', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('LISTENING PRACTICE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
          const SizedBox(height: 6),
          Text('Choose a listening practice', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Listen, answer questions, and unlock reviews as you progress.', style: TextStyle(fontSize: 13, color: textMuted, height: 1.4)),
          const SizedBox(height: 16),

          // Progress chip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: completedNormalListeningExercises >= 3 ? AppTheme.semanticGreen : AppTheme.semanticYellow,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Review unlock: $completedNormalListeningExercises/3 listening activities completed',
                    style: TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          for (final exercise in listeningExercises)
            _exerciseCard(
              exercise: exercise,
              onTap: () => openExercise(exercise),
              textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
            ),
        ],
      ),
    );
  }

  Widget _exerciseCard({
    required ListeningExercise exercise,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final bool reviewExercise = isReviewExercise(exercise);
    final bool locked = isReviewLocked(exercise);
    final int score = exerciseScores[exercise.id] ?? -1;
    final bool isCompleted = completedExercises[exercise.id] ?? false;
    final bool hasResult = score >= 0;

    Color statusColor;
    String statusText;

    if (locked) {
      statusText = 'Locked · Complete 3 listening activities';
      statusColor = textMuted;
    } else if (hasResult) {
      if (isCompleted) {
        statusText = 'Completed · Accuracy: $score%';
        statusColor = AppTheme.semanticGreen;
      } else {
        statusText = 'Review Needed · Accuracy: $score%';
        statusColor = AppTheme.semanticYellow;
      }
    } else {
      statusText = 'Not started';
      statusColor = textMuted;
    }

    final dotColor = locked ? textMuted : (reviewExercise ? AppTheme.semanticYellow : (isCompleted ? AppTheme.semanticGreen : textPrimary));

    return Opacity(
      opacity: locked ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: reviewExercise && !locked ? AppTheme.semanticYellow.withValues(alpha: 0.35) : border),
          ),
          child: Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reviewExercise) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (locked ? textMuted : AppTheme.semanticYellow).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: (locked ? textMuted : AppTheme.semanticYellow).withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          locked ? 'LOCKED REVIEW' : 'REVIEW ACTIVITY',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: locked ? textMuted : AppTheme.semanticYellow),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      exercise.title,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: locked ? textMuted : textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reviewExercise
                          ? '${exercise.description} · ${exercise.questions.length} questions'
                          : exercise.description,
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(width: 5, height: 5, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(statusText, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (locked ? textMuted : dotColor).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: (locked ? textMuted : dotColor).withValues(alpha: 0.2)),
                ),
                child: Text(exercise.level, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: locked ? textMuted : dotColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

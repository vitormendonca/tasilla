import 'package:flutter/material.dart';

import '../../data/vocabulary_data.dart';
import '../../models/vocabulary_quiz.dart';
import '../../services/student_progress_service.dart';
import '../../theme/app_theme.dart';
import 'vocabulary_quiz_screen.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  Map<String, int> quizScores = {};
  Map<String, bool> completedQuizzes = {};
  int completedNormalVocabularyQuizzes = 0;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final Map<String, int> loadedScores = {};
    final Map<String, bool> loadedCompleted = {};
    int normalCompletedCount = 0;

    for (final quiz in vocabularyQuizzes) {
      final score = await StudentProgressService.getActivityScore(activityId: quiz.id, category: 'vocabulary');
      final isCompleted = await StudentProgressService.isActivityCompleted(activityId: quiz.id, category: 'vocabulary');
      loadedScores[quiz.id] = score ?? -1;
      loadedCompleted[quiz.id] = isCompleted;
      if (!isReviewQuiz(quiz) && isCompleted) normalCompletedCount++;
    }

    if (!mounted) return;

    setState(() {
      quizScores = loadedScores;
      completedQuizzes = loadedCompleted;
      completedNormalVocabularyQuizzes = normalCompletedCount;
    });
  }

  Future<void> openQuiz(VocabularyQuiz quiz) async {
    if (isReviewQuiz(quiz) && isReviewLocked(quiz)) {
      showLockedReviewMessage();
      return;
    }
    await Navigator.push(context, MaterialPageRoute(builder: (context) => VocabularyQuizScreen(quiz: quiz)));
    await loadProgress();
  }

  bool isReviewQuiz(VocabularyQuiz quiz) {
    return quiz.id.contains('review') || quiz.level.toLowerCase().contains('review');
  }

  bool isReviewLocked(VocabularyQuiz quiz) {
    if (!isReviewQuiz(quiz)) return false;
    return completedNormalVocabularyQuizzes < 3;
  }

  void showLockedReviewMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Complete 3 vocabulary activities to unlock this review.')),
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
        title: Text('Vocabulary Quiz', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('VOCABULARY PRACTICE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
          const SizedBox(height: 6),
          Text('Choose a vocabulary practice', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Practice words by theme and unlock reviews as you progress.', style: TextStyle(fontSize: 13, color: textMuted)),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
            child: Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: completedNormalVocabularyQuizzes >= 3 ? AppTheme.semanticGreen : AppTheme.semanticYellow,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Review unlock: $completedNormalVocabularyQuizzes/3 vocabulary activities completed',
                    style: TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          for (final quiz in vocabularyQuizzes)
            _quizCard(quiz: quiz, onTap: () => openQuiz(quiz), textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
        ],
      ),
    );
  }

  Widget _quizCard({
    required VocabularyQuiz quiz,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final bool reviewQuiz = isReviewQuiz(quiz);
    final bool locked = isReviewLocked(quiz);
    final int score = quizScores[quiz.id] ?? -1;
    final bool isCompleted = completedQuizzes[quiz.id] ?? false;
    final bool hasResult = score >= 0;

    Color statusColor;
    String statusText;

    if (locked) {
      statusText = 'Locked · Complete 3 vocabulary activities';
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

    final dotColor = locked ? textMuted : (reviewQuiz ? AppTheme.semanticYellow : (isCompleted ? AppTheme.semanticGreen : textPrimary));

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
            border: Border.all(color: reviewQuiz && !locked ? AppTheme.semanticYellow.withValues(alpha: 0.35) : border),
          ),
          child: Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reviewQuiz) ...[
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
                    Text(quiz.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: locked ? textMuted : textPrimary)),
                    const SizedBox(height: 3),
                    Text(
                      reviewQuiz ? '${quiz.description} · ${quiz.questions.length} questions' : quiz.description,
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
                child: Text(quiz.level, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: locked ? textMuted : dotColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/activity_question.dart';
import '../../models/vocabulary_quiz.dart';
import '../../services/assignment_service.dart';
import '../../services/student_progress_service.dart';
import '../../theme/app_theme.dart';

class VocabularyQuizScreen extends StatefulWidget {
  final VocabularyQuiz quiz;

  const VocabularyQuizScreen({super.key, required this.quiz});

  @override
  State<VocabularyQuizScreen> createState() => _VocabularyQuizScreenState();
}

class _VocabularyQuizScreenState extends State<VocabularyQuizScreen> {
  int currentQuestionIndex = 0;
  bool showResult = false;

  final Map<String, String> answers = {};
  final Map<String, TextEditingController> textControllers = {};

  bool lastCompleted = false;
  int? lastScore;
  bool reviewMode = false;

  @override
  void initState() {
    super.initState();
    _loadLastResult();
  }

  Future<void> _loadLastResult() async {
    final completed = await StudentProgressService.isActivityCompleted(activityId: widget.quiz.id, category: 'vocabulary');
    final score = await StudentProgressService.getActivityScore(activityId: widget.quiz.id, category: 'vocabulary');
    if (!mounted) return;
    setState(() {
      lastCompleted = completed;
      lastScore = score;
      reviewMode = completed;
    });
  }

  @override
  void dispose() {
    for (final controller in textControllers.values) controller.dispose();
    super.dispose();
  }

  TextEditingController _getController(String questionId) {
    if (!textControllers.containsKey(questionId)) {
      textControllers[questionId] = TextEditingController();
    }
    return textControllers[questionId]!;
  }

  ActivityQuestion get currentQuestion => widget.quiz.questions[currentQuestionIndex];

  bool _isCurrentQuestionAnswered() {
    final answer = answers[currentQuestion.id];
    return answer != null && answer.trim().isNotEmpty;
  }

  bool _isCorrect(ActivityQuestion question, String answer) {
    return answer.trim().toLowerCase() == question.correctAnswer.trim().toLowerCase();
  }

  int _calculateScore() {
    int score = 0;
    for (final question in widget.quiz.questions) {
      final userAnswer = answers[question.id];
      if (userAnswer != null && _isCorrect(question, userAnswer)) score++;
    }
    return score;
  }

  int _calculatePercentageScore() {
    final score = _calculateScore();
    final total = widget.quiz.questions.length;
    if (total == 0) return 0;
    return ((score / total) * 100).round();
  }

  Future<void> _saveResult() async {
    final percentageScore = _calculatePercentageScore();
    if (reviewMode) return;

    final prefs = await SharedPreferences.getInstance();
    final currentStudentName = prefs.getString('currentStudentName') ?? '';

    if (percentageScore >= 85) {
      await StudentProgressService.markActivityAsCompleted(activityId: widget.quiz.id, category: 'vocabulary');
      if (currentStudentName.isNotEmpty) {
        await AssignmentService.markStudentAssignmentAsCompleted(studentName: currentStudentName, title: widget.quiz.title, category: 'Vocabulary');
      }
    } else {
      if (currentStudentName.isNotEmpty) {
        await AssignmentService.markStudentAssignmentAsReviewNeeded(studentName: currentStudentName, title: widget.quiz.title, category: 'Vocabulary');
      }
    }

    await StudentProgressService.saveActivityScore(activityId: widget.quiz.id, category: 'vocabulary', score: percentageScore);

    if (!mounted) return;
    setState(() {
      lastScore = percentageScore;
      if (percentageScore >= 85) { lastCompleted = true; reviewMode = true; }
    });
  }

  Future<void> _nextQuestion() async {
    if (!_isCurrentQuestionAnswered()) return;
    final bool isLastQuestion = currentQuestionIndex == widget.quiz.questions.length - 1;
    if (isLastQuestion) {
      await _saveResult();
      if (!mounted) return;
      setState(() { showResult = true; });
    } else {
      setState(() { currentQuestionIndex++; });
    }
  }

  void _restartQuiz() {
    setState(() {
      currentQuestionIndex = 0;
      showResult = false;
      answers.clear();
      for (final controller in textControllers.values) controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showResult) return _buildResultScreen();

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
        title: Text(widget.quiz.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (reviewMode && lastScore != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.semanticGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.semanticGreen.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppTheme.semanticGreen, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Quiz completed. You can review it, but your saved score will not change.',
                      style: TextStyle(fontSize: 13, color: AppTheme.semanticGreen, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
              child: Text('Best score: $lastScore%', style: TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 18),
          ],

          Text(widget.quiz.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(widget.quiz.description, style: TextStyle(fontSize: 13, color: textMuted)),
          const SizedBox(height: 2),
          Text(widget.quiz.level, style: TextStyle(fontSize: 12, color: textMuted)),
          const SizedBox(height: 20),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / widget.quiz.questions.length,
              minHeight: 3,
              color: textPrimary,
              backgroundColor: border,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Question ${currentQuestionIndex + 1} of ${widget.quiz.questions.length}',
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 20),

          _buildQuestionCard(currentQuestion, isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _isCurrentQuestionAnswered() ? _nextQuestion : null,
            child: Container(
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _isCurrentQuestionAnswered()
                    ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                    : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  currentQuestionIndex == widget.quiz.questions.length - 1
                      ? (reviewMode ? 'Finish Review' : 'Finish Quiz')
                      : 'Next',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isCurrentQuestionAnswered()
                        ? (isDark ? const Color(0xFF161618) : Colors.white)
                        : textMuted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    ActivityQuestion question, {
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.question, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 18),
          if (question.type == QuestionType.multipleChoice || question.type == QuestionType.trueFalse)
            _buildOptions(question, textPrimary: textPrimary, textMuted: textMuted, border: border)
          else
            _buildTextInput(question, isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, border: border),
          if (_isCurrentQuestionAnswered()) ...[
            const SizedBox(height: 12),
            _buildInstantFeedback(question, textMuted: textMuted),
          ],
        ],
      ),
    );
  }

  Widget _buildOptions(
    ActivityQuestion question, {
    required Color textPrimary,
    required Color textMuted,
    required Color border,
  }) {
    final selectedAnswer = answers[question.id];
    final hasAnswered = selectedAnswer != null;

    return Column(
      children: [
        for (final option in question.options)
          GestureDetector(
            onTap: hasAnswered ? null : () { setState(() { answers[question.id] = option; }); },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: _getOptionBg(option: option, selectedAnswer: selectedAnswer, correctAnswer: question.correctAnswer),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getOptionBorder(option: option, selectedAnswer: selectedAnswer, correctAnswer: question.correctAnswer, border: border)),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(option, style: TextStyle(fontSize: 14, color: textPrimary))),
                  if (hasAnswered && option == question.correctAnswer)
                    Icon(Icons.check_circle_outline, color: AppTheme.semanticGreen, size: 18),
                  if (hasAnswered && option == selectedAnswer && option != question.correctAnswer)
                    Icon(Icons.cancel_outlined, color: AppTheme.semanticRed, size: 18),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _getOptionBg({required String option, required String? selectedAnswer, required String correctAnswer}) {
    if (selectedAnswer == null) return Colors.transparent;
    if (option == correctAnswer) return AppTheme.semanticGreen.withValues(alpha: 0.08);
    if (option == selectedAnswer && option != correctAnswer) return AppTheme.semanticRed.withValues(alpha: 0.08);
    return Colors.transparent;
  }

  Color _getOptionBorder({required String option, required String? selectedAnswer, required String correctAnswer, required Color border}) {
    if (selectedAnswer == null) return border;
    if (option == correctAnswer) return AppTheme.semanticGreen;
    if (option == selectedAnswer && option != correctAnswer) return AppTheme.semanticRed;
    return border;
  }

  Widget _buildTextInput(
    ActivityQuestion question, {
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
  }) {
    return TextField(
      controller: _getController(question.id),
      style: TextStyle(color: textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: question.type == QuestionType.fillBlank ? 'Complete the sentence' : 'Type your answer here',
        hintStyle: TextStyle(color: textMuted, fontSize: 13),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A1C) : const Color(0xFFF5F5F0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: textPrimary)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (value) { setState(() { answers[question.id] = value; }); },
    );
  }

  Widget _buildInstantFeedback(ActivityQuestion question, {required Color textMuted}) {
    final answer = answers[question.id];
    if (answer == null || answer.trim().isEmpty) return const SizedBox.shrink();
    final isCorrect = _isCorrect(question, answer);
    final color = isCorrect ? AppTheme.semanticGreen : AppTheme.semanticYellow;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        isCorrect ? 'Correct!' : 'Correct answer: ${question.correctAnswer}',
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildResultScreen() {
    final score = _calculateScore();
    final total = widget.quiz.questions.length;
    final percentageScore = _calculatePercentageScore();
    final bool isApproved = percentageScore >= 85;

    String message;
    if (reviewMode) {
      if (isApproved) {
        message = 'Good review. Your saved score is still ${lastScore ?? percentageScore}%.';
      } else {
        message = 'This was practice only. Your saved progress did not change.';
      }
    } else if (percentageScore >= 90) {
      message = 'Excellent! This quiz is completed.';
    } else if (percentageScore >= 85) {
      message = 'Great job! This quiz is completed.';
    } else if (percentageScore >= 70) {
      message = 'Good effort. Review and try again.';
    } else {
      message = 'Review the vocabulary and try again.';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas      = isDark ? const Color(0xFF161618) : const Color(0xFFFAFAF8);
    final textPrimary = isDark ? const Color(0xFFF5F5F0) : const Color(0xFF1A1A1A);
    final textMuted   = isDark ? const Color(0xFF48484A) : const Color(0xFFAEAAA2);
    final surface     = isDark ? const Color(0xFF242426) : const Color(0xFFF0EEE8);
    final border      = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC);
    final resultColor = isApproved ? AppTheme.semanticGreen : AppTheme.semanticYellow;

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMuted),
        title: Text(reviewMode ? 'Quiz Review' : 'Quiz Result', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: resultColor.withValues(alpha: 0.35)),
            ),
            child: Column(
              children: [
                Icon(isApproved ? Icons.emoji_events_outlined : Icons.refresh, color: resultColor, size: 36),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: resultColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    reviewMode ? (isApproved ? 'REVIEW COMPLETED' : 'REVIEW PRACTICE') : (isApproved ? 'COMPLETED' : 'REVIEW NEEDED'),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: resultColor),
                  ),
                ),
                const SizedBox(height: 14),
                Text(reviewMode ? 'Your review score' : 'Your score', style: TextStyle(fontSize: 13, color: textMuted)),
                const SizedBox(height: 6),
                Text('$score/$total', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(reviewMode ? 'Review accuracy: $percentageScore%' : 'Accuracy: $percentageScore%', style: TextStyle(fontSize: 16, color: textMuted, fontWeight: FontWeight.w500)),
                if (reviewMode && lastScore != null) ...[
                  const SizedBox(height: 4),
                  Text('Saved score: $lastScore%', style: TextStyle(fontSize: 13, color: AppTheme.semanticGreen, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: textMuted, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 22),

          Text('REVIEW YOUR ANSWERS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
          const SizedBox(height: 14),

          for (int i = 0; i < widget.quiz.questions.length; i++)
            _buildReviewCard(index: i, question: widget.quiz.questions[i], textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),

          const SizedBox(height: 14),

          if (!isApproved) ...[
            GestureDetector(
              onTap: _restartQuiz,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text('Try Again', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF161618) : Colors.white))),
              ),
            ),
            const SizedBox(height: 10),
          ],

          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
              child: Center(child: Text('Back to Vocabulary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary))),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required int index,
    required ActivityQuestion question,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final userAnswer = answers[question.id] ?? '';
    final isCorrect = _isCorrect(question, userAnswer);
    final statusColor = isCorrect ? AppTheme.semanticGreen : AppTheme.semanticRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isCorrect ? Icons.check_circle_outline : Icons.cancel_outlined, color: statusColor, size: 16),
              const SizedBox(width: 8),
              Text('Question ${index + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(question.question, style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Your answer: ${userAnswer.isEmpty ? 'No answer' : userAnswer}', style: TextStyle(fontSize: 12, color: textMuted)),
          const SizedBox(height: 4),
          Text('Correct answer: ${question.correctAnswer}', style: TextStyle(fontSize: 12, color: textMuted)),
        ],
      ),
    );
  }
}

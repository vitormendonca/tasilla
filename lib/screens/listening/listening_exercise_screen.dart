import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/activity_question.dart';
import '../../models/listening_exercise.dart';
import '../../services/assignment_service.dart';
import '../../services/student_progress_service.dart';
import '../../theme/app_theme.dart';

class ListeningExerciseScreen extends StatefulWidget {
  final ListeningExercise exercise;

  const ListeningExerciseScreen({super.key, required this.exercise});

  @override
  State<ListeningExerciseScreen> createState() => _ListeningExerciseScreenState();
}

class _ListeningExerciseScreenState extends State<ListeningExerciseScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();
  final Map<String, String> selectedAnswers = {};
  final Map<String, TextEditingController> textControllers = {};

  bool showTranscript = false;
  bool isPlaying = false;
  bool showResult = false;
  bool lastCompleted = false;
  int? lastScore;
  bool reviewMode = false;

  @override
  void initState() {
    super.initState();
    _loadLastResult();
    audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() { isPlaying = false; });
    });
  }

  Future<void> _loadLastResult() async {
    final completed = await StudentProgressService.isActivityCompleted(
      activityId: widget.exercise.id,
      category: 'listening',
    );
    final score = await StudentProgressService.getActivityScore(
      activityId: widget.exercise.id,
      category: 'listening',
    );
    if (!mounted) return;
    setState(() {
      lastCompleted = completed;
      lastScore = score;
      reviewMode = completed;
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    for (final controller in textControllers.values) controller.dispose();
    super.dispose();
  }

  TextEditingController _getController(String questionId) {
    if (!textControllers.containsKey(questionId)) {
      textControllers[questionId] = TextEditingController();
    }
    return textControllers[questionId]!;
  }

  bool _isCorrect(ActivityQuestion question, String userAnswer) {
    return userAnswer.trim().toLowerCase() == question.correctAnswer.trim().toLowerCase();
  }

  bool _isQuestionAvailable(ActivityQuestion question) {
    return question.type != QuestionType.reorderSentence;
  }

  int _availableQuestionsTotal() {
    return widget.exercise.questions.where(_isQuestionAvailable).length;
  }

  bool _allQuestionsAnswered() {
    for (final question in widget.exercise.questions) {
      if (!_isQuestionAvailable(question)) continue;
      final answer = selectedAnswers[question.id];
      if (answer == null || answer.trim().isEmpty) return false;
    }
    return true;
  }

  int _calculateScore() {
    int score = 0;
    for (final question in widget.exercise.questions) {
      if (!_isQuestionAvailable(question)) continue;
      final userAnswer = selectedAnswers[question.id];
      if (userAnswer != null && _isCorrect(question, userAnswer)) score++;
    }
    return score;
  }

  int _calculatePercentageScore() {
    final int score = _calculateScore();
    final int total = _availableQuestionsTotal();
    if (total == 0) return 0;
    return ((score / total) * 100).round();
  }

  Future<void> _saveResult() async {
    final int percentageScore = _calculatePercentageScore();
    if (reviewMode) return;

    final prefs = await SharedPreferences.getInstance();
    final currentStudentName = prefs.getString('currentStudentName') ?? '';

    if (percentageScore >= 85) {
      await StudentProgressService.markActivityAsCompleted(
        activityId: widget.exercise.id,
        category: 'listening',
      );
      if (currentStudentName.isNotEmpty) {
        await AssignmentService.markStudentAssignmentAsCompleted(
          studentName: currentStudentName,
          title: widget.exercise.title,
          category: 'Listening',
        );
      }
    } else {
      if (currentStudentName.isNotEmpty) {
        await AssignmentService.markStudentAssignmentAsReviewNeeded(
          studentName: currentStudentName,
          title: widget.exercise.title,
          category: 'Listening',
        );
      }
    }

    await StudentProgressService.saveActivityScore(
      activityId: widget.exercise.id,
      category: 'listening',
      score: percentageScore,
    );

    if (!mounted) return;

    setState(() {
      lastScore = percentageScore;
      if (percentageScore >= 85) {
        lastCompleted = true;
        reviewMode = true;
      }
    });
  }

  Future<void> _finishListening() async {
    if (!_allQuestionsAnswered()) return;
    await _saveResult();
    if (!mounted) return;
    setState(() { showResult = true; });
  }

  void _restartActivity() {
    setState(() {
      showResult = false;
      selectedAnswers.clear();
      for (final controller in textControllers.values) controller.clear();
    });
  }

  void toggleTranscript() {
    setState(() { showTranscript = !showTranscript; });
  }

  Future<void> playAudio() async {
    try {
      await audioPlayer.play(AssetSource(widget.exercise.audioPath));
      setState(() { isPlaying = true; });
    } catch (e) {
      showAudioError(e);
    }
  }

  Future<void> pauseAudio() async {
    try {
      await audioPlayer.pause();
      setState(() { isPlaying = false; });
    } catch (e) {
      showAudioError(e);
    }
  }

  Future<void> restartAudio() async {
    try {
      await audioPlayer.stop();
      await audioPlayer.play(AssetSource(widget.exercise.audioPath));
      setState(() { isPlaying = true; });
    } catch (e) {
      showAudioError(e);
    }
  }

  void showAudioError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Audio error: $error')));
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
        title: Text(widget.exercise.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
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
                      'Activity completed. You can review it, but your saved score will not change.',
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

          Text(widget.exercise.description, style: TextStyle(fontSize: 12, color: textMuted)),
          const SizedBox(height: 4),
          Text(widget.exercise.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(widget.exercise.level, style: TextStyle(fontSize: 12, color: textMuted)),
          const SizedBox(height: 20),

          // Audio card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
            child: Column(
              children: [
                Icon(isPlaying ? Icons.graphic_eq : Icons.headphones_outlined, color: textPrimary, size: 40),
                const SizedBox(height: 6),
                Text(isPlaying ? 'Audio playing...' : 'Ready to listen', style: TextStyle(fontSize: 13, color: textMuted)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: isPlaying ? pauseAudio : playAudio,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 18, color: isDark ? const Color(0xFF161618) : Colors.white),
                              const SizedBox(width: 6),
                              Text(isPlaying ? 'Pause' : 'Play', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF161618) : Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: restartAudio,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.replay, size: 18, color: textMuted),
                              const SizedBox(width: 6),
                              Text('Restart', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: toggleTranscript,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(showTranscript ? Icons.visibility_off : Icons.visibility, color: textMuted, size: 16),
                      const SizedBox(width: 6),
                      Text(showTranscript ? 'Hide transcript' : 'Show transcript', style: TextStyle(fontSize: 13, color: textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (showTranscript) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
              child: Text(widget.exercise.transcript, style: TextStyle(fontSize: 13, color: textMuted, height: 1.5)),
            ),
          ],

          const SizedBox(height: 24),
          Text('QUESTIONS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
          const SizedBox(height: 14),

          for (final question in widget.exercise.questions)
            _buildQuestion(question, isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: _allQuestionsAnswered() ? _finishListening : null,
            child: Container(
              height: 52,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _allQuestionsAnswered()
                    ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                    : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  reviewMode ? 'Check Review' : 'Check Answers',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _allQuestionsAnswered()
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

  Widget _buildQuestion(
    ActivityQuestion question, {
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        return _buildMultipleChoiceQuestion(question, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border);
      case QuestionType.textInput:
      case QuestionType.dictation:
      case QuestionType.fillBlank:
        return _buildTextInputQuestion(question, isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border);
      case QuestionType.reorderSentence:
        return _buildComingSoonQuestion(question, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border);
    }
  }

  Widget _buildMultipleChoiceQuestion(
    ActivityQuestion question, {
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final selectedAnswer = selectedAnswers[question.id];
    final hasAnswered = selectedAnswer != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.question, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 12),
          for (final option in question.options)
            _buildAnswerOption(question: question, option: option, selectedAnswer: selectedAnswer, textPrimary: textPrimary, textMuted: textMuted, border: border),
          if (hasAnswered) _buildInstantFeedback(question, textMuted: textMuted),
        ],
      ),
    );
  }

  Widget _buildAnswerOption({
    required ActivityQuestion question,
    required String option,
    required String? selectedAnswer,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
  }) {
    final bool hasAnswered = selectedAnswer != null;
    final bool isCorrectAnswer = option == question.correctAnswer;
    final bool isSelected = option == selectedAnswer;
    final bool isWrongSelected = hasAnswered && isSelected && !isCorrectAnswer;

    Color borderColor = border;
    Color? bgColor;

    if (hasAnswered && isCorrectAnswer) {
      borderColor = AppTheme.semanticGreen;
      bgColor = AppTheme.semanticGreen.withValues(alpha: 0.08);
    }
    if (isWrongSelected) {
      borderColor = AppTheme.semanticRed;
      bgColor = AppTheme.semanticRed.withValues(alpha: 0.08);
    }

    return GestureDetector(
      onTap: hasAnswered ? null : () {
        setState(() { selectedAnswers[question.id] = option; });
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(child: Text(option, style: TextStyle(fontSize: 14, color: textPrimary))),
            if (hasAnswered && isCorrectAnswer)
              Icon(Icons.check_circle_outline, color: AppTheme.semanticGreen, size: 18),
            if (isWrongSelected)
              Icon(Icons.cancel_outlined, color: AppTheme.semanticRed, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputQuestion(
    ActivityQuestion question, {
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final submittedAnswer = selectedAnswers[question.id];
    final bool hasAnswered = submittedAnswer != null && submittedAnswer.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.question, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 12),
          TextField(
            controller: _getController(question.id),
            style: TextStyle(color: textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: question.type == QuestionType.dictation ? 'Type what you hear' : 'Type your answer here',
              hintStyle: TextStyle(color: textMuted, fontSize: 13),
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1A1C) : const Color(0xFFF5F5F0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: textPrimary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (value) {
              setState(() { selectedAnswers[question.id] = value; });
            },
          ),
          if (hasAnswered) ...[
            const SizedBox(height: 10),
            _buildInstantFeedback(question, textMuted: textMuted),
          ],
        ],
      ),
    );
  }

  Widget _buildInstantFeedback(ActivityQuestion question, {required Color textMuted}) {
    final answer = selectedAnswers[question.id];
    if (answer == null || answer.trim().isEmpty) return const SizedBox.shrink();
    final isCorrect = _isCorrect(question, answer);
    final color = isCorrect ? AppTheme.semanticGreen : AppTheme.semanticYellow;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
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

  Widget _buildComingSoonQuestion(
    ActivityQuestion question, {
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.question, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 8),
          Text('This question type will be available soon.', style: TextStyle(fontSize: 12, color: textMuted)),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final score = _calculateScore();
    final total = _availableQuestionsTotal();
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
      message = 'Excellent listening comprehension! This activity is completed.';
    } else if (percentageScore >= 85) {
      message = 'Great listening comprehension! This activity is completed.';
    } else if (percentageScore >= 70) {
      message = 'Good effort. Listen again and review the transcript.';
    } else {
      message = 'Listen again and compare your answers with the transcript.';
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
        title: Text(reviewMode ? 'Listening Review' : 'Listening Result', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Result card
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
                Icon(isApproved ? Icons.check_circle_outline : Icons.refresh, color: resultColor, size: 40),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: resultColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    reviewMode
                        ? (isApproved ? 'REVIEW COMPLETED' : 'REVIEW PRACTICE')
                        : (isApproved ? 'COMPLETED' : 'REVIEW NEEDED'),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: resultColor),
                  ),
                ),
                const SizedBox(height: 14),
                Text(reviewMode ? 'Your review score' : 'Your score', style: TextStyle(fontSize: 13, color: textMuted)),
                const SizedBox(height: 6),
                Text('$score/$total', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(
                  reviewMode ? 'Review accuracy: $percentageScore%' : 'Accuracy: $percentageScore%',
                  style: TextStyle(fontSize: 16, color: textMuted, fontWeight: FontWeight.w500),
                ),
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

          for (int i = 0; i < widget.exercise.questions.length; i++)
            _buildReviewCard(index: i, question: widget.exercise.questions[i], textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),

          const SizedBox(height: 16),

          if (!isApproved) ...[
            GestureDetector(
              onTap: _restartActivity,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('Try Again', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF161618) : Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: Center(
                child: Text('Back to Listening', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
              ),
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
    if (!_isQuestionAvailable(question)) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Question ${index + 1}', style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(question.question, style: TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text('This question type was not counted in this version.', style: TextStyle(fontSize: 11, color: textMuted)),
          ],
        ),
      );
    }

    final userAnswer = selectedAnswers[question.id] ?? '';
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

import 'package:flutter/material.dart';

import '../../data/placement_test_data.dart';
import '../../models/placement_question.dart';
import '../../services/learning_path_progress_service.dart';
import '../../theme/app_theme.dart';

class StudentPlacementTestScreen extends StatefulWidget {
  final String level;

  const StudentPlacementTestScreen({super.key, required this.level});

  @override
  State<StudentPlacementTestScreen> createState() => _StudentPlacementTestScreenState();
}

class _StudentPlacementTestScreenState extends State<StudentPlacementTestScreen> {
  final Map<String, String> selectedAnswers = {};

  bool isSubmitted = false;
  bool isSaving = false;
  int score = 0;

  List<PlacementQuestion> get questions {
    switch (widget.level) {
      case 'A1':
        return a1PlacementQuestions;
      default:
        return const [];
    }
  }

  int get correctCount {
    return questions.where((question) {
      return selectedAnswers[question.id] == question.correctAnswer;
    }).length;
  }

  bool get isComplete {
    return selectedAnswers.length == questions.length;
  }

  bool get passed {
    return score >= 85;
  }

  void _tryAgain() {
    setState(() {
      selectedAnswers.clear();
      isSubmitted = false;
      isSaving = false;
      score = 0;
    });
  }

  void _finishTest() {
    Navigator.pop(context, true);
  }

  Future<void> _submitTest() async {
    if (isSubmitted) {
      if (passed) {
        _finishTest();
      } else {
        _tryAgain();
      }
      return;
    }

    if (!isComplete || isSaving) {
      return;
    }

    final calculatedScore = ((correctCount / questions.length) * 100).round();

    setState(() {
      score = calculatedScore;
      isSubmitted = true;
      isSaving = true;
    });

    await LearningPathProgressService.recordLevelCheckAttempt(
      level: widget.level,
      score: calculatedScore,
      passed: calculatedScore >= 85,
      answers: selectedAnswers,
    );

    if (calculatedScore >= 85) {
      await LearningPathProgressService.validateLevel(widget.level);
    }

    if (!mounted) return;

    setState(() {
      isSaving = false;
    });
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
        title: Text('${widget.level} Placement Test', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header(isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
          const SizedBox(height: 18),
          for (final question in questions)
            _questionCard(question, isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
          const SizedBox(height: 10),
          if (isSubmitted)
            _resultCard(textPrimary: textPrimary, textMuted: textMuted),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: (isComplete || isSubmitted) && !isSaving ? _submitTest : null,
            child: Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                color: (isComplete || isSubmitted) && !isSaving
                    ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                    : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isSaving
                  ? Center(child: CircularProgressIndicator(color: isDark ? const Color(0xFF161618) : Colors.white, strokeWidth: 1.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSubmitted && passed
                              ? Icons.check_circle_outline
                              : isSubmitted
                                  ? Icons.refresh_outlined
                                  : Icons.workspace_premium_outlined,
                          color: (isComplete || isSubmitted) && !isSaving
                              ? (isDark ? const Color(0xFF161618) : Colors.white)
                              : textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isSubmitted && passed
                              ? 'Done'
                              : isSubmitted
                                  ? 'Try Again'
                                  : 'Submit Placement Test',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: (isComplete || isSubmitted) && !isSaving
                                ? (isDark ? const Color(0xFF161618) : Colors.white)
                                : textMuted,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (!isComplete) ...[
            const SizedBox(height: 10),
            Text(
              'Answer all questions to submit.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textMuted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _header({
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PLACEMENT TEST', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
          const SizedBox(height: 8),
          Text('${widget.level} Placement Test', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text(
            'Pass with 85% or higher to validate this level and continue from the next path. This is a development version with sample questions.',
            style: TextStyle(color: textMuted, fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(
    PlacementQuestion question, {
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final selectedAnswer = selectedAnswers[question.id];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skillBadge(question.skill, textMuted: textMuted, border: border),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600, height: 1.35),
          ),
          const SizedBox(height: 14),
          for (final option in question.options)
            _answerOption(
              question: question,
              option: option,
              isSelected: selectedAnswer == option,
              textPrimary: textPrimary,
              textMuted: textMuted,
              border: border,
            ),
        ],
      ),
    );
  }

  Widget _answerOption({
    required PlacementQuestion question,
    required String option,
    required bool isSelected,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
  }) {
    final isCorrect = option == question.correctAnswer;
    final showCorrect = isSubmitted && isCorrect;
    final showWrong = isSubmitted && isSelected && !isCorrect;
    final borderColor = showCorrect
        ? AppTheme.semanticGreen
        : showWrong
            ? AppTheme.semanticRed
            : isSelected
                ? textPrimary
                : border;
    final foregroundColor = showCorrect
        ? AppTheme.semanticGreen
        : showWrong
            ? AppTheme.semanticRed
            : isSelected
                ? textPrimary
                : textMuted;

    return GestureDetector(
      onTap: isSubmitted
          ? null
          : () {
              setState(() {
                selectedAnswers[question.id] = option;
              });
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? borderColor.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: foregroundColor,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  color: foregroundColor,
                  fontSize: 14,
                  fontWeight: isSelected || showCorrect ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard({required Color textPrimary, required Color textMuted}) {
    final resultColor = passed ? AppTheme.semanticGreen : AppTheme.semanticYellow;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: resultColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: resultColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            passed ? Icons.check_circle_outline : Icons.rate_review_outlined,
            color: resultColor,
            size: 26,
          ),
          const SizedBox(height: 12),
          Text('$score%', style: TextStyle(color: textPrimary, fontSize: 30, fontWeight: FontWeight.w300, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text(
            passed
                ? '${widget.level} validated. Your path was unlocked by test.'
                : 'Keep studying. You need 85% to validate this level.',
            style: TextStyle(color: textMuted, fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _skillBadge(String label, {required Color textMuted, required Color border}) {
    final color = _skillColor(label, textMuted: textMuted);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    );
  }

  Color _skillColor(String skill, {required Color textMuted}) {
    switch (skill) {
      case 'Listening':
        return AppTheme.semanticGreen;
      case 'Speaking':
        return AppTheme.semanticYellow;
      case 'Reading':
        return AppTheme.semanticGreen;
      case 'Vocabulary':
        return AppTheme.semanticYellow;
      case 'Grammar':
        return AppTheme.semanticRed;
      default:
        return textMuted;
    }
  }
}

import 'package:flutter/material.dart';

import '../models/activity_question.dart';
import '../theme/app_theme.dart';

class QuizSectionResult {
  final int answeredCount;
  final int correctCount;
  final int totalCount;
  final bool allAnswered;

  const QuizSectionResult({
    required this.answeredCount,
    required this.correctCount,
    required this.totalCount,
    required this.allAnswered,
  });

  double get score => totalCount == 0 ? 0 : correctCount / totalCount;
}

class InteractiveQuizSection extends StatefulWidget {
  final String sectionTitle;
  final List<ActivityQuestion> questions;
  final Map<String, String> explanations;
  final ValueChanged<QuizSectionResult> onResultChanged;

  const InteractiveQuizSection({
    super.key,
    required this.sectionTitle,
    required this.questions,
    required this.explanations,
    required this.onResultChanged,
  });

  @override
  State<InteractiveQuizSection> createState() =>
      _InteractiveQuizSectionState();
}

class _InteractiveQuizSectionState extends State<InteractiveQuizSection> {
  final Map<String, String> selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitResult());
  }

  void _emitResult() {
    widget.onResultChanged(_computeResult());
  }

  QuizSectionResult _computeResult() {
    final gradable = widget.questions
        .where((q) => q.type == QuestionType.multipleChoice)
        .toList();
    final answered = gradable
        .where((q) => selectedAnswers.containsKey(q.id))
        .length;
    final correct = gradable
        .where((q) => selectedAnswers[q.id] == q.correctAnswer)
        .length;
    return QuizSectionResult(
      answeredCount: answered,
      correctCount: correct,
      totalCount: gradable.length,
      allAnswered: answered == gradable.length,
    );
  }

  void _selectAnswer(ActivityQuestion question, String option) {
    if (selectedAnswers.containsKey(question.id)) return;
    setState(() {
      selectedAnswers[question.id] = option;
    });
    _emitResult();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? const Color(0xFFF5F5F0) : const Color(0xFF1A1A1A);
    final textMuted =
        isDark ? const Color(0xFF48484A) : const Color(0xFFAEAAA2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.sectionTitle,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < widget.questions.length; i++) ...[
          _questionTile(
            widget.questions[i],
            index: i,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          if (i < widget.questions.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _questionTile(
    ActivityQuestion question, {
    required int index,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final prompt = Text(
      '${index + 1}. ${question.question}',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.3,
      ),
    );

    if (question.type != QuestionType.multipleChoice) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          prompt,
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final option in question.options)
                  _chip(option, textMuted),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Not yet interactive',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: textMuted,
            ),
          ),
        ],
      );
    }

    final selected = selectedAnswers[question.id];
    final isAnswered = selected != null;
    final explanation = widget.explanations[question.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        prompt,
        const SizedBox(height: 6),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final option in question.options)
              _optionChip(
                question: question,
                option: option,
                selected: selected,
                textMuted: textMuted,
              ),
          ],
        ),
        if (isAnswered && (explanation?.trim().isNotEmpty ?? false)) ...[
          const SizedBox(height: 6),
          Text(
            explanation!,
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.3),
          ),
        ],
      ],
    );
  }

  Widget _optionChip({
    required ActivityQuestion question,
    required String option,
    required String? selected,
    required Color textMuted,
  }) {
    final isAnswered = selected != null;
    final isCorrectOption = option == question.correctAnswer;
    final isChosen = option == selected;

    Color color = textMuted;
    if (isAnswered) {
      if (isCorrectOption) {
        color = AppTheme.semanticGreen;
      } else if (isChosen) {
        color = AppTheme.semanticRed;
      }
    }

    return GestureDetector(
      onTap: () => _selectAnswer(question, option),
      child: _chip(option, color),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

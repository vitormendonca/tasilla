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
  State<InteractiveQuizSection> createState() => _InteractiveQuizSectionState();
}

class _InteractiveQuizSectionState extends State<InteractiveQuizSection> {
  final Map<String, String> selectedAnswers = {};
  final Map<String, String> draftAnswers = {};

  bool _isGradable(ActivityQuestion question) {
    return question.type == QuestionType.multipleChoice ||
        question.type == QuestionType.dictation ||
        question.type == QuestionType.fillBlank;
  }

  String _normalized(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _isCorrect(ActivityQuestion question, String answer) {
    return _normalized(answer) == _normalized(question.correctAnswer);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitResult());
  }

  void _emitResult() {
    widget.onResultChanged(_computeResult());
  }

  QuizSectionResult _computeResult() {
    final gradable = widget.questions.where(_isGradable).toList();
    final answered = gradable
        .where((q) => selectedAnswers.containsKey(q.id))
        .length;
    final correct = gradable.where((q) {
      final answer = selectedAnswers[q.id];
      return answer != null && _isCorrect(q, answer);
    }).length;
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

  void _submitTextAnswer(ActivityQuestion question) {
    if (selectedAnswers.containsKey(question.id)) return;
    final answer = draftAnswers[question.id]?.trim() ?? '';
    if (answer.isEmpty) return;
    setState(() {
      selectedAnswers[question.id] = answer;
    });
    _emitResult();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? const Color(0xFFF5F5F0)
        : const Color(0xFF1A1A1A);
    final textMuted = isDark
        ? const Color(0xFF48484A)
        : const Color(0xFFAEAAA2);

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

    if (!_isGradable(question)) {
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
                for (final option in question.options) _chip(option, textMuted),
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

    if (question.type == QuestionType.dictation ||
        (question.type == QuestionType.fillBlank && question.options.isEmpty)) {
      return _textAnswerTile(
        question,
        prompt: prompt,
        textPrimary: textPrimary,
        textMuted: textMuted,
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

  Widget _textAnswerTile(
    ActivityQuestion question, {
    required Widget prompt,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final submitted = selectedAnswers[question.id];
    final isAnswered = submitted != null;
    final isCorrect = isAnswered && _isCorrect(question, submitted);
    final explanation = widget.explanations[question.id];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        prompt,
        const SizedBox(height: 8),
        TextField(
          key: ValueKey('answer_${question.id}'),
          enabled: !isAnswered,
          onChanged: (value) => draftAnswers[question.id] = value,
          onSubmitted: (_) => _submitTextAnswer(question),
          textInputAction: TextInputAction.done,
          style: TextStyle(fontSize: 13, color: textPrimary),
          decoration: InputDecoration(
            hintText: question.type == QuestionType.dictation
                ? 'Type what you hear'
                : 'Type the missing word or phrase',
            isDense: true,
            suffixIcon: isAnswered
                ? Icon(
                    isCorrect
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: isCorrect
                        ? AppTheme.semanticGreen
                        : AppTheme.semanticRed,
                  )
                : IconButton(
                    tooltip: 'Check answer',
                    onPressed: () => _submitTextAnswer(question),
                    icon: const Icon(Icons.arrow_forward),
                  ),
          ),
        ),
        if (isAnswered) ...[
          const SizedBox(height: 6),
          Text(
            isCorrect ? 'Correct' : 'Correct answer: ${question.correctAnswer}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isCorrect ? AppTheme.semanticGreen : AppTheme.semanticRed,
            ),
          ),
        ],
        if (isAnswered && (explanation?.trim().isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
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
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

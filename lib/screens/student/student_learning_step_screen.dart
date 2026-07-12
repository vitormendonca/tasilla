import 'package:flutter/material.dart';

import '../../data/a1_learning_experience_data.dart';
import '../../data/learning_path_data.dart';
import '../../models/learning_enums.dart';
import '../../models/learning_experience.dart';
import '../../models/learning_path_step.dart';
import '../../services/learning_path_progress_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_quiz_section.dart';

class StudentLearningStepScreen extends StatefulWidget {
  final LearningPathStep step;
  final bool alreadyCompleted;
  final Future<void> Function(String stepId)? onMarkStepCompleted;

  const StudentLearningStepScreen({
    super.key,
    required this.step,
    required this.alreadyCompleted,
    this.onMarkStepCompleted,
  });

  @override
  State<StudentLearningStepScreen> createState() =>
      _StudentLearningStepScreenState();
}

class _StudentLearningStepScreenState extends State<StudentLearningStepScreen> {
  bool isSaving = false;
  int _attemptNumber = 0;
  bool _attemptedAndFailed = false;
  String? _completionMessage;
  final Map<String, QuizSectionResult> _sectionResults = {};

  double get _combinedScore {
    final totalCorrect = _sectionResults.values.fold(
      0,
      (sum, result) => sum + result.correctCount,
    );
    final totalQuestions = _sectionResults.values.fold(
      0,
      (sum, result) => sum + result.totalCount,
    );
    if (totalQuestions == 0) return 1.0;
    return totalCorrect / totalQuestions;
  }

  bool get _allSectionsAnswered =>
      _sectionResults.values.every((result) => result.allAnswered);

  Future<void> _completeStep() async {
    if (widget.alreadyCompleted || isSaving) {
      Navigator.pop(context, false);
      return;
    }

    final experience = getA1LearningExperienceById(widget.step.id);
    final threshold = experience?.passingScore ?? widget.step.passingScore;

    if (!_allSectionsAnswered) {
      setState(() {
        _completionMessage = 'Answer all questions before completing this step.';
      });
      return;
    }

    if (_combinedScore < threshold) {
      setState(() {
        _attemptedAndFailed = true;
        _completionMessage =
            'Score: ${(_combinedScore * 100).round()}% — needs ${(threshold * 100).round()}% to pass. Review and try again.';
      });
      return;
    }

    setState(() { isSaving = true; });
    final markCompleted = widget.onMarkStepCompleted ??
        LearningPathProgressService.markStepCompleted;
    await markCompleted(widget.step.id);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _resetAttempt() {
    setState(() {
      _attemptNumber++;
      _sectionResults.clear();
      _attemptedAndFailed = false;
      _completionMessage = null;
    });
  }

  void _updateSectionResult(String section, QuizSectionResult result) {
    _sectionResults[section] = result;
    if (_completionMessage != null && !_attemptedAndFailed && mounted) {
      setState(() {
        _completionMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas      = isDark ? const Color(0xFF161618) : const Color(0xFFFAFAF8);
    final textPrimary = isDark ? const Color(0xFFF5F5F0) : const Color(0xFF1A1A1A);
    final textMuted   = isDark ? const Color(0xFF48484A) : const Color(0xFFAEAAA2);
    final surface     = isDark ? const Color(0xFF242426) : const Color(0xFFF0EEE8);
    final border      = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC);

    final experience = getA1LearningExperienceById(widget.step.id);

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMuted),
        title: Text(widget.step.type.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
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
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: _stepColor(widget.step.type), shape: BoxShape.circle),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.step.title,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                Text('${widget.step.level} ${widget.step.skillTitle}', style: TextStyle(fontSize: 12, color: textMuted)),
                const SizedBox(height: 14),
                Text(widget.step.description, style: TextStyle(fontSize: 14, color: textMuted, height: 1.45)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _developmentExercise(context, experience, isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
          const SizedBox(height: 22),
          if (_completionMessage != null) ...[
            Text(
              _completionMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: _attemptedAndFailed ? AppTheme.semanticRed : textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
          ],
          GestureDetector(
            onTap: isSaving
                ? null
                : _attemptedAndFailed
                    ? _resetAttempt
                    : _completeStep,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: _attemptedAndFailed
                    ? AppTheme.semanticRed
                    : isDark ? Colors.white : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isSaving
                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: isDark ? const Color(0xFF161618) : Colors.white, strokeWidth: 1.5))
                    : Text(
                        _attemptedAndFailed
                            ? 'TRY AGAIN'
                            : widget.alreadyCompleted ? 'ALREADY COMPLETED' : _completionLabel(widget.step.type).toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: _attemptedAndFailed || !isDark ? Colors.white : const Color(0xFF161618)),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _developmentExercise(BuildContext context, LearningExperience? experience, {required bool isDark, required Color textPrimary, required Color textMuted, required Color surface, required Color border}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_exerciseTitle(widget.step.type), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 10),
          if (experience == null) ...[
            Text(_exercisePrompt(widget.step), style: TextStyle(fontSize: 13, color: textMuted, height: 1.45)),
            const SizedBox(height: 16),
            _sampleQuestion(textMuted: textMuted, surface: surface, border: border),
          ] else
            _experienceContent(context, experience, textPrimary: textPrimary, textMuted: textMuted, border: border),
        ],
      ),
    );
  }

  Widget _experienceContent(BuildContext context, LearningExperience experience, {required Color textPrimary, required Color textMuted, required Color border}) {
    final skill = experience.primarySkill;
    final isMixed = skill == LearningSkill.mixed;

    bool shows(LearningSkill sectionSkill) => isMixed || skill == sectionSkill;

    final sections = <Widget>[
      _textSection('Objective', experience.canDoStatement, textPrimary: textPrimary, textMuted: textMuted),
      if (experience.introductionText.trim().isNotEmpty)
        _textSection('Start', experience.introductionText, textPrimary: textPrimary, textMuted: textMuted),
      if (experience.vocabularyBlocks.isNotEmpty)
        _vocabularySection(experience.vocabularyBlocks, textPrimary: textPrimary, textMuted: textMuted),
      if (experience.grammarBlocks.isNotEmpty)
        _grammarSection(experience.grammarBlocks, textPrimary: textPrimary, textMuted: textMuted),
      if (experience.listeningBlock != null && shows(LearningSkill.listening))
        _listeningSection(experience.listeningBlock!, textPrimary: textPrimary, textMuted: textMuted),
      if (experience.readingBlock != null && shows(LearningSkill.reading))
        _readingSection(experience.readingBlock!, textPrimary: textPrimary, textMuted: textMuted),
      if ((experience.quizBlock?.questions.isNotEmpty ?? false) && shows(LearningSkill.vocabularyUseOfEnglish))
        _questionsSection(experience.quizBlock!, textPrimary: textPrimary, textMuted: textMuted),
      if (experience.writingTask != null && shows(LearningSkill.writing))
        _writingSection(experience.writingTask!, textPrimary: textPrimary, textMuted: textMuted),
      if (experience.speakingTask != null && shows(LearningSkill.speaking))
        _speakingSection(experience.speakingTask!, textPrimary: textPrimary, textMuted: textMuted),
      if ((experience.rubric?.criteria.isNotEmpty ?? false) &&
          (shows(LearningSkill.writing) || shows(LearningSkill.speaking)))
        _rubricSection(experience.rubric!, textPrimary: textPrimary, textMuted: textMuted),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < sections.length; i++) ...[
          if (i > 0) Divider(color: border, height: 24),
          sections[i],
        ],
      ],
    );
  }

  Widget _textSection(String title, String body, {required Color textPrimary, required Color textMuted}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 6),
        Text(body, style: TextStyle(fontSize: 13, color: textMuted, height: 1.4)),
      ],
    );
  }

  Widget _vocabularySection(List<VocabularyBlock> blocks, {required Color textPrimary, required Color textMuted}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Vocabulary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 8),
        for (final block in blocks) ...[
          if (block.title.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(block.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
            ),
          Wrap(
            spacing: 7, runSpacing: 7,
            children: [for (final word in block.words) _contentChip(word, textMuted)],
          ),
          if (block.exampleSentences.isNotEmpty) ...[
            const SizedBox(height: 7),
            for (final example in block.exampleSentences)
              Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(example, style: TextStyle(fontSize: 12, color: textMuted, height: 1.3))),
          ],
        ],
      ],
    );
  }

  Widget _grammarSection(List<GrammarBlock> blocks, {required Color textPrimary, required Color textMuted}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Grammar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 8),
        for (final block in blocks) ...[
          Text(block.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 4),
          Text(block.explanation, style: TextStyle(fontSize: 12, color: textMuted, height: 1.35)),
          if (block.patterns.isNotEmpty) ...[
            const SizedBox(height: 7),
            Wrap(spacing: 7, runSpacing: 7, children: [for (final p in block.patterns) _contentChip(p, textMuted)]),
          ],
        ],
      ],
    );
  }

  Widget _listeningSection(ListeningBlock block, {required Color textPrimary, required Color textMuted}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Listening', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 7),
        Row(
          children: [
            Icon(Icons.volume_off_outlined, color: textMuted, size: 16),
            const SizedBox(width: 6),
            Text('Audio pending generation', style: TextStyle(fontSize: 12, color: textMuted)),
          ],
        ),
        if (block.audioPath?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(block.audioPath!, style: TextStyle(fontSize: 11, color: textMuted)),
        ],
        const SizedBox(height: 8),
        Text(block.audioScript, style: TextStyle(fontSize: 13, color: textPrimary, height: 1.4)),
        if (block.listeningQuestions.isNotEmpty) ...[
          const SizedBox(height: 14),
          InteractiveQuizSection(
            key: ValueKey('listening_attempt_$_attemptNumber'),
            sectionTitle: 'Listening comprehension',
            questions: block.listeningQuestions,
            explanations: const {},
            onResultChanged: (result) {
              _updateSectionResult('listening', result);
            },
          ),
        ],
      ],
    );
  }

  Widget _readingSection(ReadingBlock block, {required Color textPrimary, required Color textMuted}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _textSection(block.readingTitle, block.readingText, textPrimary: textPrimary, textMuted: textMuted),
        if (block.readingQuestions.isNotEmpty) ...[
          const SizedBox(height: 14),
          InteractiveQuizSection(
            key: ValueKey('reading_attempt_$_attemptNumber'),
            sectionTitle: 'Reading comprehension',
            questions: block.readingQuestions,
            explanations: const {},
            onResultChanged: (result) {
              _updateSectionResult('reading', result);
            },
          ),
        ],
      ],
    );
  }

  Widget _questionsSection(QuizBlock quizBlock, {required Color textPrimary, required Color textMuted}) {
    return InteractiveQuizSection(
      key: ValueKey('quiz_attempt_$_attemptNumber'),
      sectionTitle: 'Questions',
      questions: quizBlock.questions,
      explanations: quizBlock.explanations,
      onResultChanged: (result) {
        _updateSectionResult('quiz', result);
      },
    );
  }

  Widget _writingSection(WritingTask task, {required Color textPrimary, required Color textMuted}) {
    return _taskSection(title: 'Writing', prompt: task.writingPrompt, details: ['${task.minSentences}-${task.maxSentences} sentences', if (task.requiresTeacherReview) 'Teacher review'], requirements: task.minimumRequirements, color: AppTheme.semanticYellow, textPrimary: textPrimary, textMuted: textMuted);
  }

  Widget _speakingSection(SpeakingTask task, {required Color textPrimary, required Color textMuted}) {
    return _taskSection(title: 'Speaking', prompt: task.speakingPrompt, details: ['${task.maxRecordingSeconds}s max', if (task.requiresTeacherReview) 'Teacher review'], requirements: const [], color: textMuted, textPrimary: textPrimary, textMuted: textMuted);
  }

  Widget _taskSection({required String title, required String prompt, required List<String> details, required List<String> requirements, required Color color, required Color textPrimary, required Color textMuted}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 7),
        Text(prompt, style: TextStyle(fontSize: 13, color: textMuted, height: 1.4)),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 7),
          Wrap(spacing: 7, runSpacing: 7, children: [for (final d in details) _contentChip(d, color)]),
        ],
        if (requirements.isNotEmpty) ...[
          const SizedBox(height: 7),
          for (final r in requirements) Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(r, style: TextStyle(fontSize: 12, color: textMuted, height: 1.3))),
        ],
      ],
    );
  }

  Widget _rubricSection(Rubric rubric, {required Color textPrimary, required Color textMuted}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rubric', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 7),
        for (final criterion in rubric.criteria)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text('${criterion.maxScore}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textPrimary)),
                ),
                Expanded(child: Text('${criterion.title}: ${criterion.description}', style: TextStyle(fontSize: 12, color: textMuted, height: 1.35))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _contentChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }

  Widget _sampleQuestion({required Color textMuted, required Color surface, required Color border}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: textMuted.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
      child: Text(
        'Development activity placeholder. Real questions, audio, recording or reading content will be connected to this step later.',
        style: TextStyle(fontSize: 12, color: textMuted, height: 1.35),
      ),
    );
  }

  String _completionLabel(LearningPathStepType type) {
    switch (type) {
      case LearningPathStepType.lesson: return 'Complete Lesson';
      case LearningPathStepType.reinforcement: return 'Complete Reinforcement';
      case LearningPathStepType.review: return 'Complete Review';
      case LearningPathStepType.checkpoint: return 'Complete Checkpoint';
      case LearningPathStepType.portfolio: return 'Submit Portfolio Task';
      case LearningPathStepType.finalTest: return 'Pass Final Test';
    }
  }

  String _exerciseTitle(LearningPathStepType type) {
    switch (type) {
      case LearningPathStepType.lesson: return 'Practice activity';
      case LearningPathStepType.reinforcement: return 'Smart reinforcement';
      case LearningPathStepType.review: return 'Cumulative review';
      case LearningPathStepType.checkpoint: return 'Progress checkpoint';
      case LearningPathStepType.portfolio: return 'Certificate portfolio';
      case LearningPathStepType.finalTest: return 'Strong final test';
    }
  }

  String _exercisePrompt(LearningPathStep step) {
    if (step.skillId == a1RoadmapSkillId) {
      switch (step.type) {
        case LearningPathStepType.lesson: return 'This core experience represents one focused block inside the guided A1 certificate track.';
        case LearningPathStepType.reinforcement: return 'This smart reinforcement strengthens recent A1 language before the student moves forward.';
        case LearningPathStepType.review: return 'This mixed review combines recent A1 skills before the student moves forward.';
        case LearningPathStepType.checkpoint: return 'This checkpoint helps the teacher confirm readiness and recommend review if needed.';
        case LearningPathStepType.portfolio: return 'This portfolio task stores writing or speaking evidence for certificate readiness.';
        case LearningPathStepType.finalTest: return 'This final exam covers the complete A1 track and should feel stricter than normal practice.';
      }
    }
    switch (step.type) {
      case LearningPathStepType.lesson: return 'This lesson represents one focused practice block in the ${step.skillTitle} A1 path.';
      case LearningPathStepType.reinforcement: return 'This reinforcement should revisit recent language with short targeted practice.';
      case LearningPathStepType.review: return 'This review should mix the previous three lessons before the student moves forward.';
      case LearningPathStepType.checkpoint: return 'This checkpoint should confirm whether the student is ready to continue.';
      case LearningPathStepType.portfolio: return 'This portfolio task should collect certificate evidence for teacher review.';
      case LearningPathStepType.finalTest: return 'This test should be stricter than normal lessons and count toward skill completion.';
    }
  }

  Color _stepColor(LearningPathStepType type) {
    switch (type) {
      case LearningPathStepType.lesson: return AppTheme.semanticGreen;
      case LearningPathStepType.reinforcement: return AppTheme.semanticGreen;
      case LearningPathStepType.review: return AppTheme.semanticYellow;
      case LearningPathStepType.checkpoint: return AppTheme.semanticYellow;
      case LearningPathStepType.portfolio: return AppTheme.semanticYellow;
      case LearningPathStepType.finalTest: return AppTheme.semanticRed;
    }
  }
}

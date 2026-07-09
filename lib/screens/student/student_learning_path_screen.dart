import 'package:flutter/material.dart';

import '../../data/learning_path_data.dart';
import '../../models/learning_path_step.dart';
import '../../services/learning_path_progress_service.dart';
import '../../theme/app_theme.dart';
import 'student_learning_step_screen.dart';

class StudentLearningPathScreen extends StatefulWidget {
  final String skillId;
  const StudentLearningPathScreen({super.key, required this.skillId});

  @override
  State<StudentLearningPathScreen> createState() => _StudentLearningPathScreenState();
}

class _StudentLearningPathScreenState extends State<StudentLearningPathScreen> {
  Set<String> completedStepIds = {};
  bool isLoading = true;

  LearningSkillDefinition? get skill => getLearningSkillDefinition(widget.skillId);
  List<LearningPathStep> get steps => getLearningPathStepsBySkill(widget.skillId);

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final completed = await LearningPathProgressService.getCompletedStepIds();
    if (!mounted) return;
    setState(() { completedStepIds = completed; isLoading = false; });
  }

  Future<void> _openStep(LearningPathStep step) async {
    final isCompleted = completedStepIds.contains(step.id);
    final isUnlocked = LearningPathProgressService.isStepUnlocked(
      step: step, completedStepIds: completedStepIds,
    );
    if (!isUnlocked) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete the previous step to unlock this.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1400),
        ),
      );
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StudentLearningStepScreen(step: step, alreadyCompleted: isCompleted)),
    );
    if (result == true) await _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas = isDark ? const Color(0xFF161618) : const Color(0xFFFAFAF8);
    final textPrimary = isDark ? const Color(0xFFF5F5F0) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF48484A) : const Color(0xFFAEAAA2);
    final surface = isDark ? const Color(0xFF242426) : const Color(0xFFF0EEE8);
    final border = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC);

    final skillDefinition = skill;
    if (skillDefinition == null) {
      return Scaffold(
        backgroundColor: canvas,
        appBar: _appBar(canvas, textPrimary, textMuted, 'Path'),
        body: Center(child: Text('Skill not found.', style: TextStyle(color: textMuted))),
      );
    }

    final progress = LearningPathProgressService.getSkillProgressFromCompleted(
      skillId: widget.skillId, completedStepIds: completedStepIds,
    );

    return Scaffold(
      backgroundColor: canvas,
      appBar: _appBar(canvas, textPrimary, textMuted, skillDefinition.title),
      body: RefreshIndicator(
        onRefresh: _loadProgress,
        color: textPrimary,
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: textPrimary, strokeWidth: 1.5))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  _header(skillDefinition, progress, isDark, textPrimary, textMuted, surface, border),
                  const SizedBox(height: 24),
                  Text('LESSONS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
                  const SizedBox(height: 12),
                  for (final step in steps) _stepTile(step, isDark, textPrimary, textMuted, surface, border),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _appBar(Color canvas, Color textPrimary, Color textMuted, String title) {
    return AppBar(
      backgroundColor: canvas,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: textMuted),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
    );
  }

  Widget _header(LearningSkillDefinition def, LearningPathSkillProgress progress, bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A1 ${def.title}'.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
          const SizedBox(height: 8),
          Text(def.title, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text(def.description, style: TextStyle(fontSize: 13, color: textMuted, height: 1.4)),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.lessonProgress.clamp(0.0, 1.0).toDouble(),
              minHeight: 3, color: textPrimary, backgroundColor: border,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat('${progress.completedLessons}/${progress.totalLessons}', 'LESSONS', textPrimary, textMuted),
              const SizedBox(width: 20),
              _miniStat('${progress.completedReviews}/${progress.totalReviews}', 'REVIEWS', textPrimary, textMuted),
              const SizedBox(width: 20),
              _miniStat(progress.finalTestCompleted ? 'PASS' : '—', 'FINAL', progress.finalTestCompleted ? AppTheme.semanticGreen : textPrimary, textMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, Color valueColor, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: valueColor)),
        Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: textMuted)),
      ],
    );
  }

  Widget _stepTile(LearningPathStep step, bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    final isCompleted = completedStepIds.contains(step.id);
    final isUnlocked = LearningPathProgressService.isStepUnlocked(step: step, completedStepIds: completedStepIds);
    final isMilestone = step.type == LearningPathStepType.review ||
        step.type == LearningPathStepType.checkpoint ||
        step.type == LearningPathStepType.portfolio ||
        step.type == LearningPathStepType.finalTest;

    final statusColor = isCompleted
        ? AppTheme.semanticGreen
        : !isUnlocked
            ? textMuted
            : isMilestone
                ? AppTheme.semanticYellow
                : textPrimary;

    final badgeLabel = isCompleted ? 'DONE' : isUnlocked ? step.type.label.toUpperCase() : 'LOCKED';

    return GestureDetector(
      onTap: () => _openStep(step),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isMilestone && isUnlocked ? statusColor.withValues(alpha: 0.3) : border),
        ),
        child: Row(
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isUnlocked ? textPrimary : textMuted)),
                  const SizedBox(height: 2),
                  Text(step.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Text(badgeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: statusColor)),
            ),
          ],
        ),
      ),
    );
  }
}

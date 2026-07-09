import 'package:flutter/material.dart';

import '../../data/learning_path_data.dart';
import '../../models/learning_enums.dart';
import '../../models/learning_path_step.dart';
import '../../services/learning_path_progress_service.dart';
import '../../theme/app_theme.dart';
import 'student_learning_step_screen.dart';

class StudentA1RoadmapScreen extends StatefulWidget {
  const StudentA1RoadmapScreen({super.key});

  @override
  State<StudentA1RoadmapScreen> createState() => _StudentA1RoadmapScreenState();
}

class _StudentA1RoadmapScreenState extends State<StudentA1RoadmapScreen> {
  Set<String> completedStepIds = {};
  bool isLoading = true;

  List<LearningPathStep> get roadSteps => getA1RoadmapSteps();

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final completed = await LearningPathProgressService.getCompletedStepIds();
    if (!mounted) return;
    setState(() {
      completedStepIds = completed;
      isLoading = false;
    });
  }

  bool _isRoadStepUnlocked(int index) {
    if (index <= 0) return true;
    final step = roadSteps[index];
    if (completedStepIds.contains(step.id)) return true;
    return completedStepIds.contains(roadSteps[index - 1].id);
  }

  int? _nextRoadStepIndex(List<LearningPathStep> steps) {
    for (int i = 0; i < steps.length; i++) {
      if (!completedStepIds.contains(steps[i].id) && _isRoadStepUnlocked(i)) return i;
    }
    return null;
  }

  Future<void> _openStep(int index, LearningPathStep step) async {
    final isCompleted = completedStepIds.contains(step.id);
    final isUnlocked = _isRoadStepUnlocked(index);
    if (!isUnlocked) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete the previous road step to unlock this.'), behavior: SnackBarBehavior.floating, duration: Duration(milliseconds: 1400)),
      );
      return;
    }
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => StudentLearningStepScreen(step: step, alreadyCompleted: isCompleted)));
    if (result == true) await _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas      = isDark ? const Color(0xFF161618) : const Color(0xFFFAFAF8);
    final textPrimary = isDark ? const Color(0xFFF5F5F0) : const Color(0xFF1A1A1A);
    final textMuted   = isDark ? const Color(0xFF48484A) : const Color(0xFFAEAAA2);
    final surface     = isDark ? const Color(0xFF242426) : const Color(0xFFF0EEE8);
    final border      = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC);

    final steps = roadSteps;

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMuted),
        title: Text('A1 Road Map', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProgress,
        color: textPrimary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _header(steps, isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
            const SizedBox(height: 20),
            if (isLoading)
              Center(child: Padding(padding: const EdgeInsets.all(28), child: CircularProgressIndicator(color: textPrimary, strokeWidth: 1.5)))
            else
              for (int i = 0; i < steps.length; i++)
                _roadStepTile(i, steps[i], isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
          ],
        ),
      ),
    );
  }

  Widget _header(List<LearningPathStep> steps, {required bool isDark, required Color textPrimary, required Color textMuted, required Color surface, required Color border}) {
    final completedRoadSteps = steps.where((s) => completedStepIds.contains(s.id)).length;
    final completedLessons = steps.where((s) => s.activityKind == ActivityKind.coreActivity && completedStepIds.contains(s.id)).length;
    final completedReviews = steps.where((s) => s.type == LearningPathStepType.review && completedStepIds.contains(s.id)).length;
    final completedCertificateTasks = steps.where((s) => _isCertificateTask(s) && completedStepIds.contains(s.id)).length;
    final progress = steps.isEmpty ? 0.0 : completedRoadSteps / steps.length;
    final nextIndex = isLoading ? null : _nextRoadStepIndex(steps);
    VoidCallback? continueAction;
    if (nextIndex != null) continueAction = () => _openStep(nextIndex, steps[nextIndex]);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A1 ROAD MAP', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
          const SizedBox(height: 8),
          Text('A1 Road Map', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('A guided A1 certificate track with core experiences, smart reinforcement, reviews, checkpoints, portfolio evidence and a final exam.', style: TextStyle(fontSize: 13, color: textMuted, height: 1.4)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0).toDouble(), minHeight: 3, color: textPrimary, backgroundColor: border),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _chip('$completedRoadSteps/${steps.length} experiences', textPrimary, border),
              _chip('$completedLessons/${_totalByKind(steps, ActivityKind.coreActivity)} core', textPrimary, border),
              _chip('$completedReviews/${_totalByType(steps, LearningPathStepType.review)} reviews', AppTheme.semanticYellow, border),
              _chip('$completedCertificateTasks/${_totalCertificateTasks(steps)} certificate', textMuted, border),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: continueAction,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  nextIndex == null ? 'A1 ROAD COMPLETE' : 'CONTINUE ROAD →',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: isDark ? const Color(0xFF161618) : Colors.white),
                ),
              ),
            ),
          ),
          if (nextIndex != null) ...[
            const SizedBox(height: 8),
            Text('Up next: ${steps[nextIndex].title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: textMuted)),
          ],
        ],
      ),
    );
  }

  Widget _roadStepTile(int index, LearningPathStep step, {required bool isDark, required Color textPrimary, required Color textMuted, required Color surface, required Color border}) {
    final isCompleted = completedStepIds.contains(step.id);
    final isUnlocked = _isRoadStepUnlocked(index);
    final isMilestone = _isMilestoneType(step.type);
    final stepColor = isCompleted ? AppTheme.semanticGreen : isMilestone ? _stepTypeColor(step.type) : isUnlocked ? textPrimary : textMuted;
    final badgeLabel = isCompleted ? 'Done' : isUnlocked ? step.type.label : 'Locked';

    return GestureDetector(
      onTap: () => _openStep(index, step),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isMilestone && isUnlocked ? stepColor.withValues(alpha: 0.35) : border),
        ),
        child: Row(
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: stepColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _chip('Step ${index + 1}', textMuted, border),
                      const SizedBox(width: 6),
                      _chip(step.skillTitle, isUnlocked ? textPrimary : textMuted, border),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(step.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isUnlocked ? textPrimary : textMuted)),
                  const SizedBox(height: 3),
                  Text(step.description, style: TextStyle(fontSize: 11, color: textMuted, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _chip(badgeLabel, stepColor, border),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }

  int _totalByType(List<LearningPathStep> steps, LearningPathStepType type) => steps.where((s) => s.type == type).length;
  int _totalByKind(List<LearningPathStep> steps, ActivityKind kind) => steps.where((s) => s.activityKind == kind).length;
  int _totalCertificateTasks(List<LearningPathStep> steps) => steps.where(_isCertificateTask).length;
  bool _isCertificateTask(LearningPathStep step) => step.activityKind == ActivityKind.checkpoint || step.activityKind == ActivityKind.portfolioTask || step.activityKind == ActivityKind.finalExam;
  bool _isMilestoneType(LearningPathStepType type) => type == LearningPathStepType.review || type == LearningPathStepType.checkpoint || type == LearningPathStepType.portfolio || type == LearningPathStepType.finalTest;

  Color _stepTypeColor(LearningPathStepType type) {
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

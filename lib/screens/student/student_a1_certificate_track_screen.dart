import 'package:flutter/material.dart';

import '../../data/learning_path_data.dart';
import '../../models/learning_enums.dart';
import '../../models/learning_path_step.dart';
import '../../services/learning_path_progress_service.dart';
import '../../theme/app_theme.dart';
import 'student_learning_step_screen.dart';

class StudentA1CertificateTrackScreen extends StatefulWidget {
  const StudentA1CertificateTrackScreen({super.key});

  @override
  State<StudentA1CertificateTrackScreen> createState() => _StudentA1CertificateTrackScreenState();
}

class _StudentA1CertificateTrackScreenState extends State<StudentA1CertificateTrackScreen> {
  Set<String> completedStepIds = {};
  bool isLoading = true;

  List<LearningPathStep> get certificateExperiences {
    return getA1RoadmapSteps()
        .where((step) =>
            step.activityKind == ActivityKind.coreActivity &&
            (step.lessonNumber ?? 0) >= 1 &&
            (step.lessonNumber ?? 0) <= 20)
        .toList();
  }

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

  bool _isUnlocked(int index) {
    if (index <= 0) return true;
    final steps = certificateExperiences;
    final step = steps[index];
    if (completedStepIds.contains(step.id)) return true;
    return completedStepIds.contains(steps[index - 1].id);
  }

  Future<void> _openStep(int index, LearningPathStep step) async {
    if (!_isUnlocked(index)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete the previous experience to unlock this.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 1400),
        ),
      );
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StudentLearningStepScreen(step: step, alreadyCompleted: completedStepIds.contains(step.id))),
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

    final steps = certificateExperiences;

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMuted),
        title: Text('Certificate Track', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProgress,
        color: textPrimary,
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: textPrimary, strokeWidth: 1.5))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  _header(steps, isDark, textPrimary, textMuted, surface, border),
                  const SizedBox(height: 24),
                  Text('CORE EXPERIENCES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
                  const SizedBox(height: 12),
                  for (int i = 0; i < steps.length; i++) _tile(i, steps[i], isDark, textPrimary, textMuted, surface, border),
                ],
              ),
      ),
    );
  }

  Widget _header(List<LearningPathStep> steps, bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    final completed = steps.where((s) => completedStepIds.contains(s.id)).length;
    final progress = steps.isEmpty ? 0.0 : completed / steps.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A1 CERTIFICATE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
          const SizedBox(height: 8),
          Text('Certificate Track', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Foundation and Personal Life — experiences 1 to 20.', style: TextStyle(fontSize: 13, color: textMuted, height: 1.4)),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0).toDouble(), minHeight: 3, color: textPrimary, backgroundColor: border),
          ),
          const SizedBox(height: 12),
          Text('$completed of ${steps.length} completed', style: TextStyle(fontSize: 11, color: textMuted)),
        ],
      ),
    );
  }

  Widget _tile(int index, LearningPathStep step, bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    final isCompleted = completedStepIds.contains(step.id);
    final isUnlocked = _isUnlocked(index);
    final statusColor = isCompleted ? AppTheme.semanticGreen : isUnlocked ? textPrimary : textMuted;

    return GestureDetector(
      onTap: () => _openStep(index, step),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
        child: Row(
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.id, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: textMuted)),
                  const SizedBox(height: 3),
                  Text(step.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isUnlocked ? textPrimary : textMuted)),
                  const SizedBox(height: 2),
                  Text(step.canDoStatement, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(isCompleted ? Icons.check : isUnlocked ? Icons.arrow_forward_ios_rounded : Icons.lock_outline, color: statusColor, size: 14),
          ],
        ),
      ),
    );
  }
}

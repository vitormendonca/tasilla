import 'package:flutter/material.dart';

import '../../data/learning_path_data.dart';
import '../../services/learning_path_progress_service.dart';
import '../../theme/app_theme.dart';

class TeacherStudentProgressScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentLevel;

  const TeacherStudentProgressScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentLevel,
  });

  @override
  State<TeacherStudentProgressScreen> createState() => _TeacherStudentProgressScreenState();
}

class _TeacherStudentProgressScreenState extends State<TeacherStudentProgressScreen> {
  Map<String, LearningPathSkillProgress> progressBySkill = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await LearningPathProgressService.getAllSkillProgressForStudent(
      studentId: widget.studentId,
      studentName: widget.studentName,
    );

    if (!mounted) return;

    setState(() {
      progressBySkill = progress;
      isLoading = false;
    });
  }

  int get totalCompletedSteps => progressBySkill.values.fold(0, (sum, p) => sum + p.completedSteps);
  int get totalSteps => progressBySkill.values.fold(0, (sum, p) => sum + p.totalSteps);
  int get totalLessonsCompleted => progressBySkill.values.fold(0, (sum, p) => sum + p.completedLessons);
  int get finalTestsPassed => progressBySkill.values.where((p) => p.finalTestCompleted).length;
  int get overallPercent => totalSteps == 0 ? 0 : ((totalCompletedSteps / totalSteps) * 100).round();

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
        title: Text('Student Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        actions: [
          IconButton(
            tooltip: 'Refresh progress',
            onPressed: _loadProgress,
            icon: Icon(Icons.refresh, color: textMuted, size: 20),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProgress,
        color: textPrimary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Student header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: textPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        widget.studentName.isEmpty ? '?' : widget.studentName[0].toUpperCase(),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.studentName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary)),
                        const SizedBox(height: 6),
                        _chip('Level ${widget.studentLevel}', textMuted, border),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            if (isLoading)
              Center(child: Padding(padding: const EdgeInsets.only(top: 40), child: CircularProgressIndicator(color: textPrimary, strokeWidth: 1.5)))
            else ...[
              // Overall card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: textPrimary, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Overall Progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                              const SizedBox(height: 2),
                              Text('$totalCompletedSteps/$totalSteps path steps completed', style: TextStyle(fontSize: 12, color: textMuted)),
                            ],
                          ),
                        ),
                        Text('$overallPercent%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: totalSteps == 0 ? 0.0 : totalCompletedSteps / totalSteps,
                        minHeight: 3,
                        color: textPrimary,
                        backgroundColor: border,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _miniStat(label: 'LESSONS', value: '$totalLessonsCompleted', color: AppTheme.semanticGreen, surface: surface, border: border, textMuted: textMuted),
                        const SizedBox(width: 10),
                        _miniStat(label: 'FINAL TESTS', value: '$finalTestsPassed/5', color: AppTheme.semanticRed, surface: surface, border: border, textMuted: textMuted),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Text('LEARNING PATH', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
              const SizedBox(height: 4),
              Text('Progress by skill across lessons, reviews and tests.', style: TextStyle(fontSize: 12, color: textMuted)),
              const SizedBox(height: 12),

              for (final skill in learningSkillDefinitions)
                _skillProgressCard(skill, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
            ],
          ],
        ),
      ),
    );
  }

  Widget _skillProgressCard(
    LearningSkillDefinition skill, {
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final progress = progressBySkill[skill.id] ??
        LearningPathSkillProgress(
          skillId: skill.id,
          completedLessons: 0,
          totalLessons: 12,
          completedReviews: 0,
          totalReviews: 4,
          finalTestCompleted: false,
        );

    final completedSteps = progress.completedSteps;
    final totalSkillSteps = progress.totalSteps;
    final percent = totalSkillSteps == 0 ? 0 : ((completedSteps / totalSkillSteps) * 100).round();
    final finalColor = progress.finalTestCompleted ? AppTheme.semanticGreen : textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_skillIcon(skill.id), color: textMuted, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(skill.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                    const SizedBox(height: 2),
                    Text(skill.description, style: TextStyle(fontSize: 11, color: textMuted, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('$percent%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: totalSkillSteps == 0 ? 0.0 : completedSteps / totalSkillSteps,
              minHeight: 3,
              color: textPrimary,
              backgroundColor: border,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _chip('${progress.completedLessons}/${progress.totalLessons} lessons', textPrimary, border),
              _chip('${progress.completedReviews}/${progress.totalReviews} reviews', AppTheme.semanticYellow, border),
              _chip(progress.finalTestCompleted ? 'Final passed' : 'Final pending', finalColor, border),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required Color color,
    required Color surface,
    required Color border,
    required Color textMuted,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, color: color)),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: textMuted)),
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
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }

  IconData _skillIcon(String skillId) {
    switch (skillId) {
      case 'listening': return Icons.headphones_outlined;
      case 'speaking': return Icons.mic_none_outlined;
      case 'reading': return Icons.menu_book_outlined;
      case 'vocabulary': return Icons.style_outlined;
      case 'homework': return Icons.edit_note_outlined;
      default: return Icons.school_outlined;
    }
  }
}

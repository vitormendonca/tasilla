import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/speaking_activity.dart';
import '../../services/assignment_service.dart';
import '../../services/student_progress_service.dart';
import '../../theme/app_theme.dart';

class SpeakingActivityScreen extends StatefulWidget {
  final SpeakingActivity activity;

  const SpeakingActivityScreen({super.key, required this.activity});

  @override
  State<SpeakingActivityScreen> createState() => _SpeakingActivityScreenState();
}

class _SpeakingActivityScreenState extends State<SpeakingActivityScreen> {
  final Set<int> checkedItems = {};
  bool submitted = false;
  int? lastScore;

  @override
  void initState() {
    super.initState();
    _loadLastResult();
  }

  Future<void> _loadLastResult() async {
    final score = await StudentProgressService.getActivityScore(
      activityId: widget.activity.id,
      category: 'speaking',
    );

    if (!mounted) return;

    setState(() {
      lastScore = score;
      if (score != null) {
        submitted = true;
        checkedItems.addAll(List<int>.generate(widget.activity.checklist.length, (index) => index));
      }
    });
  }

  bool get isReadyToSubmit => checkedItems.length == widget.activity.checklist.length;

  Future<void> _submitForReview() async {
    if (!isReadyToSubmit || submitted) return;

    final prefs = await SharedPreferences.getInstance();
    final currentStudentName = prefs.getString('currentStudentName') ?? '';

    await StudentProgressService.saveActivityScore(
      activityId: widget.activity.id,
      category: 'speaking',
      score: 100,
    );

    if (currentStudentName.isNotEmpty) {
      await AssignmentService.markStudentAssignmentAsReviewNeeded(
        studentName: currentStudentName,
        title: widget.activity.title,
        category: 'Speaking',
      );
    }

    if (!mounted) return;

    setState(() {
      submitted = true;
      lastScore = 100;
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
        title: Text(widget.activity.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SPEAKING ACTIVITY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
                const SizedBox(height: 8),
                Text(widget.activity.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text(widget.activity.description, style: TextStyle(fontSize: 13, color: textMuted, height: 1.4)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _chip(widget.activity.level, textMuted, border),
                    _chip(submitted ? 'Submitted' : 'Teacher Review', submitted ? AppTheme.semanticYellow : textMuted, border),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Speaking Prompt
          _textPanel(
            title: 'Speaking Prompt',
            body: widget.activity.prompt,
            icon: Icons.record_voice_over_outlined,
            textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
          ),
          const SizedBox(height: 10),

          // Target Language
          _textPanel(
            title: 'Target Language',
            body: widget.activity.targetLanguage,
            icon: Icons.chat_bubble_outline,
            textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
          ),
          const SizedBox(height: 10),

          // Preparation
          _textPanel(
            title: 'Preparation',
            body: widget.activity.preparationTip,
            icon: Icons.tips_and_updates_outlined,
            textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
          ),
          const SizedBox(height: 16),

          // Self check section
          Text('SELF CHECK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
          const SizedBox(height: 4),
          Text(
            lastScore == null ? 'Confirm each item after practicing aloud.' : 'Your practice was submitted for review.',
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
            child: Column(
              children: [
                for (int index = 0; index < widget.activity.checklist.length; index++)
                  CheckboxListTile(
                    value: checkedItems.contains(index),
                    onChanged: submitted
                        ? null
                        : (value) {
                            setState(() {
                              if (value == true) checkedItems.add(index);
                              else checkedItems.remove(index);
                            });
                          },
                    title: Text(widget.activity.checklist[index], style: TextStyle(fontSize: 14, color: textPrimary)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: textPrimary,
                    checkColor: isDark ? const Color(0xFF161618) : Colors.white,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          GestureDetector(
            onTap: isReadyToSubmit && !submitted ? _submitForReview : null,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: isReadyToSubmit && !submitted
                    ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                    : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    submitted ? Icons.rate_review_outlined : Icons.upload_file_outlined,
                    size: 18,
                    color: isReadyToSubmit && !submitted
                        ? (isDark ? const Color(0xFF161618) : Colors.white)
                        : textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    submitted ? 'Submitted for Review' : 'Submit Speaking Practice',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isReadyToSubmit && !submitted
                          ? (isDark ? const Color(0xFF161618) : Colors.white)
                          : textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (submitted) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.semanticYellow.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.semanticYellow.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.rate_review_outlined, color: AppTheme.semanticYellow, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your speaking practice is ready for teacher review.',
                      style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _textPanel({
    required String title,
    required String body,
    required IconData icon,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                const SizedBox(height: 6),
                Text(body, style: TextStyle(fontSize: 13, color: textMuted, height: 1.4)),
              ],
            ),
          ),
        ],
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
}

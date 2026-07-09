import 'package:flutter/material.dart';

import '../../data/teacher_mock_data.dart';
import '../../models/teacher_class.dart';
import '../../theme/app_theme.dart';

class TeacherClassesScreen extends StatelessWidget {
  const TeacherClassesScreen({super.key});

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
        title: Text('My Classes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('MY CLASSES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
          const SizedBox(height: 4),
          Text('Manage your groups, class codes, schedules, and student progress.', style: TextStyle(fontSize: 12, color: textMuted)),
          const SizedBox(height: 20),
          for (final teacherClass in teacherClasses)
            _classCard(teacherClass: teacherClass, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
          const SizedBox(height: 10),
          _infoCard(textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
        ],
      ),
    );
  }

  Widget _classCard({
    required TeacherClass teacherClass,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final bool needsReview = teacherClass.reviewNeeded > 0;
    final statusColor = needsReview ? AppTheme.semanticYellow : AppTheme.semanticGreen;

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
              Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teacherClass.className, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                    const SizedBox(height: 2),
                    Text('${teacherClass.students} students · ${teacherClass.classType}', style: TextStyle(fontSize: 12, color: textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  needsReview ? 'REVIEW' : 'ON TRACK',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(teacherClass.description, style: TextStyle(fontSize: 13, color: textMuted, height: 1.4)),
          const SizedBox(height: 12),
          _infoRow(icon: Icons.key_outlined, title: 'Class Code', value: teacherClass.classCode, textPrimary: textPrimary, textMuted: textMuted),
          _infoRow(icon: Icons.calendar_today_outlined, title: 'Class Time', value: '${teacherClass.classDay} at ${teacherClass.classTime}', textPrimary: textPrimary, textMuted: textMuted),
          _infoRow(icon: Icons.repeat_outlined, title: 'Frequency', value: teacherClass.frequency, textPrimary: textPrimary, textMuted: textMuted),
          _infoRow(icon: Icons.computer_outlined, title: 'Format', value: teacherClass.format, textPrimary: textPrimary, textMuted: textMuted),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat(label: 'COMPLETED', value: '${teacherClass.completed}', color: AppTheme.semanticGreen, textMuted: textMuted, border: border),
              const SizedBox(width: 8),
              _miniStat(label: 'REVIEW', value: '${teacherClass.reviewNeeded}', color: AppTheme.semanticYellow, textMuted: textMuted, border: border),
              const SizedBox(width: 8),
              _miniStat(label: 'AVERAGE', value: '${teacherClass.average}%', color: textPrimary, textMuted: textMuted, border: border),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, color: textMuted, size: 15),
          const SizedBox(width: 8),
          Text('$title: ', style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: textPrimary))),
        ],
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required Color color,
    required Color textMuted,
    required Color border,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: color)),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMING SOON', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
          const SizedBox(height: 8),
          Text(
            'Soon teachers will be able to create real classes, edit class codes, approve student requests, and add students by Student ID.',
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

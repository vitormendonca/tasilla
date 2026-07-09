import 'package:flutter/material.dart';

import 'teacher_assigned_activities_screen.dart';
import 'teacher_students_screen.dart';

class AddAssignmentScreen extends StatelessWidget {
  const AddAssignmentScreen({super.key});

  void _goToStudents(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TeacherStudentsScreen()),
    );
  }

  void _openAssignedActivities(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TeacherAssignedActivitiesScreen()),
    );
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
        title: Text('Add Assignment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('ADD ASSIGNMENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
          const SizedBox(height: 4),
          Text('Assignments start from a student profile so the teacher keeps the right context.', style: TextStyle(fontSize: 12, color: textMuted)),
          const SizedBox(height: 20),

          // Info card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: textMuted, shape: BoxShape.circle)),
                const SizedBox(height: 14),
                Text('New assignment flow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimary)),
                const SizedBox(height: 8),
                Text(
                  'Assignments are now created from the student profile. This makes the process easier because the app already knows which student will receive the activity.',
                  style: TextStyle(fontSize: 13, color: textMuted, height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Steps card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HOW TO ASSIGN AN ACTIVITY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
                const SizedBox(height: 14),
                _StepItem(number: '1', text: 'Go to Students.', textPrimary: textPrimary, textMuted: textMuted, border: border),
                _StepItem(number: '2', text: 'Choose a student.', textPrimary: textPrimary, textMuted: textMuted, border: border),
                _StepItem(number: '3', text: 'Tap Assign Activity.', textPrimary: textPrimary, textMuted: textMuted, border: border),
                _StepItem(number: '4', text: 'Choose the activity and confirm.', textPrimary: textPrimary, textMuted: textMuted, border: border),
              ],
            ),
          ),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: () => _goToStudents(context),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 18, color: isDark ? const Color(0xFF161618) : Colors.white),
                  const SizedBox(width: 8),
                  Text('Go to Students', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF161618) : Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          GestureDetector(
            onTap: () => _openAssignedActivities(context),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: textMuted.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 18, color: textMuted),
                  const SizedBox(width: 8),
                  Text('View Assigned Activities', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String text;
  final Color textPrimary;
  final Color textMuted;
  final Color border;

  const _StepItem({
    required this.number,
    required this.text,
    required this.textPrimary,
    required this.textMuted,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: textMuted.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: textMuted.withValues(alpha: 0.25)),
            ),
            child: Text(number, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(text, style: TextStyle(fontSize: 14, color: textMuted, height: 1.4)),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/theme_controller.dart';
import 'teacher_assigned_activities_screen.dart';
import 'teacher_classes_screen.dart';
import 'teacher_profile_screen.dart';
import 'teacher_students_screen.dart';

class TeacherHomeScreen extends StatelessWidget {
  const TeacherHomeScreen({super.key});

  void _showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$featureName will be available soon.')),
    );
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
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
        title: Text('Teacher Dashboard', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(ThemeController.iconFor(context), color: textMuted, size: 20),
            onPressed: () => ThemeController.toggle(context),
          ),
          IconButton(
            tooltip: 'Teacher Profile',
            icon: Icon(Icons.person_outline, color: textMuted, size: 20),
            onPressed: () => _openScreen(context, const TeacherProfileScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('TEACHER DASHBOARD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
          const SizedBox(height: 6),
          Text('Welcome, Teacher', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('Manage your students, classes, activities and progress from here.', style: TextStyle(fontSize: 13, color: textMuted, height: 1.4)),
          const SizedBox(height: 24),
          _actionTile(
            icon: Icons.person_outline,
            title: 'Students',
            subtitle: 'View students, assign activities and check individual progress.',
            onTap: () => _openScreen(context, const TeacherStudentsScreen()),
            textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
          ),
          _actionTile(
            icon: Icons.groups_outlined,
            title: 'Classes',
            subtitle: 'Manage groups, class schedules and class activities.',
            onTap: () => _openScreen(context, const TeacherClassesScreen()),
            textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
          ),
          _actionTile(
            icon: Icons.assignment_outlined,
            title: 'Activities',
            subtitle: 'View available homework, listening and vocabulary activities.',
            onTap: () => _openScreen(context, const TeacherAssignedActivitiesScreen()),
            textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
          ),
          _actionTile(
            icon: Icons.query_stats_outlined,
            title: 'Progress',
            subtitle: 'Track completed activities and student development.',
            onTap: () => _showComingSoon(context, 'Progress'),
            textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(color: textMuted, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Icon(icon, color: textMuted, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: textMuted, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, color: textMuted, size: 13),
          ],
        ),
      ),
    );
  }
}

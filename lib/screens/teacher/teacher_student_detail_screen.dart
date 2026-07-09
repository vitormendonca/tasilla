import 'package:flutter/material.dart';

import '../../models/assigned_activity.dart';
import '../../services/assignment_service.dart';
import '../../theme/app_theme.dart';
import 'teacher_assign_activity_screen.dart';
import 'teacher_student_assigned_activities_screen.dart';
import 'teacher_student_progress_screen.dart';

class TeacherStudentDetailScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentLevel;
  final String accessCode;

  const TeacherStudentDetailScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentLevel,
    required this.accessCode,
  });

  @override
  State<TeacherStudentDetailScreen> createState() => _TeacherStudentDetailScreenState();
}

class _TeacherStudentDetailScreenState extends State<TeacherStudentDetailScreen> {
  List<AssignedActivity> assignedActivities = [];
  bool isLoadingAssignments = true;

  @override
  void initState() {
    super.initState();
    _loadAssignedActivities();
  }

  Future<void> _loadAssignedActivities() async {
    final activities = await AssignmentService.getAssignedActivitiesForStudent(
      studentId: widget.studentId,
      studentName: widget.studentName,
    );

    if (!mounted) return;

    setState(() {
      assignedActivities = activities;
      isLoadingAssignments = false;
    });
  }

  int get totalAssigned => assignedActivities.length;
  int get pendingCount => assignedActivities.where((a) => a.status == 'Pending').length;
  int get completedCount => assignedActivities.where((a) => a.status == 'Completed' || a.status == 'Reviewed').length;
  int get reviewNeededCount => assignedActivities.where((a) => a.status == 'Review Needed').length;

  Future<void> _openAssignActivityScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherAssignActivityScreen(
          studentId: widget.studentId,
          studentName: widget.studentName,
          studentLevel: widget.studentLevel,
        ),
      ),
    );
    if (!context.mounted) return;
    await _loadAssignedActivities();
  }

  Future<void> _openStudentAssignedActivitiesScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherStudentAssignedActivitiesScreen(
          studentId: widget.studentId,
          studentName: widget.studentName,
          studentLevel: widget.studentLevel,
        ),
      ),
    );
    await _loadAssignedActivities();
  }

  void _openStudentProgressScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherStudentProgressScreen(
          studentId: widget.studentId,
          studentName: widget.studentName,
          studentLevel: widget.studentLevel,
        ),
      ),
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

    final totalText = isLoadingAssignments ? '…' : '$totalAssigned';
    final pendingText = isLoadingAssignments ? '…' : '$pendingCount';
    final completedText = isLoadingAssignments ? '…' : '$completedCount';
    final reviewText = isLoadingAssignments ? '…' : '$reviewNeededCount';

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMuted),
        title: Text('Student Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        actions: [
          IconButton(
            tooltip: 'Refresh assignments',
            onPressed: _loadAssignedActivities,
            icon: Icon(Icons.refresh, color: textMuted, size: 20),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAssignedActivities,
        color: textPrimary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Student header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: textPrimary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.studentName.isEmpty ? '?' : widget.studentName[0].toUpperCase(),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.studentName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: textPrimary)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _chip('Level ${widget.studentLevel}', textMuted, border),
                            if (widget.accessCode.isNotEmpty)
                              _chip(widget.accessCode, textMuted, border),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Assignment summary
            Text('ASSIGNMENT SUMMARY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
            const SizedBox(height: 4),
            Text('Current guidance and review state for this student.', style: TextStyle(fontSize: 12, color: textMuted)),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard(label: 'ASSIGNED', value: totalText, color: textPrimary, surface: surface, border: border, textMuted: textMuted),
                const SizedBox(width: 8),
                _statCard(label: 'PENDING', value: pendingText, color: pendingCount > 0 ? AppTheme.semanticYellow : textMuted, surface: surface, border: border, textMuted: textMuted),
                const SizedBox(width: 8),
                _statCard(label: 'DONE', value: completedText, color: completedCount > 0 ? AppTheme.semanticGreen : textMuted, surface: surface, border: border, textMuted: textMuted),
                const SizedBox(width: 8),
                _statCard(label: 'REVIEW', value: reviewText, color: reviewNeededCount > 0 ? AppTheme.semanticRed : textMuted, surface: surface, border: border, textMuted: textMuted),
              ],
            ),
            const SizedBox(height: 22),

            // Actions
            _actionTile(
              icon: Icons.add_task_outlined,
              title: 'Assign Activity',
              subtitle: 'Choose a homework, listening or vocabulary activity for this student.',
              onTap: () => _openAssignActivityScreen(context),
              textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
            ),
            _actionTile(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Assigned Activities',
              subtitle: 'View or manage activities for this student.',
              onTap: () => _openStudentAssignedActivitiesScreen(context),
              textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
            ),
            _actionTile(
              icon: Icons.query_stats_outlined,
              title: 'Progress',
              subtitle: 'Check completed path steps and skill performance.',
              onTap: () => _openStudentProgressScreen(context),
              textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color color,
    required Color surface,
    required Color border,
    required Color textMuted,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, letterSpacing: 0.8, color: textMuted, fontWeight: FontWeight.w600)),
          ],
        ),
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
            Container(width: 6, height: 6, decoration: BoxDecoration(color: textMuted, shape: BoxShape.circle)),
            const SizedBox(width: 14),
            Icon(icon, color: textMuted, size: 20),
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

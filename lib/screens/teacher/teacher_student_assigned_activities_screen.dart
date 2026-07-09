import 'package:flutter/material.dart';

import '../../models/assigned_activity.dart';
import '../../services/assignment_service.dart';
import '../../theme/app_theme.dart';
import 'teacher_assign_activity_screen.dart';

class TeacherStudentAssignedActivitiesScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentLevel;

  const TeacherStudentAssignedActivitiesScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentLevel,
  });

  @override
  State<TeacherStudentAssignedActivitiesScreen> createState() => _TeacherStudentAssignedActivitiesScreenState();
}

class _TeacherStudentAssignedActivitiesScreenState extends State<TeacherStudentAssignedActivitiesScreen> {
  List<AssignedActivity> assignedActivities = [];
  bool isLoading = true;

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
      assignedActivities = activities.reversed.toList();
      isLoading = false;
    });
  }

  Future<void> _openAssignActivityScreen() async {
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

    if (!mounted) return;

    setState(() { isLoading = true; });
    await _loadAssignedActivities();
  }

  Future<void> _confirmDeleteAssignment(AssignedActivity activity) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove assignment?'),
        content: Text('Remove "${activity.title}" from ${widget.studentName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );

    if (shouldDelete != true) return;

    await AssignmentService.deleteAssignment(activity.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assigned activity removed.')));
    await _loadAssignedActivities();
  }

  Future<void> _confirmMarkAsReviewed(AssignedActivity activity) async {
    final shouldReview = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as reviewed?'),
        content: Text('Mark "${activity.title}" as reviewed for ${widget.studentName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mark as Reviewed')),
        ],
      ),
    );

    if (shouldReview != true) return;

    await AssignmentService.markAssignmentAsReviewed(activity.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment marked as reviewed.')));
    await _loadAssignedActivities();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed': return AppTheme.semanticGreen;
      case 'Reviewed': return AppTheme.semanticGreen;
      case 'Review Needed': return AppTheme.semanticYellow;
      case 'Pending': default: return AppTheme.semanticYellow;
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

    final hasAssignedActivities = assignedActivities.isNotEmpty;

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMuted),
        title: Text('Student Activities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        actions: [
          IconButton(
            tooltip: 'Refresh activities',
            onPressed: _loadAssignedActivities,
            icon: Icon(Icons.refresh, color: textMuted, size: 20),
          ),
        ],
      ),
      floatingActionButton: hasAssignedActivities
          ? FloatingActionButton.extended(
              onPressed: _openAssignActivityScreen,
              backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
              foregroundColor: isDark ? const Color(0xFF161618) : Colors.white,
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('Assign'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadAssignedActivities,
        color: textPrimary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(widget.studentName.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
            const SizedBox(height: 4),
            Text('Activities assigned to this student.', style: TextStyle(fontSize: 12, color: textMuted)),
            const SizedBox(height: 20),
            if (isLoading)
              Center(child: Padding(padding: const EdgeInsets.only(top: 40), child: CircularProgressIndicator(color: textPrimary, strokeWidth: 1.5)))
            else if (!hasAssignedActivities)
              _emptyState(isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border)
            else
              for (final activity in assignedActivities)
                _assignedActivityCard(activity, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
          ],
        ),
      ),
    );
  }

  Widget _assignedActivityCard(
    AssignedActivity activity, {
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final statusColor = _getStatusColor(activity.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                const SizedBox(height: 3),
                Text('${activity.category} · Level ${activity.level}', style: TextStyle(fontSize: 12, color: textMuted)),
                const SizedBox(height: 2),
                Text('Due: ${activity.dueDate}', style: TextStyle(fontSize: 11, color: textMuted)),
                if (activity.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('Note: ${activity.note}', style: TextStyle(fontSize: 11, color: textMuted)),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(activity.status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: statusColor)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _actionIcon(activity, textMuted: textMuted),
        ],
      ),
    );
  }

  Widget _actionIcon(AssignedActivity activity, {required Color textMuted}) {
    if (activity.status == 'Pending') {
      return IconButton(
        tooltip: 'Remove assignment',
        onPressed: () => _confirmDeleteAssignment(activity),
        icon: Icon(Icons.delete_outline, color: textMuted, size: 18),
      );
    }
    if (activity.status == 'Completed' || activity.status == 'Review Needed') {
      final color = activity.status == 'Completed' ? AppTheme.semanticGreen : AppTheme.semanticYellow;
      return IconButton(
        tooltip: 'Mark as reviewed',
        onPressed: () => _confirmMarkAsReviewed(activity),
        icon: Icon(
          activity.status == 'Completed' ? Icons.check_circle_outline : Icons.rate_review_outlined,
          color: color,
          size: 18,
        ),
      );
    }
    if (activity.status == 'Reviewed') {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Icon(Icons.verified_outlined, color: AppTheme.semanticGreen, size: 18),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _emptyState({
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(
        children: [
          Icon(Icons.assignment_outlined, color: textMuted, size: 40),
          const SizedBox(height: 14),
          Text(
            'No activities assigned to ${widget.studentName} yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Assign an activity now without going back to the student profile.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _openAssignActivityScreen,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Assign Activity',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF161618) : Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

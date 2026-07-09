import 'package:flutter/material.dart';

import '../../models/assigned_activity.dart';
import '../../services/assignment_service.dart';
import '../../theme/app_theme.dart';

class TeacherAssignedActivitiesScreen extends StatefulWidget {
  const TeacherAssignedActivitiesScreen({super.key});

  @override
  State<TeacherAssignedActivitiesScreen> createState() => _TeacherAssignedActivitiesScreenState();
}

class _TeacherAssignedActivitiesScreenState extends State<TeacherAssignedActivitiesScreen> {
  List<AssignedActivity> assignedActivities = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssignedActivities();
  }

  Future<void> _loadAssignedActivities() async {
    final activities = await AssignmentService.getAllAssignedActivities();

    if (!mounted) return;

    setState(() {
      assignedActivities = activities.reversed.toList();
      isLoading = false;
    });
  }

  Future<void> _deleteAssignment(String assignmentId) async {
    await AssignmentService.deleteAssignment(assignmentId);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assigned activity removed.')));
    await _loadAssignedActivities();
  }

  void _showAssignInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('To assign an activity, open a student profile first.')),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed': return AppTheme.semanticGreen;
      case 'Review Needed': return AppTheme.semanticYellow;
      case 'Reviewed': return AppTheme.semanticGreen;
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
        title: Text('Assigned Activities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        actions: [
          IconButton(
            tooltip: 'Refresh activities',
            onPressed: _loadAssignedActivities,
            icon: Icon(Icons.refresh, color: textMuted, size: 20),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAssignInfo,
        backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
        foregroundColor: isDark ? const Color(0xFF161618) : Colors.white,
        icon: const Icon(Icons.add_task_outlined),
        label: const Text('Assign'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAssignedActivities,
        color: textPrimary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('ASSIGNED ACTIVITIES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
            const SizedBox(height: 4),
            Text('View activities that have already been assigned to students.', style: TextStyle(fontSize: 12, color: textMuted)),
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
                Text('${activity.assignedToType}: ${activity.assignedToName}', style: TextStyle(fontSize: 12, color: textMuted)),
                const SizedBox(height: 2),
                Text('${activity.category} · Level ${activity.level}', style: TextStyle(fontSize: 11, color: textMuted)),
                const SizedBox(height: 2),
                Text('Due: ${activity.dueDate}', style: TextStyle(fontSize: 11, color: textMuted)),
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
          IconButton(
            tooltip: 'Remove assignment',
            onPressed: () => _deleteAssignment(activity.id),
            icon: Icon(Icons.delete_outline, color: textMuted, size: 18),
          ),
        ],
      ),
    );
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
          Text('No assigned activities yet', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary)),
          const SizedBox(height: 8),
          Text(
            'To assign an activity, go to Students, choose a student and tap Assign Activity.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _showAssignInfo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: isDark ? const Color(0xFF161618) : Colors.white),
                  const SizedBox(width: 8),
                  Text('How to assign', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF161618) : Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

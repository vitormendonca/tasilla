import 'package:flutter/material.dart';

import '../../models/assigned_activity.dart';
import '../../services/assignment_service.dart';
import '../../services/student_progress_service.dart';
import '../../theme/app_theme.dart';

class TeacherAssignActivityScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentLevel;

  const TeacherAssignActivityScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentLevel,
  });

  @override
  State<TeacherAssignActivityScreen> createState() => _TeacherAssignActivityScreenState();
}

class _TeacherAssignActivityScreenState extends State<TeacherAssignActivityScreen> {
  String? selectedActivityId;
  String selectedCategory = 'All';
  bool isSaving = false;
  bool isLoadingStatuses = true;

  final Map<String, String> activityStatuses = {};

  final List<String> categories = const [
    'All', 'Homework', 'Listening', 'Speaking', 'Vocabulary', 'Reading',
  ];

  final List<Map<String, String>> availableActivities = const [
    {
      'id': 'homework_001',
      'title': 'Basic Introductions',
      'type': 'Homework',
      'level': 'A1',
      'description': 'Practice simple introductions in English.',
    },
    {
      'id': 'listening_a1_morning_routine',
      'title': 'Morning Routine',
      'type': 'Listening',
      'level': 'A1',
      'description': 'Listen to a short audio about a daily routine.',
    },
    {
      'id': 'speaking_001',
      'title': 'Personal Introduction Practice',
      'type': 'Speaking',
      'level': 'A1',
      'description': 'Practice a short self-introduction for teacher review.',
    },
    {
      'id': 'vocabulary_a1_greetings',
      'title': 'Greetings and Introductions',
      'type': 'Vocabulary',
      'level': 'A1',
      'description': 'Practice basic greetings and personal introductions.',
    },
    {
      'id': 'homework_002',
      'title': 'Personal Information',
      'type': 'Homework',
      'level': 'A1',
      'description': 'Practice questions about age, city, and job.',
    },
    {
      'id': 'reading_001',
      'title': 'A Busy Morning',
      'type': 'Reading',
      'level': 'A1',
      'description': 'Read a short text about a morning routine.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadActivityStatuses();
  }

  String _progressCategory(String assignmentCategory) {
    switch (assignmentCategory) {
      case 'Listening': return 'listening';
      case 'Speaking': return 'speaking';
      case 'Vocabulary': return 'vocabulary';
      case 'Reading': return 'reading';
      case 'Homework': return 'homework';
      default: return assignmentCategory.toLowerCase();
    }
  }

  Future<void> _loadActivityStatuses() async {
    final Map<String, String> loadedStatuses = {};

    final List<AssignedActivity> assignments =
        await AssignmentService.getAssignedActivitiesForStudent(
          studentId: widget.studentId,
          studentName: widget.studentName,
        );

    for (final activity in availableActivities) {
      final id = activity['id'] ?? '';
      final title = activity['title'] ?? '';
      final type = activity['type'] ?? '';

      String status = 'Not Assigned';

      for (final assignment in assignments) {
        if (assignment.title == title && assignment.category == type && assignment.status != 'Reviewed') {
          status = assignment.status;
          break;
        }
      }

      final bool completedByStudent = await StudentProgressService.isActivityCompleted(
        activityId: id,
        category: _progressCategory(type),
      );

      final score = await StudentProgressService.getActivityScore(
        activityId: id,
        category: _progressCategory(type),
      );

      if (completedByStudent) {
        status = 'Completed';
      } else if (status == 'Not Assigned' && score != null && score < 85) {
        status = 'Review Needed';
      }

      loadedStatuses[id] = status;
    }

    if (!mounted) return;

    setState(() {
      activityStatuses.clear();
      activityStatuses.addAll(loadedStatuses);
      isLoadingStatuses = false;
    });
  }

  List<Map<String, String>> get filteredActivities {
    if (selectedCategory == 'All') return availableActivities;
    return availableActivities.where((a) => a['type'] == selectedCategory).toList();
  }

  bool _canAssignActivity(String activityId) {
    final status = activityStatuses[activityId] ?? 'Not Assigned';
    return status == 'Not Assigned';
  }

  Future<void> _assignActivity() async {
    if (selectedActivityId == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an activity first.')));
      return;
    }

    if (!_canAssignActivity(selectedActivityId!)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This activity already has a status for this student.')));
      return;
    }

    final selectedActivity = availableActivities.firstWhere((a) => a['id'] == selectedActivityId);
    final selectedId = selectedActivity['id'];

    setState(() { isSaving = true; });

    final wasAssigned = await AssignmentService.assignActivityToStudent(
      studentId: widget.studentId,
      studentName: widget.studentName,
      title: selectedActivity['title'] ?? '',
      category: selectedActivity['type'] ?? '',
      level: selectedActivity['level'] ?? '',
      dueDate: 'No due date',
      note: '',
    );

    if (!mounted) return;

    setState(() { isSaving = false; });

    if (!wasAssigned) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedActivity['title']} is already pending for ${widget.studentName}.')),
      );
      await _loadActivityStatuses();
      return;
    }

    setState(() {
      if (selectedId != null) activityStatuses[selectedId] = 'Pending';
      selectedActivityId = null;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${selectedActivity['title']} assigned to ${widget.studentName}.')),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'Listening': return Icons.headphones_outlined;
      case 'Speaking': return Icons.mic_none_outlined;
      case 'Vocabulary': return Icons.style_outlined;
      case 'Homework': return Icons.edit_note_outlined;
      case 'Reading': return Icons.menu_book_outlined;
      default: return Icons.task_alt_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed': return AppTheme.semanticGreen;
      case 'Pending': return AppTheme.semanticYellow;
      case 'Review Needed': return AppTheme.semanticYellow;
      default: return AppTheme.semanticGreen;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Completed': return 'Completed by student';
      case 'Pending': return 'Pending';
      case 'Review Needed': return 'Review Needed';
      default: return 'Available';
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

    final selectedActivity = selectedActivityId == null
        ? null
        : availableActivities.firstWhere((a) => a['id'] == selectedActivityId);
    final activitiesToShow = filteredActivities;

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMuted),
        title: Text('Assign Activities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: canvas,
            border: Border(top: BorderSide(color: border)),
          ),
          child: GestureDetector(
            onTap: isSaving || isLoadingStatuses ? null : _assignActivity,
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isSaving || isLoadingStatuses
                    ? (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC))
                    : (isDark ? Colors.white : const Color(0xFF1A1A1A)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isSaving
                  ? Center(child: CircularProgressIndicator(color: isDark ? const Color(0xFF161618) : Colors.white, strokeWidth: 1.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_task_outlined,
                          size: 18,
                          color: isSaving || isLoadingStatuses
                              ? textMuted
                              : (isDark ? const Color(0xFF161618) : Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isLoadingStatuses
                              ? 'Loading...'
                              : selectedActivity == null
                                  ? 'Select an Activity'
                                  : 'Assign ${selectedActivity['title']}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSaving || isLoadingStatuses
                                ? textMuted
                                : (isDark ? const Color(0xFF161618) : Colors.white),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadActivityStatuses,
        color: textPrimary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('ASSIGN ACTIVITIES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
            const SizedBox(height: 4),
            Text('Choose a category and assign an activity to this student.', style: TextStyle(fontSize: 12, color: textMuted)),
            const SizedBox(height: 20),

            // Student info box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: textPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        widget.studentName.isEmpty ? '?' : widget.studentName[0].toUpperCase(),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.studentName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                        const SizedBox(height: 4),
                        _chip('Level ${widget.studentLevel}', textMuted, border),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh statuses',
                    onPressed: isSaving ? null : _loadActivityStatuses,
                    icon: Icon(Icons.refresh, color: textMuted, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category filter
            Text('CATEGORY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final category = categories[i];
                  final bool isSelected = selectedCategory == category;
                  return GestureDetector(
                    onTap: isSaving ? null : () {
                      setState(() {
                        selectedCategory = category;
                        selectedActivityId = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? textPrimary : surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isSelected ? textPrimary : border),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? (isDark ? const Color(0xFF161618) : Colors.white) : textMuted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Activities list
            Text(
              selectedCategory == 'All' ? 'AVAILABLE ACTIVITIES' : '${selectedCategory.toUpperCase()} ACTIVITIES',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted),
            ),
            const SizedBox(height: 10),

            if (isLoadingStatuses)
              Center(child: Padding(padding: const EdgeInsets.all(24), child: CircularProgressIndicator(color: textPrimary, strokeWidth: 1.5)))
            else if (activitiesToShow.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                child: Text('No $selectedCategory activities available yet.', style: TextStyle(fontSize: 13, color: textMuted)),
              )
            else
              for (final activity in activitiesToShow)
                _activityCard(activity, isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
          ],
        ),
      ),
    );
  }

  Widget _activityCard(
    Map<String, String> activity, {
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final activityId = activity['id'] ?? '';
    final isSelected = selectedActivityId == activityId;
    final activityType = activity['type'] ?? '';
    final status = activityStatuses[activityId] ?? 'Not Assigned';
    final canAssign = _canAssignActivity(activityId);
    final statusColor = canAssign
        ? textPrimary
        : _getStatusColor(status);

    return GestureDetector(
      onTap: isSaving || !canAssign
          ? null
          : () {
              setState(() {
                selectedActivityId = activityId;
              });
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? textPrimary.withValues(alpha: 0.06) : surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? textPrimary.withValues(alpha: 0.3) : border),
        ),
        child: Row(
          children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity['title'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: canAssign ? textPrimary : textMuted)),
                  const SizedBox(height: 3),
                  Text(activity['description'] ?? '', style: TextStyle(fontSize: 11, color: textMuted, height: 1.3)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 4,
                    children: [
                      _chip(activityType, textMuted, border),
                      _chip('Level ${activity['level']}', textMuted, border),
                      _chip(_getStatusLabel(status), statusColor, border),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              !canAssign
                  ? Icons.check_circle_outline
                  : isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
              color: statusColor,
              size: 18,
            ),
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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/homework_data.dart';
import '../../data/listening_data.dart';
import '../../data/reading_data.dart';
import '../../data/speaking_data.dart';
import '../../data/vocabulary_data.dart';
import '../../models/assigned_activity.dart';
import '../../models/homework_activity.dart';
import '../../models/listening_exercise.dart';
import '../../models/reading_activity.dart';
import '../../models/speaking_activity.dart';
import '../../models/vocabulary_quiz.dart';
import '../../services/assignment_service.dart';
import '../../theme/app_theme.dart';
import '../homework/homework_activity_screen.dart';
import '../listening/listening_exercise_screen.dart';
import '../reading/reading_screen.dart';
import '../speaking/speaking_activity_screen.dart';
import '../vocabulary/vocabulary_quiz_screen.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() =>
      _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> {
  String currentStudentName = '';
  String currentStudentLevel = '';

  List<AssignedActivity> studentAssignments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentAssignments();
  }

  Future<void> _loadStudentAssignments() async {
    final prefs = await SharedPreferences.getInstance();

    final savedStudentName = prefs.getString('currentStudentName') ?? '';
    final savedStudentLevel = prefs.getString('currentStudentLevel') ?? '';

    final assignments =
        await AssignmentService.getAssignedActivitiesByStudentName(
          savedStudentName,
        );

    if (!mounted) return;

    setState(() {
      currentStudentName = savedStudentName;
      currentStudentLevel = savedStudentLevel;
      studentAssignments = assignments.reversed.toList();
      isLoading = false;
    });
  }

  ListeningExercise? _findListeningExercise(String title) {
    for (final exercise in listeningExercises) {
      if (exercise.title == title) return exercise;
    }
    return null;
  }

  VocabularyQuiz? _findVocabularyQuiz(String title) {
    for (final quiz in vocabularyQuizzes) {
      if (quiz.title == title) return quiz;
    }
    return null;
  }

  ReadingActivity? _findReadingActivity(String title) {
    for (final activity in readingActivities) {
      if (activity.title == title) return activity;
    }
    return null;
  }

  SpeakingActivity? _findSpeakingActivity(String title) {
    for (final activity in speakingActivities) {
      if (activity.title == title) return activity;
    }
    return null;
  }

  HomeworkActivity? _findHomeworkActivity(String title) {
    for (final activity in homeworkActivities) {
      if (activity.title == title) return activity;
    }
    return null;
  }

  void _showActivityNotFound(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Activity not found. Check if the assigned activity title matches the real activity title.',
        ),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _openAssignedActivity({
    required BuildContext context,
    required AssignedActivity assignment,
  }) async {
    switch (assignment.category) {
      case 'Listening':
        final exercise = _findListeningExercise(assignment.title);
        if (exercise == null) { _showActivityNotFound(context); return; }
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ListeningExerciseScreen(exercise: exercise)));
        await _loadStudentAssignments();
        return;

      case 'Vocabulary':
        final quiz = _findVocabularyQuiz(assignment.title);
        if (quiz == null) { _showActivityNotFound(context); return; }
        await Navigator.push(context, MaterialPageRoute(builder: (_) => VocabularyQuizScreen(quiz: quiz)));
        await _loadStudentAssignments();
        return;

      case 'Reading':
        final readingActivity = _findReadingActivity(assignment.title);
        if (readingActivity == null) { _showActivityNotFound(context); return; }
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ReadingActivityScreen(activity: readingActivity)));
        await _loadStudentAssignments();
        return;

      case 'Speaking':
        final speakingActivity = _findSpeakingActivity(assignment.title);
        if (speakingActivity == null) { _showActivityNotFound(context); return; }
        await Navigator.push(context, MaterialPageRoute(builder: (_) => SpeakingActivityScreen(activity: speakingActivity)));
        await _loadStudentAssignments();
        return;

      case 'Homework':
        final homeworkActivity = _findHomeworkActivity(assignment.title);
        if (homeworkActivity == null) { _showActivityNotFound(context); return; }
        await Navigator.push(context, MaterialPageRoute(builder: (_) => HomeworkActivityScreen(activity: homeworkActivity)));
        await _loadStudentAssignments();
        return;

      default:
        _showActivityNotFound(context);
        return;
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

    final totalAssignments = studentAssignments.length;
    final pendingCount = studentAssignments.where((a) => a.status == 'Pending').length;
    final completedCount = studentAssignments.where((a) => a.status == 'Completed' || a.status == 'Reviewed').length;
    final reviewNeededCount = studentAssignments.where((a) => a.status == 'Review Needed').length;

    final studentLabel = currentStudentName.isEmpty
        ? 'Check the activities your teacher assigned to you.'
        : 'Activities assigned to $currentStudentName.';
    final levelLabel = currentStudentLevel.isEmpty
        ? studentLabel
        : '$studentLabel Level $currentStudentLevel.';

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMuted),
        title: Text(
          'My Assignments',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh assignments',
            onPressed: _loadStudentAssignments,
            icon: Icon(Icons.refresh, color: textMuted, size: 20),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStudentAssignments,
        color: textPrimary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            Text(
              'MY ASSIGNMENTS',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              levelLabel,
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            const SizedBox(height: 20),
            _summaryRow(
              isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
              totalAssignments: totalAssignments, pendingCount: pendingCount,
              completedCount: completedCount, reviewNeededCount: reviewNeededCount,
            ),
            const SizedBox(height: 24),
            Text(
              'ASSIGNED TO YOU',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              'Open teacher recommendations and keep your path moving.',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
            const SizedBox(height: 14),
            if (isLoading)
              Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: CircularProgressIndicator(color: textPrimary, strokeWidth: 1.5),
              ))
            else if (studentAssignments.isEmpty)
              _emptyCard(surface: surface, border: border, textPrimary: textPrimary, textMuted: textMuted)
            else
              for (final activity in studentAssignments)
                _assignmentCard(context: context, activity: activity, isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
            const SizedBox(height: 20),
            _infoCard(surface: surface, border: border, textPrimary: textPrimary, textMuted: textMuted),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow({
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
    required int totalAssignments,
    required int pendingCount,
    required int completedCount,
    required int reviewNeededCount,
  }) {
    return Row(
      children: [
        _statCard(label: 'TOTAL', value: isLoading ? '…' : '$totalAssignments', color: textPrimary, surface: surface, border: border, textMuted: textMuted),
        const SizedBox(width: 8),
        _statCard(label: 'PENDING', value: isLoading ? '…' : '$pendingCount', color: pendingCount > 0 ? AppTheme.semanticYellow : textMuted, surface: surface, border: border, textMuted: textMuted),
        const SizedBox(width: 8),
        _statCard(label: 'DONE', value: isLoading ? '…' : '$completedCount', color: completedCount > 0 ? AppTheme.semanticGreen : textMuted, surface: surface, border: border, textMuted: textMuted),
        const SizedBox(width: 8),
        _statCard(label: 'REVIEW', value: isLoading ? '…' : '$reviewNeededCount', color: reviewNeededCount > 0 ? AppTheme.semanticRed : textMuted, surface: surface, border: border, textMuted: textMuted),
      ],
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

  Widget _assignmentCard({
    required BuildContext context,
    required AssignedActivity activity,
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final statusColor = _statusColor(activity.status);

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
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${activity.category} · ${activity.level}',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
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
                  activity.status.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.event_outlined, color: textMuted, size: 14),
              const SizedBox(width: 6),
              Text('Due: ', style: TextStyle(fontSize: 12, color: textMuted)),
              Text(activity.dueDate, style: TextStyle(fontSize: 12, color: textPrimary)),
            ],
          ),
          if (activity.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(activity.note, style: TextStyle(fontSize: 12, color: textMuted, height: 1.4)),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _openAssignedActivity(context: context, assignment: activity),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _isCompletedStatus(activity.status) ? 'OPEN AGAIN →' : 'OPEN ACTIVITY →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: isDark ? const Color(0xFF161618) : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard({
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text('No assignments yet.', style: TextStyle(color: textMuted, fontSize: 14)),
    );
  }

  Widget _infoCard({
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textMuted,
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
          Text('MVP Note', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Opening an activity does not automatically complete it. The assignment is completed only after the activity returns a real completion confirmation.',
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.45),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
      case 'Reviewed':
        return AppTheme.semanticGreen;
      case 'Review Needed':
        return AppTheme.semanticRed;
      case 'Pending':
      default:
        return AppTheme.semanticYellow;
    }
  }

  bool _isCompletedStatus(String status) {
    return status == 'Completed' || status == 'Reviewed';
  }
}

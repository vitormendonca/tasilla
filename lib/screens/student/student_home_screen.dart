import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/learning_path_data.dart';
import '../../models/assigned_activity.dart';
import '../../models/learning_path_step.dart';
import '../../services/assignment_service.dart';
import '../../services/learning_path_progress_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import 'student_a1_certificate_track_screen.dart';
import 'student_a1_roadmap_screen.dart';
import 'student_assignments_screen.dart';
import 'student_learning_path_screen.dart';
import 'student_profile_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String currentStudentName = '';
  String currentStudentLevel = 'A1';
  int totalPending = 0;
  int totalCompleted = 0;
  int totalReviewNeeded = 0;
  int completedRoadSteps = 0;
  int completedRoadReviews = 0;
  bool roadFinalTestCompleted = false;
  bool isLoadingProgress = true;

  final Map<String, int> completedBySkill = {
    'listening': 0, 'speaking': 0, 'reading': 0, 'vocabulary': 0, 'homework': 0,
  };
  final Map<String, int> reviewBySkill = {
    'listening': 0, 'speaking': 0, 'reading': 0, 'vocabulary': 0, 'homework': 0,
  };
  final Map<String, bool> finalTestBySkill = {
    'listening': false, 'speaking': false, 'reading': false, 'vocabulary': false, 'homework': false,
  };

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStudentName = prefs.getString('currentStudentName') ?? '';
    final savedStudentLevel = prefs.getString('currentStudentLevel') ?? 'A1';

    final List<AssignedActivity> assignments =
        await AssignmentService.getAssignedActivitiesByStudentName(savedStudentName);

    await LearningPathProgressService.syncCompletedAssignmentsToLearningPath(assignments);

    final completedStepIds = await LearningPathProgressService.getCompletedStepIds();
    final pathProgress = LearningPathProgressService.getAllSkillProgressFromCompleted(completedStepIds);
    final roadSteps = getA1RoadmapSteps();
    final roadStepsCompleted = roadSteps.where((s) => completedStepIds.contains(s.id)).length;
    final roadReviewsCompleted = roadSteps
        .where((s) => s.type == LearningPathStepType.review && completedStepIds.contains(s.id))
        .length;

    LearningPathStep? roadFinalStep;
    for (final step in roadSteps) {
      if (step.type == LearningPathStepType.finalTest) { roadFinalStep = step; break; }
    }

    if (!mounted) return;

    final pending = assignments.where((a) => a.status == 'Pending').length;
    final completed = assignments.where((a) => a.status == 'Completed' || a.status == 'Reviewed').length;
    final reviewNeeded = assignments.where((a) => a.status == 'Review Needed').length;

    setState(() {
      currentStudentName = savedStudentName;
      currentStudentLevel = savedStudentLevel;
      totalPending = pending;
      totalCompleted = completed;
      totalReviewNeeded = reviewNeeded;
      completedRoadSteps = roadStepsCompleted;
      completedRoadReviews = roadReviewsCompleted;
      roadFinalTestCompleted = roadFinalStep != null && completedStepIds.contains(roadFinalStep.id);
      for (final skill in completedBySkill.keys) {
        final sp = pathProgress[skill];
        completedBySkill[skill] = sp?.completedLessons ?? 0;
        reviewBySkill[skill] = sp?.completedReviews ?? 0;
        finalTestBySkill[skill] = sp?.finalTestCompleted ?? false;
      }
      isLoadingProgress = false;
    });
  }

  Future<void> refreshProgress() async {
    setState(() => isLoadingProgress = true);
    await loadProgress();
  }

  Future<void> openScreen(BuildContext context, Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
    await refreshProgress();
  }

  String get firstName {
    if (currentStudentName.trim().isEmpty) return 'there';
    return currentStudentName.trim().split(' ').first;
  }

  int get totalRoadSteps => getA1RoadmapSteps().length;

  String get nextSkillId {
    const order = ['listening', 'speaking', 'reading', 'vocabulary', 'homework'];
    for (final s in order) { if ((completedBySkill[s] ?? 0) < 12) return s; }
    return 'listening';
  }

  String get nextSkillTitle {
    switch (nextSkillId) {
      case 'speaking': return 'Speaking';
      case 'reading': return 'Reading';
      case 'vocabulary': return 'Vocabulary';
      case 'homework': return 'Grammar';
      default: return 'Listening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas = isDark ? const Color(0xFF161618) : const Color(0xFFFAFAF8);
    final textPrimary = isDark ? const Color(0xFFF5F5F0) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF48484A) : const Color(0xFFAEAAA2);
    final surface = isDark ? const Color(0xFF242426) : const Color(0xFFF0EEE8);
    final border = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC);

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'TASILLA',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: textMuted,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(ThemeController.iconFor(context), color: textMuted, size: 20),
            onPressed: () => ThemeController.toggle(context),
          ),
          IconButton(
            icon: Icon(Icons.person_outline, color: textMuted, size: 20),
            onPressed: () => openScreen(context, const StudentProfileScreen()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshProgress,
        color: textPrimary,
        child: isLoadingProgress
            ? Center(child: CircularProgressIndicator(color: textPrimary, strokeWidth: 1.5))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  _greetingSection(isDark, textPrimary, textMuted, surface, border),
                  const SizedBox(height: 24),
                  _nextLessonCard(isDark, textPrimary, textMuted, surface, border),
                  const SizedBox(height: 24),
                  _statsRow(isDark, textPrimary, textMuted, surface, border),
                  if (totalPending > 0 || totalReviewNeeded > 0) ...[
                    const SizedBox(height: 24),
                    _teacherSection(isDark, textPrimary, textMuted, surface, border),
                  ],
                  const SizedBox(height: 24),
                  _sectionLabel('A1 ROAD MAP', textMuted),
                  const SizedBox(height: 12),
                  _roadmapCard(isDark, textPrimary, textMuted, surface, border),
                  const SizedBox(height: 10),
                  _certificateCard(isDark, textPrimary, textMuted, surface, border),
                  const SizedBox(height: 24),
                  _sectionLabel('SKILL PATHS', textMuted),
                  const SizedBox(height: 12),
                  _skillsGrid(isDark, textPrimary, textMuted, surface, border),
                ],
              ),
      ),
    );
  }

  Widget _greetingSection(bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GOOD MORNING',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          firstName,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5),
        ),
        const SizedBox(height: 4),
        Text(
          '$currentStudentLevel · $completedRoadSteps of $totalRoadSteps completed',
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
      ],
    );
  }

  Widget _nextLessonCard(bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    return GestureDetector(
      onTap: () => openScreen(context, StudentLearningPathScreen(skillId: nextSkillId)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NEXT LESSON',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              nextSkillTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w400, color: textPrimary, letterSpacing: -0.2),
            ),
            const SizedBox(height: 4),
            Text(
              '${completedBySkill[nextSkillId] ?? 0} of 12 lessons done · A1',
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'START LESSON →',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDark ? const Color(0xFF161618) : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow(bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    return Row(
      children: [
        _statCard(label: 'DONE', value: '$totalCompleted', color: textPrimary, surface: surface, border: Border.all(color: border), textMuted: textMuted),
        const SizedBox(width: 8),
        _statCard(
          label: 'AVG',
          value: totalCompleted > 0 ? '${((completedRoadSteps / totalRoadSteps) * 100).round()}%' : '—',
          color: AppTheme.semanticGreen,
          surface: surface,
          border: totalReviewNeeded > 0 ? Border.all(color: border) : Border.all(color: AppTheme.semanticGreen.withValues(alpha: 0.25)),
          textMuted: textMuted,
        ),
        if (totalPending > 0) ...[
          const SizedBox(width: 8),
          _statCard(
            label: 'PENDING',
            value: '$totalPending',
            color: AppTheme.semanticYellow,
            surface: surface,
            border: Border.all(color: AppTheme.semanticYellow.withValues(alpha: 0.3)),
            textMuted: textMuted,
          ),
        ],
        if (totalReviewNeeded > 0) ...[
          const SizedBox(width: 8),
          _statCard(
            label: 'REVIEW',
            value: '$totalReviewNeeded',
            color: AppTheme.semanticRed,
            surface: surface,
            border: Border.all(color: AppTheme.semanticRed.withValues(alpha: 0.3)),
            textMuted: textMuted,
          ),
        ],
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required Color color,
    required Color surface,
    required Border border,
    required Color textMuted,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10), border: border),
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

  Widget _teacherSection(bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('FROM YOUR TEACHER', textMuted),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => openScreen(context, const StudentAssignmentsScreen()),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: totalReviewNeeded > 0 ? AppTheme.semanticRed : AppTheme.semanticYellow,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        totalReviewNeeded > 0 ? 'Review needed' : 'Assignments waiting',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                      ),
                      Text(
                        totalReviewNeeded > 0
                            ? '$totalReviewNeeded activities to redo'
                            : '$totalPending activities pending',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (totalReviewNeeded > 0 ? AppTheme.semanticRed : AppTheme.semanticYellow).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: (totalReviewNeeded > 0 ? AppTheme.semanticRed : AppTheme.semanticYellow).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    totalReviewNeeded > 0 ? 'REVIEW' : 'PENDING',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: totalReviewNeeded > 0 ? AppTheme.semanticRed : AppTheme.semanticYellow,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _roadmapCard(bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    return GestureDetector(
      onTap: () => openScreen(context, const StudentA1RoadmapScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Full A1 Road Map', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(height: 3),
                  Text('$completedRoadSteps of $totalRoadSteps experiences', style: TextStyle(fontSize: 11, color: textMuted)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: totalRoadSteps > 0 ? completedRoadSteps / totalRoadSteps : 0,
                      minHeight: 2,
                      color: textPrimary,
                      backgroundColor: border,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.arrow_forward_ios_rounded, color: textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _certificateCard(bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    return GestureDetector(
      onTap: () => openScreen(context, const StudentA1CertificateTrackScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('A1 Certificate Track', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(height: 3),
                  Text('Track your certificate progress', style: TextStyle(fontSize: 11, color: textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Icon(Icons.arrow_forward_ios_rounded, color: textMuted, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _skillsGrid(bool isDark, Color textPrimary, Color textMuted, Color surface, Color border) {
    const skills = [
      {'id': 'listening', 'title': 'Listening'},
      {'id': 'speaking', 'title': 'Speaking'},
      {'id': 'reading', 'title': 'Reading'},
      {'id': 'vocabulary', 'title': 'Vocabulary'},
      {'id': 'homework', 'title': 'Grammar'},
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: skills.map((skill) {
        final id = skill['id']!;
        final title = skill['title']!;
        final completed = completedBySkill[id] ?? 0;
        final reviews = reviewBySkill[id] ?? 0;
        final testDone = finalTestBySkill[id] ?? false;
        final progress = (completed / 12).clamp(0.0, 1.0);
        final statusColor = testDone
            ? AppTheme.semanticGreen
            : (reviews > 0 ? textPrimary : textMuted);

        return GestureDetector(
          onTap: () => openScreen(context, StudentLearningPathScreen(skillId: id)),
          child: Container(
            padding: const EdgeInsets.all(14),
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
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
                      ),
                    ),
                    Text(
                      '$completed/12',
                      style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 2,
                    color: progress > 0 ? textPrimary : textMuted,
                    backgroundColor: border,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    testDone ? 'DONE' : '$reviews/4 reviews',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: statusColor),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionLabel(String text, Color textMuted) {
    return Text(
      text,
      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted),
    );
  }
}

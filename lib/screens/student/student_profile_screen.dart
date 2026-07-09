import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/learning_path_data.dart';
import '../../models/assigned_activity.dart';
import '../../models/learning_enums.dart';
import '../../models/learning_path_step.dart';
import '../../services/app_auth_service.dart';
import '../../services/assignment_service.dart';
import '../../services/learning_path_progress_service.dart';
import '../../services/student_progress_service.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import 'student_level_tests_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  String studentName = 'Student';
  String studentLevel = 'A1';

  int listeningCompleted = 0;
  int speakingCompleted = 0;
  int vocabularyCompleted = 0;
  int readingCompleted = 0;
  int homeworkCompleted = 0;

  int listeningPending = 0;
  int speakingPending = 0;
  int vocabularyPending = 0;
  int readingPending = 0;
  int homeworkPending = 0;

  int listeningReviewNeeded = 0;
  int speakingReviewNeeded = 0;
  int vocabularyReviewNeeded = 0;
  int readingReviewNeeded = 0;
  int homeworkReviewNeeded = 0;

  int listeningAverage = 0;
  int speakingAverage = 0;
  int vocabularyAverage = 0;
  int readingAverage = 0;
  int homeworkAverage = 0;

  int roadLessonsCompleted = 0;
  int roadStepsCompleted = 0;
  int roadReviewsCompleted = 0;
  int roadCertificateTasksCompleted = 0;
  bool roadFinalTestCompleted = false;

  bool isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final currentStudentName = prefs.getString('currentStudentName') ?? 'Student';
    final currentStudentLevel = prefs.getString('currentStudentLevel') ?? 'A1';

    final List<AssignedActivity> assignedActivities =
        await AssignmentService.getAssignedActivitiesByStudentName(currentStudentName);

    final averages = await StudentProgressService.getAverageScoresByCategory();
    final completedStepIds = await LearningPathProgressService.getCompletedStepIds();
    final roadSteps = getA1RoadmapSteps();
    final completedRoadSteps = roadSteps.where((step) => completedStepIds.contains(step.id)).length;
    final completedRoadLessons = roadSteps.where((step) => step.activityKind == ActivityKind.coreActivity && completedStepIds.contains(step.id)).length;
    final completedRoadReviews = roadSteps.where((step) => step.type == LearningPathStepType.review && completedStepIds.contains(step.id)).length;
    final completedRoadCertificateTasks = roadSteps.where((step) => _isCertificateRoadTask(step) && completedStepIds.contains(step.id)).length;

    LearningPathStep? roadFinalStep;
    for (final step in roadSteps) {
      if (step.type == LearningPathStepType.finalTest) { roadFinalStep = step; break; }
    }

    int listeningPendingCount = 0, speakingPendingCount = 0, vocabularyPendingCount = 0, readingPendingCount = 0, homeworkPendingCount = 0;
    int listeningCompletedCount = 0, speakingCompletedCount = 0, vocabularyCompletedCount = 0, readingCompletedCount = 0, homeworkCompletedCount = 0;
    int listeningReviewNeededCount = 0, speakingReviewNeededCount = 0, vocabularyReviewNeededCount = 0, readingReviewNeededCount = 0, homeworkReviewNeededCount = 0;

    for (final activity in assignedActivities) {
      final category = activity.category.toLowerCase();
      if (activity.status == 'Pending') {
        if (category == 'listening') listeningPendingCount++;
        else if (category == 'speaking') speakingPendingCount++;
        else if (category == 'vocabulary') vocabularyPendingCount++;
        else if (category == 'reading') readingPendingCount++;
        else if (category == 'homework') homeworkPendingCount++;
      }
      if (activity.status == 'Completed' || activity.status == 'Reviewed') {
        if (category == 'listening') listeningCompletedCount++;
        else if (category == 'speaking') speakingCompletedCount++;
        else if (category == 'vocabulary') vocabularyCompletedCount++;
        else if (category == 'reading') readingCompletedCount++;
        else if (category == 'homework') homeworkCompletedCount++;
      }
      if (activity.status == 'Review Needed') {
        if (category == 'listening') listeningReviewNeededCount++;
        else if (category == 'speaking') speakingReviewNeededCount++;
        else if (category == 'vocabulary') vocabularyReviewNeededCount++;
        else if (category == 'reading') readingReviewNeededCount++;
        else if (category == 'homework') homeworkReviewNeededCount++;
      }
    }

    if (!mounted) return;

    setState(() {
      studentName = currentStudentName;
      studentLevel = currentStudentLevel;

      listeningPending = listeningPendingCount;
      speakingPending = speakingPendingCount;
      vocabularyPending = vocabularyPendingCount;
      readingPending = readingPendingCount;
      homeworkPending = homeworkPendingCount;

      listeningCompleted = listeningCompletedCount;
      speakingCompleted = speakingCompletedCount;
      vocabularyCompleted = vocabularyCompletedCount;
      readingCompleted = readingCompletedCount;
      homeworkCompleted = homeworkCompletedCount;

      listeningReviewNeeded = listeningReviewNeededCount;
      speakingReviewNeeded = speakingReviewNeededCount;
      vocabularyReviewNeeded = vocabularyReviewNeededCount;
      readingReviewNeeded = readingReviewNeededCount;
      homeworkReviewNeeded = homeworkReviewNeededCount;

      listeningAverage = averages['listening'] ?? 0;
      speakingAverage = averages['speaking'] ?? 0;
      vocabularyAverage = averages['vocabulary'] ?? 0;
      readingAverage = averages['reading'] ?? 0;
      homeworkAverage = averages['homework'] ?? 0;

      roadStepsCompleted = completedRoadSteps;
      roadLessonsCompleted = completedRoadLessons;
      roadReviewsCompleted = completedRoadReviews;
      roadCertificateTasksCompleted = completedRoadCertificateTasks;
      roadFinalTestCompleted = roadFinalStep != null && completedStepIds.contains(roadFinalStep.id);

      isLoadingProgress = false;
    });
  }

  Future<void> openPlacementTest() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentLevelTestsScreen()));
    await loadProgress();
  }

  Future<void> logout() async {
    await AppAuthService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
  }

  Future<void> confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to leave this account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
        ],
      ),
    );
    if (shouldLogout == true) await logout();
  }

  bool _isCertificateRoadTask(LearningPathStep step) {
    return step.activityKind == ActivityKind.checkpoint ||
        step.activityKind == ActivityKind.portfolioTask ||
        step.activityKind == ActivityKind.finalExam;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas      = isDark ? const Color(0xFF161618) : const Color(0xFFFAFAF8);
    final textPrimary = isDark ? const Color(0xFFF5F5F0) : const Color(0xFF1A1A1A);
    final textMuted   = isDark ? const Color(0xFF48484A) : const Color(0xFFAEAAA2);
    final surface     = isDark ? const Color(0xFF242426) : const Color(0xFFF0EEE8);
    final border      = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC);

    final totalCompleted = listeningCompleted + speakingCompleted + vocabularyCompleted + readingCompleted + homeworkCompleted;
    final totalPending = listeningPending + speakingPending + vocabularyPending + readingPending + homeworkPending;
    final totalReviewNeeded = listeningReviewNeeded + speakingReviewNeeded + vocabularyReviewNeeded + readingReviewNeeded + homeworkReviewNeeded;

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMuted),
        title: Text('My Profile', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        actions: [
          IconButton(
            tooltip: 'Refresh profile',
            onPressed: loadProgress,
            icon: Icon(Icons.refresh, color: textMuted, size: 20),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadProgress,
        color: textPrimary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _profileHeader(isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
            const SizedBox(height: 20),
            _summaryRow(isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border, totalPending: totalPending, totalCompleted: totalCompleted, totalReviewNeeded: totalReviewNeeded),
            const SizedBox(height: 22),
            _currentLevelPanel(isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
            const SizedBox(height: 22),
            _roadProgressPanel(isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
            const SizedBox(height: 22),
            _progressPanel(isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border, totalPending: totalPending, totalCompleted: totalCompleted, totalReviewNeeded: totalReviewNeeded),
            const SizedBox(height: 22),
            _achievementsPanel(textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
            const SizedBox(height: 22),
            _accountPanel(isDark: isDark, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
          ],
        ),
      ),
    );
  }

  Widget _profileHeader({required bool isDark, required Color textPrimary, required Color textMuted, required Color surface, required Color border}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: textMuted.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(28)),
            child: Icon(Icons.person_outline, color: textMuted, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(studentName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                _levelBadge(textPrimary: textPrimary, textMuted: textMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelBadge({required Color textPrimary, required Color textMuted}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: textMuted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textMuted.withValues(alpha: 0.2)),
      ),
      child: Text(
        'LEVEL ${studentLevel.toUpperCase()}',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: textMuted),
      ),
    );
  }

  Widget _summaryRow({required bool isDark, required Color textPrimary, required Color textMuted, required Color surface, required Color border, required int totalPending, required int totalCompleted, required int totalReviewNeeded}) {
    return Row(
      children: [
        _statCard(label: 'PENDING', value: isLoadingProgress ? '…' : '$totalPending', color: totalPending > 0 ? AppTheme.semanticYellow : textMuted, surface: surface, border: border, textMuted: textMuted),
        const SizedBox(width: 8),
        _statCard(label: 'APPROVED', value: isLoadingProgress ? '…' : '$totalCompleted', color: totalCompleted > 0 ? AppTheme.semanticGreen : textMuted, surface: surface, border: border, textMuted: textMuted),
        const SizedBox(width: 8),
        _statCard(label: 'REVIEW', value: isLoadingProgress ? '…' : '$totalReviewNeeded', color: totalReviewNeeded > 0 ? AppTheme.semanticRed : textMuted, surface: surface, border: border, textMuted: textMuted),
      ],
    );
  }

  Widget _statCard({required String label, required String value, required Color color, required Color surface, required Color border, required Color textMuted}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
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

  Widget _currentLevelPanel({required bool isDark, required Color textPrimary, required Color textMuted, required Color surface, required Color border}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary)),
          const SizedBox(height: 10),
          _levelBadge(textPrimary: textPrimary, textMuted: textMuted),
          const SizedBox(height: 10),
          Text('Your level updates as you complete the road and validate progress.', style: TextStyle(fontSize: 12, color: textMuted, height: 1.4)),
          const SizedBox(height: 14),
          Divider(color: border, height: 1),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: openPlacementTest,
            child: Row(
              children: [
                Icon(Icons.workspace_premium_outlined, color: textMuted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Placement Test', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                      Text('Validate your starting point.', style: TextStyle(fontSize: 11, color: textMuted)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: textMuted, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roadProgressPanel({required bool isDark, required Color textPrimary, required Color textMuted, required Color surface, required Color border}) {
    final roadSteps = getA1RoadmapSteps();
    final totalRoadLessons = roadSteps.where((s) => s.activityKind == ActivityKind.coreActivity).length;
    final totalRoadReviews = roadSteps.where((s) => s.type == LearningPathStepType.review).length;
    final totalCertificateTasks = roadSteps.where(_isCertificateRoadTask).length;
    final totalSteps = roadSteps.length;
    final progress = totalSteps > 0 ? roadStepsCompleted / totalSteps : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A1 Road Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary)),
          const SizedBox(height: 4),
          Text(isLoadingProgress ? 'Loading progress…' : '$roadStepsCompleted/$totalSteps experiences completed', style: TextStyle(fontSize: 12, color: textMuted)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 3,
              color: textPrimary,
              backgroundColor: border,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _badge(label: '$roadLessonsCompleted/$totalRoadLessons core', color: textPrimary, border: border),
              _badge(label: '$roadReviewsCompleted/$totalRoadReviews reviews', color: AppTheme.semanticYellow, border: border),
              _badge(label: '$roadCertificateTasksCompleted/$totalCertificateTasks certificate', color: textPrimary, border: border),
              _badge(label: roadFinalTestCompleted ? 'Final 1/1' : 'Final 0/1', color: roadFinalTestCompleted ? AppTheme.semanticGreen : textMuted, border: border),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge({required String label, required Color color, required Color border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _progressPanel({required bool isDark, required Color textPrimary, required Color textMuted, required Color surface, required Color border, required int totalPending, required int totalCompleted, required int totalReviewNeeded}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$studentLevel Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary)),
          const SizedBox(height: 4),
          Text(
            isLoadingProgress ? 'Loading progress…' : '$totalPending pending · $totalCompleted approved · $totalReviewNeeded review needed',
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 16),
          _progressRow(icon: Icons.headphones_outlined, title: 'Listening', pending: listeningPending, completed: listeningCompleted, reviewNeeded: listeningReviewNeeded, averageScore: listeningAverage, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
          _progressRow(icon: Icons.mic_none_outlined, title: 'Speaking', pending: speakingPending, completed: speakingCompleted, reviewNeeded: speakingReviewNeeded, averageScore: speakingAverage, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
          _progressRow(icon: Icons.style_outlined, title: 'Vocabulary', pending: vocabularyPending, completed: vocabularyCompleted, reviewNeeded: vocabularyReviewNeeded, averageScore: vocabularyAverage, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
          _progressRow(icon: Icons.menu_book_outlined, title: 'Reading', pending: readingPending, completed: readingCompleted, reviewNeeded: readingReviewNeeded, averageScore: readingAverage, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
          _progressRow(icon: Icons.edit_note_outlined, title: 'Grammar', pending: homeworkPending, completed: homeworkCompleted, reviewNeeded: homeworkReviewNeeded, averageScore: homeworkAverage, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border),
        ],
      ),
    );
  }

  Widget _progressRow({
    required IconData icon,
    required String title,
    required int pending,
    required int completed,
    required int reviewNeeded,
    required int averageScore,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final averageColor = averageScore >= 70 ? AppTheme.semanticGreen : averageScore > 0 ? AppTheme.semanticYellow : textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: textMuted.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _badge(label: 'Pending $pending', color: pending > 0 ? AppTheme.semanticYellow : textMuted, border: border),
                    _badge(label: 'Approved $completed', color: completed > 0 ? AppTheme.semanticGreen : textMuted, border: border),
                    _badge(label: 'Review $reviewNeeded', color: reviewNeeded > 0 ? AppTheme.semanticRed : textMuted, border: border),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('$averageScore%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: averageColor)),
        ],
      ),
    );
  }

  Widget _achievementsPanel({required Color textPrimary, required Color textMuted, required Color surface, required Color border}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Achievements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary)),
          const SizedBox(height: 8),
          Text('Badges, level certificates, and skill achievements will appear here in future versions.', style: TextStyle(fontSize: 12, color: textMuted, height: 1.4)),
        ],
      ),
    );
  }

  Widget _accountPanel({required bool isDark, required Color textPrimary, required Color textMuted, required Color surface, required Color border}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary)),
          const SizedBox(height: 8),
          Text('Use this option only when you want to leave this account or switch users.', style: TextStyle(fontSize: 12, color: textMuted, height: 1.4)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: confirmLogout,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: textMuted, size: 16),
                  const SizedBox(width: 8),
                  Text('Logout', style: TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

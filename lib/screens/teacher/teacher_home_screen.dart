import 'package:flutter/material.dart';

import '../../services/organization_service.dart';
import '../../services/teacher_dashboard_service.dart';
import '../../theme/theme_controller.dart';
import 'teacher_assigned_activities_screen.dart';
import 'teacher_classes_screen.dart';
import 'teacher_invitations_screen.dart';
import 'teacher_profile_screen.dart';
import 'teacher_review_screen.dart';
import 'teacher_students_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  List<OrganizationSummary> _organizations = const [];
  String? _organizationId;
  TeacherDashboardStats _stats = TeacherDashboardStats.empty;
  bool _loadingStats = true;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final organizations = await OrganizationService.getOrganizationsForCurrentUser();
      final stats = await TeacherDashboardService.getStats(organizationId: _organizationId);
      if (!mounted) return;
      setState(() {
        _organizations = organizations;
        _stats = stats;
        _loadingStats = false;
        _statsError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingStats = false;
        _statsError = 'Dashboard metrics are temporarily unavailable.';
      });
    }
  }

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
          const SizedBox(height: 20),
          if (_organizations.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: _organizationId ?? '__independent__',
              decoration: const InputDecoration(labelText: 'Teaching context'),
              items: [
                const DropdownMenuItem(value: '__independent__', child: Text('Independent Teacher')),
                for (final organization in _organizations)
                  DropdownMenuItem(value: organization.id, child: Text(organization.name)),
              ],
              onChanged: (value) async {
                setState(() {
                  _organizationId = value == '__independent__' ? null : value;
                  _loadingStats = true;
                  _statsError = null;
                });
                await _loadDashboard();
              },
            ),
            const SizedBox(height: 16),
          ],
          if (_loadingStats)
            const LinearProgressIndicator()
          else if (_statsError != null)
            Row(children: [Expanded(child: Text(_statsError!, style: TextStyle(fontSize: 12, color: textMuted))), TextButton(onPressed: () { setState(() => _loadingStats = true); _loadDashboard(); }, child: const Text('Retry'))])
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _metricCard('Students', _stats.activeStudents, textPrimary, textMuted, surface, border),
                _metricCard('Classes', _stats.classes, textPrimary, textMuted, surface, border),
                _metricCard('Pending reviews', _stats.pendingReviews, textPrimary, textMuted, surface, border),
                _metricCard('Completed steps', _stats.completedSteps, textPrimary, textMuted, surface, border),
              ],
            ),
          const SizedBox(height: 24),
          _actionTile(
            icon: Icons.person_outline,
            title: 'Students',
            subtitle: 'View students, assign activities and check individual progress.',
            onTap: () => _openScreen(context, const TeacherStudentsScreen()),
            textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
          ),
          _actionTile(
            icon: Icons.mail_outline,
            title: 'School invitations',
            subtitle: 'Review and accept invitations to teach for a school.',
            onTap: () => _openScreen(context, const TeacherInvitationsScreen()),
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
            icon: Icons.rate_review_outlined,
            title: 'Review',
            subtitle: 'Listen to speaking and read writing submissions. Approve or request a redo.',
            onTap: () => _openScreen(context, const TeacherReviewScreen()),
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

  Widget _metricCard(String label, int value, Color textPrimary, Color textMuted, Color surface, Color border) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$value', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, color: textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: textMuted)),
      ]),
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

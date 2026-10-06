import 'package:flutter/material.dart';

import '../../services/organization_service.dart';
import '../../services/submission_service.dart';
import '../../theme/app_theme.dart';
import 'teacher_submission_detail_screen.dart';

enum _SkillFilter { all, speaking, writing }

class TeacherReviewScreen extends StatefulWidget {
  const TeacherReviewScreen({super.key});

  @override
  State<TeacherReviewScreen> createState() => _TeacherReviewScreenState();
}

class _TeacherReviewScreenState extends State<TeacherReviewScreen> {
  List<Submission> _submissions = [];
  _SkillFilter _filter = _SkillFilter.all;
  bool _isLoading = true;
  List<OrganizationSummary> _organizations = [];
  String? _organizationId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final organizations = await OrganizationService.getOrganizationsForCurrentUser();
    final submissions = await SubmissionService.getTeacherSubmissions(
      organizationId: _organizationId,
      filterByContext: true,
    );

    if (!mounted) return;
    setState(() {
      _organizations = organizations;
      _submissions = submissions;
      _isLoading = false;
    });
  }

  List<Submission> get _pending =>
      _submissions.where((item) => item.isPending).toList();

  List<Submission> get _visible {
    return _pending.where((item) {
      switch (_filter) {
        case _SkillFilter.all:
          return true;
        case _SkillFilter.speaking:
          return item.skill == 'speaking';
        case _SkillFilter.writing:
          return item.skill == 'writing';
      }
    }).toList();
  }

  Future<void> _openSubmission(Submission submission) async {
    final outcome = await Navigator.push<SubmissionReviewOutcome>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TeacherSubmissionDetailScreen(submission: submission),
      ),
    );

    if (outcome == null || !mounted) return;

    // Reflect the decision locally so the item leaves the pending list at once,
    // then reconcile with the database.
    setState(() {
      _submissions = _submissions.map((item) {
        if (item.id != outcome.submissionId) return item;

        return Submission(
          id: item.id,
          studentId: item.studentId,
          teacherId: item.teacherId,
          organizationId: item.organizationId,
          studentName: item.studentName,
          learningStepId: item.learningStepId,
          stepTitle: item.stepTitle,
          skill: item.skill,
          submissionType: item.submissionType,
          textContent: item.textContent,
          filePath: item.filePath,
          status: outcome.status,
          teacherFeedback: item.teacherFeedback,
          submittedAt: item.submittedAt,
        );
      }).toList();
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          outcome.status == 'approved'
              ? 'Submission approved.'
              : 'Redo requested.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1600),
      ),
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas = isDark ? AppTheme.darkCanvas : AppTheme.lightCanvas;
    final textPrimary = isDark ? AppTheme.textDark : AppTheme.textLight;
    final textMuted = isDark ? AppTheme.mutedDark : AppTheme.mutedLight;
    final surface = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final border = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE4E2DC);

    final visible = _visible;

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMuted),
        title: Text(
          'Review',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _header(
              textPrimary: textPrimary,
              textMuted: textMuted,
              surface: surface,
              border: border,
            ),
            const SizedBox(height: 16),
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
                    _isLoading = true;
                  });
                  await _load();
                },
              ),
              const SizedBox(height: 16),
            ],
            _filterRow(textPrimary: textPrimary, textMuted: textMuted, border: border),
            const SizedBox(height: 16),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: textMuted,
                    ),
                  ),
                ),
              )
            else if (visible.isEmpty)
              _emptyState(
                textPrimary: textPrimary,
                textMuted: textMuted,
                surface: surface,
                border: border,
              )
            else
              for (final submission in visible)
                _submissionTile(
                  submission,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  surface: surface,
                  border: border,
                ),
          ],
        ),
      ),
    );
  }

  Widget _header({
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final pending = _pending.length;
    final approved = _submissions.where((item) => item.isApproved).length;
    final rejected = _submissions.where((item) => item.isRejected).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REVIEW QUEUE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review Queue',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Listen to speaking and read writing submissions from your students. '
            'Approve the work or request a redo with feedback.',
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('$pending pending', textPrimary, border),
              _chip('$approved approved', AppTheme.semanticGreen, border),
              _chip('$rejected needs redo', AppTheme.semanticRed, border),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterRow({
    required Color textPrimary,
    required Color textMuted,
    required Color border,
  }) {
    return Row(
      children: [
        for (final filter in _SkillFilter.values) ...[
          _filterChip(
            filter,
            textPrimary: textPrimary,
            textMuted: textMuted,
            border: border,
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _filterChip(
    _SkillFilter filter, {
    required Color textPrimary,
    required Color textMuted,
    required Color border,
  }) {
    final isSelected = _filter == filter;

    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? textPrimary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? textPrimary.withValues(alpha: 0.3) : border,
          ),
        ),
        child: Text(
          _filterLabel(filter),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? textPrimary : textMuted,
          ),
        ),
      ),
    );
  }

  Widget _submissionTile(
    Submission submission, {
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final skillColor = submission.skill == 'writing'
        ? AppTheme.semanticYellow
        : AppTheme.semanticGreen;

    return GestureDetector(
      onTap: () => _openSubmission(submission),
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
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: skillColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    submission.studentName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    submission.stepTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      _chip(submission.skill, skillColor, border),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          submissionTimeAgo(submission.submittedAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: textMuted,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 28, color: textMuted),
          const SizedBox(height: 12),
          Text(
            'No submissions waiting for review.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Work your students send in will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
          ),
        ],
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
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _filterLabel(_SkillFilter filter) {
    switch (filter) {
      case _SkillFilter.all:
        return 'All';
      case _SkillFilter.speaking:
        return 'Speaking';
      case _SkillFilter.writing:
        return 'Writing';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/a1_learning_experience_data.dart';
import '../../models/learning_experience.dart';
import '../../services/submission_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lesson_audio_player.dart';

/// The result handed back to the queue so it can drop the reviewed item.
class SubmissionReviewOutcome {
  final String submissionId;
  final String status;

  const SubmissionReviewOutcome({
    required this.submissionId,
    required this.status,
  });
}

class TeacherSubmissionDetailScreen extends StatefulWidget {
  final Submission submission;

  const TeacherSubmissionDetailScreen({super.key, required this.submission});

  @override
  State<TeacherSubmissionDetailScreen> createState() =>
      _TeacherSubmissionDetailScreenState();
}

/// Inner padding of the feedback card. The feedback field must span the card's
/// full content width — if it does not, something outside the field is eating
/// the space and the drawn box no longer matches the hit target.
const double _feedbackCardPadding = 18;

class _TeacherSubmissionDetailScreenState
    extends State<TeacherSubmissionDetailScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSaving = false;
  bool _feedbackMissing = false;
  String? _errorMessage;
  String? _signedUrl;
  bool _isLoadingUrl = false;

  Submission get _submission => widget.submission;

  LearningExperience? get _experience =>
      getA1LearningExperienceById(_submission.learningStepId);

  Rubric? get _rubric => _experience?.rubric;

  @override
  void initState() {
    super.initState();
    _feedbackController.text = _submission.teacherFeedback ?? '';

    if (!_submission.isText) {
      _loadSignedUrl();
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadSignedUrl() async {
    final path = _submission.filePath;

    if (path == null || path.trim().isEmpty) {
      return;
    }

    setState(() => _isLoadingUrl = true);
    final url = await SubmissionService.getSignedUrl(path);

    if (!mounted) return;
    setState(() {
      _signedUrl = url;
      _isLoadingUrl = false;
    });
  }

  Future<void> _openFile() async {
    final url = _signedUrl;

    if (url == null) return;

    final uri = Uri.tryParse(url);

    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _review({required bool approve}) async {
    final feedback = _feedbackController.text.trim();

    // Feedback is required for a redo, optional for an approve. A student told
    // "redo this" with no reason has learned nothing.
    if (!approve && feedback.isEmpty) {
      setState(() {
        _feedbackMissing = true;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _feedbackMissing = false;
      _errorMessage = null;
    });

    try {
      if (approve) {
        await SubmissionService.approveSubmission(_submission.id, feedback);
      } else {
        await SubmissionService.rejectSubmission(_submission.id, feedback);
      }
    } on SubmissionReviewException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = error.message;
      });
      return;
    }

    if (!mounted) return;

    Navigator.pop(
      context,
      SubmissionReviewOutcome(
        submissionId: _submission.id,
        status: approve ? 'approved' : 'rejected',
      ),
    );
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

    // Wide screens put the rubric beside the work; narrow screens stack it
    // directly under the work, still above the feedback field.
    final isWide = MediaQuery.of(context).size.width >= 900;

    final work = _workCard(
      isDark: isDark,
      textPrimary: textPrimary,
      textMuted: textMuted,
      surface: surface,
      border: border,
    );
    final rubric = _rubricCard(
      textPrimary: textPrimary,
      textMuted: textMuted,
      surface: surface,
      border: border,
    );

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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header(
            textPrimary: textPrimary,
            textMuted: textMuted,
            surface: surface,
            border: border,
          ),
          const SizedBox(height: 16),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: work),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: rubric),
              ],
            )
          else ...[
            work,
            const SizedBox(height: 16),
            rubric,
          ],
          const SizedBox(height: 16),
          _feedbackCard(
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
            surface: surface,
            border: border,
          ),
        ],
      ),
    );
  }

  Widget _header({
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
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
            'SUBMISSION',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _submission.studentName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _submission.stepTitle,
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(_submission.skill, _skillColor(_submission.skill), border),
              _chip(_submission.submissionType, textMuted, border),
              _chip(
                submissionTimeAgo(_submission.submittedAt),
                textMuted,
                border,
              ),
              _chip(
                _statusLabel(_submission.status),
                _statusColor(_submission.status, textMuted),
                border,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _workCard({
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The work',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _workContent(
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
            border: border,
          ),
        ],
      ),
    );
  }

  Widget _workContent({
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color border,
  }) {
    if (_submission.isText) {
      final text = _submission.textContent?.trim() ?? '';

      return SelectableText(
        text.isEmpty ? 'This submission has no text.' : text,
        style: TextStyle(
          fontSize: 15,
          height: 1.7,
          color: text.isEmpty ? textMuted : textPrimary,
        ),
      );
    }

    if (_isLoadingUrl) {
      return Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          const SizedBox(width: 10),
          Text(
            'Preparing the file…',
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
        ],
      );
    }

    final url = _signedUrl;

    if (url == null) {
      return Text(
        'This file could not be loaded. It may have been removed from storage.',
        style: TextStyle(fontSize: 13, color: AppTheme.semanticRed, height: 1.4),
      );
    }

    if (_submission.isAudio) {
      return LessonAudioPlayer(
        key: ValueKey('submission_audio_${_submission.id}'),
        audioPath: url,
        isRemote: true,
      );
    }

    // submissionType == 'file': image previews inline, everything else opens
    // externally. No inline PDF rendering for the MVP.
    if (_isImagePath(_submission.filePath)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Text(
            'The image could not be displayed.',
            style: TextStyle(fontSize: 13, color: AppTheme.semanticRed),
          ),
        ),
      );
    }

    return Row(
      children: [
        Icon(Icons.description_outlined, size: 18, color: textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _fileName(_submission.filePath),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: textPrimary),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton(onPressed: _openFile, child: const Text('Open')),
      ],
    );
  }

  Widget _rubricCard({
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final criteria = _rubric?.criteria ?? const <RubricCriterion>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rubric',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            criteria.isEmpty
                ? 'This lesson has no rubric attached, so there are no explicit criteria to grade against.'
                : 'Grade the work against each criterion before deciding.',
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          for (final criterion in criteria)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: textMuted.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${criterion.maxScore}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          criterion.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          criterion.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _feedbackCard({
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    return Container(
      key: const ValueKey('submission_feedback_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(_feedbackCardPadding),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feedback',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Required for a redo, optional for an approval.',
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          const SizedBox(height: 12),
          // The border and padding belong to the field's own decoration, not to
          // a wrapper. A wrapper would paint the box while the field's hit
          // target stayed inset by the padding, leaving a dead band inside the
          // visible border where clicks and drag-selection miss the editable.
          TextField(
            key: const ValueKey('submission_feedback_field'),
            controller: _feedbackController,
            maxLines: 4,
            minLines: 3,
            enabled: !_isSaving,
            style: TextStyle(fontSize: 13, color: textPrimary, height: 1.5),
            decoration: InputDecoration(
              hintText: 'What did they do well? What should change?',
              hintStyle: TextStyle(fontSize: 13, color: textMuted),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              // The app-wide inputDecorationTheme sets every border to
              // InputBorder.none, so each state is overridden explicitly here.
              border: _feedbackBorder(border),
              enabledBorder: _feedbackBorder(border),
              focusedBorder: _feedbackBorder(border),
              disabledBorder: _feedbackBorder(border),
            ),
            onChanged: (_) {
              if (_feedbackMissing) {
                setState(() => _feedbackMissing = false);
              }
            },
          ),
          if (_feedbackMissing) ...[
            const SizedBox(height: 8),
            Text(
              'Feedback is required when you ask for a redo.',
              style: TextStyle(fontSize: 12, color: AppTheme.semanticRed),
            ),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.semanticRed,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _primaryButton(
                  key: const ValueKey('submission_approve_button'),
                  label: 'APPROVE',
                  onTap: _isSaving ? null : () => _review(approve: true),
                  background: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  foreground: isDark ? const Color(0xFF161618) : Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _primaryButton(
                  key: const ValueKey('submission_reject_button'),
                  label: 'REQUEST REDO',
                  onTap: _isSaving ? null : () => _review(approve: false),
                  background: AppTheme.semanticRed,
                  foreground: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _feedbackBorder(Color border) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: _feedbackMissing ? AppTheme.semanticRed : border,
      ),
    );
  }

  Widget _primaryButton({
    required Key key,
    required String label,
    required VoidCallback? onTap,
    required Color background,
    required Color foreground,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: onTap == null ? background.withValues(alpha: 0.5) : background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: _isSaving
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: foreground,
                    strokeWidth: 1.5,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: foreground,
                  ),
                ),
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
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  bool _isImagePath(String? path) {
    if (path == null) return false;

    final lower = path.toLowerCase();

    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  String _fileName(String? path) {
    if (path == null || path.trim().isEmpty) {
      return 'Attached file';
    }

    return path.split('/').last;
  }

  Color _skillColor(String skill) {
    return skill == 'writing' ? AppTheme.semanticYellow : AppTheme.semanticGreen;
  }

  Color _statusColor(String status, Color textMuted) {
    switch (status) {
      case 'approved':
        return AppTheme.semanticGreen;
      case 'rejected':
        return AppTheme.semanticRed;
      default:
        return textMuted;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Needs redo';
      default:
        return 'Pending';
    }
  }
}

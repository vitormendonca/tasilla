import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/learning_enums.dart';
import '../../services/certificate_service.dart';
import '../../theme/app_theme.dart';

/// The teacher's final gate. Shows the eligibility checklist — every criterion
/// green or red — and lets the teacher issue the certificate only when all pass.
/// The teacher cannot override a red line; that is what makes the certificate
/// mean something.
class TeacherCertificateSignoffScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String studentLevel;
  final String? organizationId;

  const TeacherCertificateSignoffScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.studentLevel,
    this.organizationId,
  });

  @override
  State<TeacherCertificateSignoffScreen> createState() =>
      _TeacherCertificateSignoffScreenState();
}

class _TeacherCertificateSignoffScreenState
    extends State<TeacherCertificateSignoffScreen> {
  bool _loading = true;
  bool _issuing = false;
  String? _error;

  CertificateEligibility? _eligibility;
  IssuedCertificate? _certificate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final existing =
        await CertificateService.getCertificateForStudent(widget.studentId, organizationId: widget.organizationId);
    final eligibility =
        await CertificateService.getEligibilityForStudent(widget.studentId, organizationId: widget.organizationId);

    if (!mounted) return;

    setState(() {
      _certificate = existing;
      _eligibility = eligibility;
      _loading = false;
    });
  }

  Future<void> _issue() async {
    setState(() {
      _issuing = true;
      _error = null;
    });

    try {
      final certificate = await CertificateService.issueCertificate(
        studentId: widget.studentId,
        studentName: widget.studentName,
        level: widget.studentLevel,
        organizationId: widget.organizationId,
      );

      if (!mounted) return;
      setState(() {
        _certificate = certificate;
        _issuing = false;
      });
    } on CertificateException catch (error) {
      if (!mounted) return;
      setState(() {
        _issuing = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _issuing = false;
        _error = 'Could not issue the certificate. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas = isDark ? const Color(0xFF161618) : const Color(0xFFFAFAF8);
    final textPrimary = isDark ? const Color(0xFFF5F5F0) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF8E8E93) : const Color(0xFF706D67);
    final surface = isDark ? const Color(0xFF242426) : const Color(0xFFF0EEE8);
    final border = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC);

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMuted),
        title: Text(
          'Certificate',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: Icon(Icons.refresh, color: textMuted, size: 20),
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: textPrimary,
                strokeWidth: 1.5,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: _certificate != null
                  ? _issuedBody(
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      surface: surface,
                      border: border,
                    )
                  : _pendingBody(
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                      surface: surface,
                      border: border,
                    ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Not yet issued: the checklist + issue button.
  // ---------------------------------------------------------------------------

  List<Widget> _pendingBody({
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final eligibility = _eligibility;

    if (eligibility == null) {
      return [
        Text(
          'Could not load this student\'s progress.',
          style: TextStyle(fontSize: 13, color: textMuted),
        ),
      ];
    }

    final eligible = eligibility.isEligible;

    return [
      _statusHeader(
        title: widget.studentName,
        subtitle: eligible
            ? 'Every requirement is met. You can issue the ${widget.studentLevel} certificate.'
            : 'Some requirements are not met yet. The certificate cannot issue until every line is green.',
        accent: eligible ? AppTheme.semanticGreen : textMuted,
        textPrimary: textPrimary,
        textMuted: textMuted,
        surface: surface,
        border: border,
      ),
      const SizedBox(height: 22),
      _sectionLabel('SKILL SCORES', textMuted),
      const SizedBox(height: 12),
      _skillRow(eligibility, textPrimary, textMuted, surface, border),
      const SizedBox(height: 22),
      _sectionLabel('REQUIREMENTS', textMuted),
      const SizedBox(height: 12),
      for (final criterion in eligibility.criteria)
        _criterionTile(criterion, textPrimary, textMuted, surface, border),
      const SizedBox(height: 20),
      if (_error != null) ...[
        Text(
          _error!,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.semanticRed,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
      ],
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: (eligible && !_issuing) ? _issue : null,
          icon: _issuing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.workspace_premium_outlined, size: 18),
          label: Text(_issuing ? 'Issuing…' : 'Issue certificate'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      if (!eligible) ...[
        const SizedBox(height: 10),
        Text(
          'This gate cannot be overridden — it is what makes the certificate '
          'trustworthy.',
          style: TextStyle(fontSize: 11, color: textMuted, height: 1.4),
        ),
      ],
    ];
  }

  // ---------------------------------------------------------------------------
  // Already issued: show the certificate + its public code.
  // ---------------------------------------------------------------------------

  List<Widget> _issuedBody({
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final certificate = _certificate!;

    return [
      _statusHeader(
        title: '${widget.studentLevel} Certificate issued',
        subtitle: 'Issued to ${certificate.studentName} on '
            '${_formatDate(certificate.issuedAt)}.',
        accent: AppTheme.semanticGreen,
        textPrimary: textPrimary,
        textMuted: textMuted,
        surface: surface,
        border: border,
      ),
      const SizedBox(height: 22),
      _sectionLabel('VERIFICATION CODE', textMuted),
      const SizedBox(height: 12),
      Container(
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
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    certificate.certificateCode,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy code',
                  onPressed: () => _copy(certificate.certificateCode),
                  icon: Icon(Icons.copy_rounded, size: 18, color: textMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'An employer can verify this certificate with this code — no login '
              'required.',
              style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      _sectionLabel('SKILL SCORES', textMuted),
      const SizedBox(height: 12),
      _skillRowFromCertificate(certificate, textPrimary, textMuted, surface, border),
    ];
  }

  // ---------------------------------------------------------------------------
  // Shared pieces.
  // ---------------------------------------------------------------------------

  Widget _statusHeader({
    required String title,
    required String subtitle,
    required Color accent,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                'A1 CERTIFICATE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, Color textMuted) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
        color: textMuted,
      ),
    );
  }

  Widget _skillRow(
    CertificateEligibility eligibility,
    Color textPrimary,
    Color textMuted,
    Color surface,
    Color border,
  ) {
    return Row(
      children: [
        for (final skill in eligibility.skillScores) ...[
          _skillCard(
            label: _skillLabel(skill.skill),
            score: skill.score,
            met: skill.meetsThreshold,
            textPrimary: textPrimary,
            textMuted: textMuted,
            surface: surface,
            border: border,
          ),
          if (skill.skill != eligibility.skillScores.last.skill)
            const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _skillRowFromCertificate(
    IssuedCertificate certificate,
    Color textPrimary,
    Color textMuted,
    Color surface,
    Color border,
  ) {
    final scores = <String, double>{
      'Listening': certificate.listeningScore,
      'Reading': certificate.readingScore,
      'Speaking': certificate.speakingScore,
      'Writing': certificate.writingScore,
    };

    final entries = scores.entries.toList();

    return Row(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          _skillCard(
            label: entries[i].key,
            score: entries[i].value,
            met: entries[i].value >= CertificateService.skillPassThreshold,
            textPrimary: textPrimary,
            textMuted: textMuted,
            surface: surface,
            border: border,
          ),
          if (i != entries.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _skillCard({
    required String label,
    required double score,
    required bool met,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final color = met ? AppTheme.semanticGreen : AppTheme.semanticRed;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Text(
              '${(score * 100).round()}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.4,
                color: textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _criterionTile(
    EligibilityCriterion criterion,
    Color textPrimary,
    Color textMuted,
    Color surface,
    Color border,
  ) {
    final color = criterion.met ? AppTheme.semanticGreen : AppTheme.semanticRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            criterion.met
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  criterion.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  criterion.detail,
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Certificate code copied'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1400),
      ),
    );
  }

  String _skillLabel(LearningSkill skill) {
    switch (skill) {
      case LearningSkill.listening:
        return 'Listening';
      case LearningSkill.reading:
        return 'Reading';
      case LearningSkill.speaking:
        return 'Speaking';
      case LearningSkill.writing:
        return 'Writing';
      default:
        return skill.label;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

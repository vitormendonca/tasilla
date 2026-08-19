import 'package:flutter/material.dart';

import '../services/certificate_service.dart';

/// Public certificate verification — the employer-facing page behind
/// `#/verify/{certificate_code}`.
///
/// Requires NO login: the `certificates_public_verify` RLS policy lets the
/// anon role read any non-revoked certificate, so this screen works for a
/// signed-out visitor. Revoked certificates are invisible to anon and render
/// as "not found", which is the correct public behaviour.
class VerifyCertificateScreen extends StatefulWidget {
  /// The code from the URL. May be empty — the screen then shows a lookup box.
  final String initialCode;

  /// Injectable for tests. Defaults to the real Supabase lookup.
  final Future<IssuedCertificate?> Function(String code)? lookup;

  const VerifyCertificateScreen({
    super.key,
    this.initialCode = '',
    this.lookup,
  });

  @override
  State<VerifyCertificateScreen> createState() =>
      _VerifyCertificateScreenState();
}

class _VerifyCertificateScreenState extends State<VerifyCertificateScreen> {
  static const List<String> _a1CanDoStatements = [
    'Introduce themselves and recognize basic greetings',
    'Share and understand simple personal information',
    'Talk about family and people using simple language',
    'Describe basic daily routines',
    'Use numbers, time and days in simple contexts',
    'Express likes, dislikes and preferences',
    'Identify places in town and simple directions',
    'Follow classroom instructions and learning language',
    'Handle simple shopping and ordering situations',
    'Talk simply about work and study',
    'Understand and write short messages and notices',
    'Integrate core A1 skills in familiar situations',
  ];

  late final TextEditingController _codeController;
  bool _loading = false;
  bool _searched = false;
  IssuedCertificate? _certificate;

  Future<IssuedCertificate?> Function(String code) get _lookup =>
      widget.lookup ?? CertificateService.getCertificateByCode;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode);

    if (widget.initialCode.trim().isNotEmpty) {
      _runLookup();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _runLookup() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
    });

    final certificate = await _lookup(code);

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
      _searched = true;
      _certificate = certificate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = theme.colorScheme.onSurface;
    final textMuted = textPrimary.withValues(alpha: 0.6);
    final surface = isDark ? const Color(0xFF1E2430) : Colors.white;
    final border = isDark ? const Color(0xFF2E3646) : const Color(0xFFE3E7EE);

    return Scaffold(
      appBar: AppBar(title: const Text('Certificate Verification')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _lookupBox(surface, border, textPrimary, textMuted),
                  const SizedBox(height: 24),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_certificate != null)
                    _certificateCard(
                      _certificate!,
                      surface,
                      border,
                      textPrimary,
                      textMuted,
                    )
                  else if (_searched)
                    _notFoundCard(surface, border, textPrimary, textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lookupBox(
    Color surface,
    Color border,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
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
            'TASILLA CERTIFICATE CHECK',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter a certificate code to confirm it was issued by TASILLA. '
            'No account needed.',
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _runLookup(),
                  decoration: const InputDecoration(
                    hintText: 'TSL-A1-XXXXX',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _loading ? null : _runLookup,
                child: const Text('Verify'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notFoundCard(
    Color surface,
    Color border,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 36, color: Colors.red),
          const SizedBox(height: 10),
          Text(
            'No valid certificate found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This code does not match any active TASILLA certificate. Check '
            'the code for typos. Revoked certificates also fail verification.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _certificateCard(
    IssuedCertificate certificate,
    Color surface,
    Color border,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
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
              const Icon(
                Icons.verified_rounded,
                size: 30,
                color: Color(0xFF2E9E5B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Valid TASILLA certificate',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _detailRow('Certificate', certificate.certificateCode, textPrimary,
              textMuted, selectable: true),
          _detailRow(
            'Holder',
            certificate.studentName.isEmpty
                ? '(name not recorded)'
                : certificate.studentName,
            textPrimary,
            textMuted,
          ),
          _detailRow(
            'Level',
            'CEFR ${certificate.level.toUpperCase()} — English',
            textPrimary,
            textMuted,
          ),
          _detailRow(
            'Issued',
            _formatDate(certificate.issuedAt),
            textPrimary,
            textMuted,
          ),
          _detailRow(
            'Issued by',
            certificate.issuedByName.isEmpty
                ? 'TASILLA teacher'
                : certificate.issuedByName,
            textPrimary,
            textMuted,
          ),
          const SizedBox(height: 18),
          Text(
            'SKILL SCORES — each passed independently (minimum 70%)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 10),
          _scoreRow('Listening', certificate.listeningScore, textPrimary,
              textMuted),
          _scoreRow('Reading', certificate.readingScore, textPrimary,
              textMuted),
          _scoreRow('Speaking', certificate.speakingScore, textPrimary,
              textMuted),
          _scoreRow('Writing', certificate.writingScore, textPrimary,
              textMuted),
          const SizedBox(height: 6),
          Text(
            'Speaking and writing were reviewed and approved by a human '
            'teacher — not auto-graded.',
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 18),
          Text(
            'THE HOLDER CAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 10),
          for (final statement in _a1CanDoStatements)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Color(0xFF2E9E5B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statement,
                      style: TextStyle(
                        fontSize: 13,
                        color: textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    Color textPrimary,
    Color textMuted, {
    bool selectable = false,
  }) {
    final valueStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
          ),
          Expanded(
            child: selectable
                ? SelectableText(value, style: valueStyle)
                : Text(value, style: valueStyle),
          ),
        ],
      ),
    );
  }

  Widget _scoreRow(
    String skill,
    double score,
    Color textPrimary,
    Color textMuted,
  ) {
    final percent = (score * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              skill,
              style: TextStyle(fontSize: 13, color: textMuted),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: score.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: textMuted.withValues(alpha: 0.15),
                color: const Color(0xFF2E9E5B),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              '$percent%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

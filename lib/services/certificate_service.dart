import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/a1_content_loader.dart';
import '../models/learning_enums.dart';
import '../models/learning_experience.dart';
import 'submission_service.dart';
import 'supabase_bootstrap.dart';

/// Thrown when a certificate cannot be issued — the student is not eligible, or
/// the database refused the insert (only a teacher, only for a linked student).
class CertificateException implements Exception {
  final String message;

  const CertificateException(this.message);

  @override
  String toString() => message;
}

/// One skill's computed score and whether it clears the A1 gate on its own.
class SkillScore {
  final LearningSkill skill;
  final double score; // 0.0 – 1.0

  const SkillScore({required this.skill, required this.score});

  bool get meetsThreshold => score >= CertificateService.skillPassThreshold;
}

/// One line on the eligibility checklist the teacher signs off against. Each is
/// green or red, and the certificate cannot issue while any is red.
class EligibilityCriterion {
  final String label;
  final String detail; // e.g. '72% (min 70%)' or '3 of 4 approved'
  final bool met;

  const EligibilityCriterion({
    required this.label,
    required this.detail,
    required this.met,
  });
}

/// The full picture the sign-off screen renders: the four per-skill scores, and
/// the checklist that decides whether a certificate may issue.
class CertificateEligibility {
  final double listeningScore;
  final double readingScore;
  final double speakingScore;
  final double writingScore;
  final List<EligibilityCriterion> criteria;

  const CertificateEligibility({
    required this.listeningScore,
    required this.readingScore,
    required this.speakingScore,
    required this.writingScore,
    required this.criteria,
  });

  /// The teacher cannot override this — it is what makes the certificate mean
  /// something. Every criterion must be met.
  bool get isEligible => criteria.every((criterion) => criterion.met);

  List<SkillScore> get skillScores => [
    SkillScore(skill: LearningSkill.listening, score: listeningScore),
    SkillScore(skill: LearningSkill.reading, score: readingScore),
    SkillScore(skill: LearningSkill.speaking, score: speakingScore),
    SkillScore(skill: LearningSkill.writing, score: writingScore),
  ];
}

/// An issued certificate, as stored and as shown on the public verification page.
class IssuedCertificate {
  final String certificateCode;
  final String studentId;
  final String studentName;
  final String issuedByName;
  final String level;
  final double listeningScore;
  final double readingScore;
  final double speakingScore;
  final double writingScore;
  final DateTime issuedAt;
  final DateTime? revokedAt;

  const IssuedCertificate({
    required this.certificateCode,
    required this.studentId,
    required this.studentName,
    required this.issuedByName,
    required this.level,
    required this.listeningScore,
    required this.readingScore,
    required this.speakingScore,
    required this.writingScore,
    required this.issuedAt,
    required this.revokedAt,
  });

  bool get isRevoked => revokedAt != null;

  factory IssuedCertificate.fromRow(Map<String, dynamic> row) {
    double score(Object? value) =>
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

    return IssuedCertificate(
      certificateCode: row['certificate_code']?.toString() ?? '',
      studentId: row['student_id']?.toString() ?? '',
      studentName: row['student_name']?.toString() ?? 'Student',
      issuedByName: row['issued_by_name']?.toString() ?? 'Teacher',
      level: row['level']?.toString() ?? 'A1',
      listeningScore: score(row['listening_score']),
      readingScore: score(row['reading_score']),
      speakingScore: score(row['speaking_score']),
      writingScore: score(row['writing_score']),
      issuedAt:
          DateTime.tryParse(row['issued_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      revokedAt: DateTime.tryParse(row['revoked_at']?.toString() ?? ''),
    );
  }
}

/// Computes A1 certificate eligibility and issues certificates.
///
/// Scoring, per the certification standard: the four skills are gated
/// independently at 70%, never averaged. Listening and reading are the mean of
/// their lessons' quiz scores; speaking and writing are the teacher's approval
/// rate over the reviewed evidence lessons — because a multiple-choice score can
/// never prove someone speaks or writes English.
class CertificateService {
  static const double skillPassThreshold = 0.70;

  /// The launch course is lessons 001-020. EXP 021-040 are hidden, so nothing in
  /// them can serve as evidence today.
  static const int launchScope = 20;

  static const String _table = 'certificates';

  // ---------------------------------------------------------------------------
  // The evidence sets, read straight from the content.
  // ---------------------------------------------------------------------------

  static int? _coreNumber(LearningExperience experience) {
    // TASILLA content ids: A1-T{nn}-{VOC|LIS|REA|SPE|WRI} -> topic number.
    final tasilla = RegExp(
      r'^A1-T(\d{2})-(VOC|LIS|REA|SPE|WRI)$',
    ).firstMatch(experience.id);
    if (tasilla != null) {
      return int.parse(tasilla.group(1)!);
    }

    // Legacy seed-content scheme, kept so old stored ids stay readable.
    final match = RegExp(r'^A1-EXP-(\d{3})$').firstMatch(experience.id);

    return match == null ? null : int.parse(match.group(1)!);
  }

  /// The 20 core lessons a launch student can actually reach.
  static List<LearningExperience> get launchCoreLessons {
    return getA1LearningExperiences().where((experience) {
      final number = _coreNumber(experience);

      return number != null && number >= 1 && number <= launchScope;
    }).toList();
  }

  /// Lessons whose speaking task is recorded and teacher-reviewed. Speaking is
  /// scored as the approval rate over exactly this set.
  static List<String> get speakingEvidenceStepIds => launchCoreLessons
      .where((e) => e.speakingTask?.requiresTeacherReview ?? false)
      .map((e) => e.id)
      .toList();

  /// Lessons whose writing is submitted and teacher-reviewed.
  static List<String> get writingEvidenceStepIds => launchCoreLessons
      .where((e) => e.writingTask?.requiresTeacherReview ?? false)
      .map((e) => e.id)
      .toList();

  static List<String> _scoredStepIdsForSkill(LearningSkill skill) =>
      launchCoreLessons
          .where((e) => e.primarySkill == skill)
          .map((e) => e.id)
          .toList();

  static double _meanScore(
    Iterable<String> stepIds,
    Map<String, double?> scoresByStepId,
  ) {
    final values = stepIds
        .map((id) => scoresByStepId[id])
        .whereType<double>()
        .toList();

    if (values.isEmpty) {
      return 0;
    }

    return values.reduce((a, b) => a + b) / values.length;
  }

  // ---------------------------------------------------------------------------
  // The pure gate. No network — everything it needs is passed in, so the whole
  // standard is testable without a live database.
  // ---------------------------------------------------------------------------

  static CertificateEligibility evaluate({
    required Map<String, double?> scoresByStepId,
    required Set<String> completedStepIds,
    required List<Submission> submissions,
  }) {
    final listening = _meanScore(
      _scoredStepIdsForSkill(LearningSkill.listening),
      scoresByStepId,
    );
    final reading = _meanScore(
      _scoredStepIdsForSkill(LearningSkill.reading),
      scoresByStepId,
    );

    final approvedSteps = <String>{
      for (final submission in submissions)
        if (submission.isApproved) submission.learningStepId,
    };

    final speakingEvidence = speakingEvidenceStepIds;
    final writingEvidence = writingEvidenceStepIds;
    final approvedSpeaking = speakingEvidence.where(approvedSteps.contains).length;
    final approvedWriting = writingEvidence.where(approvedSteps.contains).length;

    final speaking = speakingEvidence.isEmpty
        ? 0.0
        : approvedSpeaking / speakingEvidence.length;
    final writing = writingEvidence.isEmpty
        ? 0.0
        : approvedWriting / writingEvidence.length;

    final coreIds = launchCoreLessons.map((e) => e.id).toList();
    final completedCore = coreIds.where(completedStepIds.contains).length;

    final criteria = <EligibilityCriterion>[
      EligibilityCriterion(
        label: 'All ${coreIds.length} core lessons completed',
        detail: '$completedCore of ${coreIds.length}',
        met: coreIds.isNotEmpty && completedCore == coreIds.length,
      ),
      _skillCriterion('Listening', listening),
      _skillCriterion('Reading', reading),
      EligibilityCriterion(
        label: 'Speaking approved by teacher',
        detail: '$approvedSpeaking of ${speakingEvidence.length} approved',
        met: speakingEvidence.isNotEmpty &&
            approvedSpeaking == speakingEvidence.length,
      ),
      EligibilityCriterion(
        label: 'Writing approved by teacher',
        detail: '$approvedWriting of ${writingEvidence.length} approved',
        met: writingEvidence.isNotEmpty &&
            approvedWriting == writingEvidence.length,
      ),
    ];

    return CertificateEligibility(
      listeningScore: listening,
      readingScore: reading,
      speakingScore: speaking,
      writingScore: writing,
      criteria: criteria,
    );
  }

  static EligibilityCriterion _skillCriterion(String label, double score) {
    return EligibilityCriterion(
      label: '$label ≥ 70%',
      detail: '${(score * 100).round()}% (min 70%)',
      met: score >= skillPassThreshold,
    );
  }

  // ---------------------------------------------------------------------------
  // IO — fetch a student's evidence, and issue.
  // ---------------------------------------------------------------------------

  /// Reads one student's progress and submissions and runs the gate. Works for
  /// the teacher (RLS scopes rows to their linked students) and for the student
  /// viewing their own readiness.
  static Future<CertificateEligibility> getEligibilityForStudent(
    String studentId, {
    String? organizationId,
  }) async {
    final progress = await _stepProgressForStudent(
      studentId,
      organizationId: organizationId,
    );
    final submissions = await SubmissionService.getSubmissionsForStudent(
      studentId,
      organizationId: organizationId,
    );

    return evaluate(
      scoresByStepId: progress.scores,
      completedStepIds: progress.completed,
      submissions: submissions,
    );
  }

  /// Issues an A1 certificate for a student. Guards eligibility client-side, but
  /// the database is the real gate: the four_skill_minimum check rejects any row
  /// that violates the standard, and RLS rejects a non-teacher.
  static Future<IssuedCertificate> issueCertificate({
    required String studentId,
    required String studentName,
    String level = 'A1',
    String? organizationId,
  }) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null) {
      throw const CertificateException(
        'You must be signed in to issue a certificate.',
      );
    }

    if (organizationId == null || organizationId.isEmpty) {
      throw const CertificateException(
        'An organization is required to issue a certificate.',
      );
    }

    final eligibility = await getEligibilityForStudent(
      studentId,
      organizationId: organizationId,
    );

    if (!eligibility.isEligible) {
      throw const CertificateException(
        'This student has not met every certificate requirement yet.',
      );
    }

    final teacherName = await _teacherName(user.id);
    final code = generateCertificateCode(level);

    try {
      final row = await client
          .from(_table)
          .insert({
            'certificate_code': code,
            'student_id': studentId,
            'student_name': studentName,
            'issued_by': user.id,
            'issued_by_name': teacherName,
            'organization_id': organizationId,
            'level': level,
            'listening_score': _rounded(eligibility.listeningScore),
            'reading_score': _rounded(eligibility.readingScore),
            'speaking_score': _rounded(eligibility.speakingScore),
            'writing_score': _rounded(eligibility.writingScore),
          })
          .select()
          .single();

      return IssuedCertificate.fromRow(Map<String, dynamic>.from(row));
    } catch (error) {
      debugPrint('Certificate issue failed: $error');
      throw CertificateException(_friendlyError(error));
    }
  }

  /// The certificate a student already holds, if any. Newest first.
  static Future<IssuedCertificate?> getCertificateForStudent(
    String studentId, {
    String? organizationId,
  }) async {
    final client = SupabaseBootstrap.client;

    if (client == null || studentId.isEmpty) {
      return null;
    }

    try {
      var query = client.from(_table).select().eq('student_id', studentId);
      if (organizationId != null && organizationId.isNotEmpty) {
        query = query.eq('organization_id', organizationId);
      }
      final row = await query
          .order('issued_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (row == null) {
        return null;
      }

      return IssuedCertificate.fromRow(Map<String, dynamic>.from(row));
    } catch (error) {
      debugPrint('Certificate lookup unavailable: $error');
      return null;
    }
  }

  /// Public verification: look a certificate up by its code. The RLS policy lets
  /// even a signed-out visitor read a non-revoked certificate, so an employer can
  /// confirm it.
  static Future<IssuedCertificate?> getCertificateByCode(String code) async {
    final client = SupabaseBootstrap.client;
    final trimmed = code.trim().toUpperCase();

    if (client == null || trimmed.isEmpty) {
      return null;
    }

    try {
      final row = await client
          .from(_table)
          .select()
          .eq('certificate_code', trimmed)
          .maybeSingle();

      if (row == null) {
        return null;
      }

      return IssuedCertificate.fromRow(Map<String, dynamic>.from(row));
    } catch (error) {
      debugPrint('Certificate verification lookup failed: $error');
      return null;
    }
  }

  /// A public, human-readable, hard-to-guess code: e.g. TSL-A1-7K2M9. Uses an
  /// unambiguous alphabet (no 0/O/1/I) so it survives being read aloud or typed.
  static String generateCertificateCode(String level, {Random? random}) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = random ?? Random.secure();
    final suffix = List.generate(
      5,
      (_) => alphabet[rng.nextInt(alphabet.length)],
    ).join();

    return 'TSL-${level.toUpperCase()}-$suffix';
  }

  static num _rounded(double score) =>
      (score.clamp(0.0, 1.0) * 1000).round() / 1000;

  static Future<_StepProgress> _stepProgressForStudent(
    String studentId, {
    String? organizationId,
  }) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || studentId.isEmpty) {
      return const _StepProgress(scores: {}, completed: {});
    }

    if (organizationId != null && organizationId.isNotEmpty && user != null) {
      final access = await client
          .from('teacher_students')
          .select('id')
          .eq('teacher_id', user.id)
          .eq('student_id', studentId)
          .eq('organization_id', organizationId)
          .eq('status', 'active')
          .limit(1);
      if (_rowsFromResponse(access).isEmpty) {
        return const _StepProgress(scores: {}, completed: {});
      }
    }

    try {
      final data = await client
          .from('student_step_progress')
          .select('learning_step_id,score,status')
          .eq('student_id', studentId);

      final scores = <String, double?>{};
      final completed = <String>{};

      for (final row in _rowsFromResponse(data)) {
        final stepId = row['learning_step_id']?.toString() ?? '';

        if (stepId.isEmpty) {
          continue;
        }

        final rawScore = row['score'];
        if (rawScore is num) {
          scores[stepId] = rawScore.toDouble();
        }

        final status = row['status']?.toString() ?? '';
        if (status == 'completed' ||
            status == 'validated' ||
            status == 'approved') {
          completed.add(stepId);
        }
      }

      return _StepProgress(scores: scores, completed: completed);
    } catch (error) {
      debugPrint('Student step progress unavailable: $error');
      return const _StepProgress(scores: {}, completed: {});
    }
  }

  static Future<String> _teacherName(String teacherId) async {
    final client = SupabaseBootstrap.client;

    if (client == null) {
      return 'Teacher';
    }

    try {
      final row = await client
          .from('profiles')
          .select('full_name')
          .eq('id', teacherId)
          .maybeSingle();

      final name = row?['full_name']?.toString().trim() ?? '';

      return name.isEmpty ? 'Teacher' : name;
    } catch (error) {
      debugPrint('Teacher name unavailable: $error');
      return 'Teacher';
    }
  }

  static String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('four_skill_minimum')) {
      return 'Every skill must reach 70% before a certificate can issue.';
    }

    if (message.contains('row-level security') ||
        message.contains('violates row-level')) {
      return 'Only this student\'s teacher can issue their certificate.';
    }

    if (message.contains('duplicate') || message.contains('unique')) {
      return 'A certificate already exists for this student.';
    }

    return 'Could not issue the certificate. Please try again.';
  }

  static List<Map<String, dynamic>> _rowsFromResponse(Object? response) {
    if (response is! List) {
      return [];
    }

    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }
}

class _StepProgress {
  final Map<String, double?> scores;
  final Set<String> completed;

  const _StepProgress({required this.scores, required this.completed});
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/services/certificate_service.dart';
import 'package:tasilla/services/submission_service.dart';

/// A student's submission for one lesson, at a given review status. Only the
/// fields the gate reads are meaningful here.
Submission _submission(String stepId, String status, {String skill = 'speaking'}) {
  return Submission(
    id: 'sub-$stepId',
    studentId: 'student-1',
    studentName: 'Ana',
    learningStepId: stepId,
    stepTitle: stepId,
    skill: skill,
    submissionType: skill == 'writing' ? 'text' : 'audio',
    textContent: null,
    filePath: null,
    status: status,
    teacherFeedback: null,
    submittedAt: DateTime(2026, 7, 1),
  );
}

/// Everything a launch student needs to pass the gate: all 20 core lessons
/// completed, listening + reading at 100%, and every speaking/writing piece
/// approved. Individual tests knock one piece out to prove the gate bites.
({
  Map<String, double?> scores,
  Set<String> completed,
  List<Submission> submissions,
}) _passingEvidence() {
  final coreIds = CertificateService.launchCoreLessons.map((e) => e.id).toList();

  final scores = <String, double?>{
    for (final lesson in CertificateService.launchCoreLessons) lesson.id: 1.0,
  };

  final submissions = <Submission>[
    for (final id in CertificateService.speakingEvidenceStepIds)
      _submission(id, 'approved', skill: 'speaking'),
    for (final id in CertificateService.writingEvidenceStepIds)
      _submission(id, 'approved', skill: 'writing'),
  ];

  return (scores: scores, completed: coreIds.toSet(), submissions: submissions);
}

void main() {
  group('certificate code', () {
    test('is human-readable and namespaced by level', () {
      final code = CertificateService.generateCertificateCode('A1');

      expect(code, startsWith('TSL-A1-'));
      expect(code.split('-').last.length, 5);
    });

    test('avoids ambiguous characters', () {
      for (var i = 0; i < 200; i++) {
        final suffix = CertificateService.generateCertificateCode('A1').split('-').last;
        expect(suffix, isNot(matches(RegExp(r'[01OI]'))));
      }
    });
  });

  group('eligibility gate', () {
    test('a fully-evidenced student is eligible', () {
      final e = _passingEvidence();

      final result = CertificateService.evaluate(
        scoresByStepId: e.scores,
        completedStepIds: e.completed,
        submissions: e.submissions,
      );

      expect(result.isEligible, isTrue);
      expect(result.speakingScore, 1.0);
      expect(result.writingScore, 1.0);
      expect(result.listeningScore, 1.0);
      expect(result.readingScore, 1.0);
    });

    test('one unapproved speaking piece blocks the certificate', () {
      final e = _passingEvidence();
      final firstSpeaking = CertificateService.speakingEvidenceStepIds.first;

      final submissions = [
        for (final s in e.submissions)
          if (s.learningStepId == firstSpeaking)
            _submission(firstSpeaking, 'submitted', skill: 'speaking')
          else
            s,
      ];

      final result = CertificateService.evaluate(
        scoresByStepId: e.scores,
        completedStepIds: e.completed,
        submissions: submissions,
      );

      expect(result.isEligible, isFalse);
      final speaking = result.criteria
          .firstWhere((c) => c.label.startsWith('Speaking'));
      expect(speaking.met, isFalse);
    });

    test('a listening skill below 70% blocks the certificate', () {
      final e = _passingEvidence();

      // Drop every listening lesson to 0.5 — below the 70% gate.
      final scores = Map<String, double?>.from(e.scores);
      for (final lesson in CertificateService.launchCoreLessons) {
        if (lesson.primarySkill.name == 'listening') {
          scores[lesson.id] = 0.5;
        }
      }

      final result = CertificateService.evaluate(
        scoresByStepId: scores,
        completedStepIds: e.completed,
        submissions: e.submissions,
      );

      expect(result.isEligible, isFalse);
      final listening = result.criteria
          .firstWhere((c) => c.label.startsWith('Listening'));
      expect(listening.met, isFalse);
    });

    test('an incomplete lesson blocks the certificate', () {
      final e = _passingEvidence();
      final fewer = e.completed.toSet()..remove(e.completed.first);

      final result = CertificateService.evaluate(
        scoresByStepId: e.scores,
        completedStepIds: fewer,
        submissions: e.submissions,
      );

      expect(result.isEligible, isFalse);
      final completion = result.criteria
          .firstWhere((c) => c.label.contains('core lessons'));
      expect(completion.met, isFalse);
    });

    test('a rejected writing piece does not count as approved', () {
      final e = _passingEvidence();
      final firstWriting = CertificateService.writingEvidenceStepIds.first;

      final submissions = [
        for (final s in e.submissions)
          if (s.learningStepId == firstWriting)
            _submission(firstWriting, 'rejected', skill: 'writing')
          else
            s,
      ];

      final result = CertificateService.evaluate(
        scoresByStepId: e.scores,
        completedStepIds: e.completed,
        submissions: submissions,
      );

      expect(result.isEligible, isFalse);
      final writing = result.criteria
          .firstWhere((c) => c.label.startsWith('Writing'));
      expect(writing.met, isFalse);
    });

    test('no evidence at all is not eligible (never 0/0 = pass)', () {
      final result = CertificateService.evaluate(
        scoresByStepId: const {},
        completedStepIds: const {},
        submissions: const [],
      );

      expect(result.isEligible, isFalse);
    });
  });
}

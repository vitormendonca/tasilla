import 'package:flutter_test/flutter_test.dart';
import 'package:tasilla/services/submission_service.dart';

void main() {
  group('Submission.stepTitleFor', () {
    test('resolves a lesson title from the A1 content set', () {
      expect(Submission.stepTitleFor('A1-EXP-001'), 'Introducing Yourself');
      expect(Submission.stepTitleFor('A1-EXP-016'), 'My Activities');
    });

    test('falls back to the raw step id when the lesson is unknown', () {
      expect(Submission.stepTitleFor('A1-EXP-999'), 'A1-EXP-999');
    });
  });

  group('Submission.fromRow', () {
    test('maps a database row into a submission', () {
      final submission = Submission.fromRow({
        'id': 'sub-1',
        'student_id': 'student-1',
        'learning_step_id': 'A1-EXP-016',
        'skill': 'writing',
        'submission_type': 'text',
        'text_content': 'Hello. My name is Ana.',
        'file_path': null,
        'status': 'submitted',
        'teacher_feedback': null,
        'submitted_at': '2026-07-12T10:00:00Z',
      }, studentName: 'Ana');

      expect(submission.id, 'sub-1');
      expect(submission.studentName, 'Ana');
      expect(submission.stepTitle, 'My Activities');
      expect(submission.skill, 'writing');
      expect(submission.textContent, 'Hello. My name is Ana.');
      expect(submission.isPending, isTrue);
      expect(submission.isText, isTrue);
      expect(submission.isApproved, isFalse);
    });

    test('reads the approved status and its feedback', () {
      final submission = Submission.fromRow({
        'id': 'sub-2',
        'student_id': 'student-1',
        'learning_step_id': 'A1-EXP-016',
        'skill': 'writing',
        'submission_type': 'text',
        'text_content': 'Hello.',
        'status': 'approved',
        'teacher_feedback': 'Well done.',
        'submitted_at': '2026-07-12T10:00:00Z',
      }, studentName: 'Ana');

      expect(submission.isApproved, isTrue);
      expect(submission.isPending, isFalse);
      expect(submission.teacherFeedback, 'Well done.');
    });

    test('defaults a missing status to submitted', () {
      final submission = Submission.fromRow({
        'id': 'sub-3',
        'student_id': 'student-1',
        'learning_step_id': 'A1-EXP-016',
        'skill': 'speaking',
        'submission_type': 'audio',
        'file_path': 'student-1/A1-EXP-016.m4a',
        'submitted_at': '2026-07-12T10:00:00Z',
      }, studentName: 'Ana');

      expect(submission.status, 'submitted');
      expect(submission.isAudio, isTrue);
      expect(submission.filePath, 'student-1/A1-EXP-016.m4a');
    });
  });

  group('submissionTimeAgo', () {
    final now = DateTime.utc(2026, 7, 12, 12);

    test('reports fresh submissions as just now', () {
      expect(
        submissionTimeAgo(now.subtract(const Duration(seconds: 20)), now: now),
        'just now',
      );
    });

    test('reports minutes, singular and plural', () {
      expect(
        submissionTimeAgo(now.subtract(const Duration(minutes: 1)), now: now),
        '1 minute ago',
      );
      expect(
        submissionTimeAgo(now.subtract(const Duration(minutes: 40)), now: now),
        '40 minutes ago',
      );
    });

    test('reports hours', () {
      expect(
        submissionTimeAgo(now.subtract(const Duration(hours: 2)), now: now),
        '2 hours ago',
      );
    });

    test('reports days', () {
      expect(
        submissionTimeAgo(now.subtract(const Duration(days: 3)), now: now),
        '3 days ago',
      );
    });
  });
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/a1_content_loader.dart';
import 'supabase_bootstrap.dart';

/// Thrown when the database refuses a review action. The `student_submissions`
/// review-authority trigger raises when a non-teacher tries to approve or
/// reject, so this surfaces as a real error rather than a silent no-op.
class SubmissionReviewException implements Exception {
  final String message;

  const SubmissionReviewException(this.message);

  @override
  String toString() => message;
}

class Submission {
  final String id;
  final String studentId;
  final String studentName;
  final String learningStepId;
  final String stepTitle;
  final String skill;
  final String submissionType;
  final String? textContent;
  final String? filePath;
  final String status;
  final String? teacherFeedback;
  final DateTime submittedAt;

  const Submission({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.learningStepId,
    required this.stepTitle,
    required this.skill,
    required this.submissionType,
    required this.textContent,
    required this.filePath,
    required this.status,
    required this.teacherFeedback,
    required this.submittedAt,
  });

  bool get isPending => status == 'submitted';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  bool get isAudio => submissionType == 'audio';
  bool get isText => submissionType == 'text';
  bool get isFile => submissionType == 'file';

  /// Resolves the lesson title from the A1 content set. Falls back to the raw
  /// step id so an unknown id still renders something a teacher can act on.
  static String stepTitleFor(String learningStepId) {
    final experience = getA1LearningExperienceById(learningStepId);
    final title = experience?.title.trim() ?? '';

    return title.isEmpty ? learningStepId : title;
  }

  factory Submission.fromRow(
    Map<String, dynamic> row, {
    required String studentName,
  }) {
    final learningStepId = row['learning_step_id']?.toString() ?? '';

    return Submission(
      id: row['id']?.toString() ?? '',
      studentId: row['student_id']?.toString() ?? '',
      studentName: studentName,
      learningStepId: learningStepId,
      stepTitle: stepTitleFor(learningStepId),
      skill: row['skill']?.toString() ?? '',
      submissionType: row['submission_type']?.toString() ?? '',
      textContent: row['text_content']?.toString(),
      filePath: row['file_path']?.toString(),
      status: row['status']?.toString() ?? 'submitted',
      teacherFeedback: row['teacher_feedback']?.toString(),
      submittedAt:
          DateTime.tryParse(row['submitted_at']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}

class SubmissionService {
  static const String _bucket = 'submissions';
  static const String _columns =
      'id,student_id,learning_step_id,skill,submission_type,'
      'text_content,file_path,status,teacher_feedback,submitted_at';

  /// Every submission the signed-in teacher is allowed to see, newest first.
  ///
  /// Deliberately does NOT filter by teacher: the `student_submissions_read_teacher`
  /// RLS policy already restricts rows to the teacher's actively-linked students.
  /// Filtering again in Dart would duplicate the policy and drift from it.
  static Future<List<Submission>> getTeacherSubmissions({String? status}) async {
    final client = SupabaseBootstrap.client;

    if (client == null || client.auth.currentUser == null) {
      return [];
    }

    try {
      final query = client.from('student_submissions').select(_columns);
      final filtered = status == null ? query : query.eq('status', status);
      final data = await filtered.order('submitted_at', ascending: false);

      return await _withStudentNames(_rowsFromResponse(data));
    } catch (error) {
      debugPrint('Remote submissions unavailable: $error');
      return [];
    }
  }

  /// All `status = 'submitted'` submissions for the teacher's linked students.
  static Future<List<Submission>> getPendingSubmissions() {
    return getTeacherSubmissions(status: 'submitted');
  }

  /// All submissions for one student, any status, newest first.
  static Future<List<Submission>> getSubmissionsForStudent(
    String studentId, {
    String? organizationId,
  }) async {
    final client = SupabaseBootstrap.client;

    final user = client?.auth.currentUser;
    if (client == null || user == null || studentId.isEmpty) {
      return [];
    }

    if (organizationId != null && organizationId.isNotEmpty && user.id != studentId) {
      final access = await client
          .from('teacher_students')
          .select('id')
          .eq('teacher_id', user.id)
          .eq('student_id', studentId)
          .eq('organization_id', organizationId)
          .eq('status', 'active')
          .limit(1);
      if (_rowsFromResponse(access).isEmpty) return [];
    }

    try {
      final data = await client
          .from('student_submissions')
          .select(_columns)
          .eq('student_id', studentId)
          .order('submitted_at', ascending: false);

      return await _withStudentNames(_rowsFromResponse(data));
    } catch (error) {
      debugPrint('Remote student submissions unavailable: $error');
      return [];
    }
  }

  /// The signed-in student's submission for one lesson, if they have made one.
  static Future<Submission?> getSubmissionForStep(String learningStepId) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null || learningStepId.isEmpty) {
      return null;
    }

    try {
      final row = await client
          .from('student_submissions')
          .select(_columns)
          .eq('student_id', user.id)
          .eq('learning_step_id', learningStepId)
          .maybeSingle();

      if (row == null) {
        return null;
      }

      return Submission.fromRow(
        Map<String, dynamic>.from(row),
        studentName: '',
      );
    } catch (error) {
      debugPrint('Remote submission lookup unavailable: $error');
      return null;
    }
  }

  /// Creates or replaces the signed-in student's submission for a lesson.
  ///
  /// The table is uniquely keyed on (student_id, learning_step_id), so a redo
  /// upserts over the previous attempt rather than adding a row — we keep the
  /// latest attempt, not a history. `teacher_feedback` is deliberately absent
  /// from the payload: the review-authority trigger rejects any student write
  /// to that column, and an omitted column keeps its existing value.
  static Future<void> submitOrResubmit({
    required String learningStepId,
    required String skill,
    required String submissionType,
    String? textContent,
    String? filePath,
  }) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null) {
      throw const SubmissionReviewException(
        'You must be signed in to submit work.',
      );
    }

    try {
      await client.from('student_submissions').upsert({
        'student_id': user.id,
        'learning_step_id': learningStepId,
        'skill': skill,
        'submission_type': submissionType,
        'text_content': textContent,
        'file_path': filePath,
        'status': 'submitted',
      }, onConflict: 'student_id,learning_step_id');
    } catch (error) {
      throw SubmissionReviewException(_friendlyError(error));
    }
  }

  /// Uploads a recording or a handwritten page and returns its storage path.
  ///
  /// The path always starts with the student's own id, because that is exactly
  /// what the storage policy checks: a student may only write under
  /// `submissions/{their own uuid}/`. Anything else is rejected by the bucket,
  /// not merely by the UI.
  ///
  /// Upserts, so a redo replaces the previous take rather than piling up files
  /// nobody will ever listen to.
  static Future<String> uploadSubmissionFile({
    required String learningStepId,
    required Uint8List bytes,
    required String fileExtension,
    required String contentType,
  }) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null) {
      throw const SubmissionReviewException(
        'You must be signed in to submit work.',
      );
    }

    if (bytes.isEmpty) {
      throw const SubmissionReviewException(
        'That recording came out empty. Please try again.',
      );
    }

    final path = '${user.id}/$learningStepId.$fileExtension';

    try {
      await client.storage
          .from(_bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      return path;
    } catch (error) {
      debugPrint('Submission upload failed for $path: $error');
      throw const SubmissionReviewException(
        'Could not upload your work. Check your connection and try again.',
      );
    }
  }

  /// Signed URL for audio/file playback. The bucket is private, so a direct
  /// object URL returns 403 — playback must go through a signed URL.
  static Future<String?> getSignedUrl(String filePath) async {
    final client = SupabaseBootstrap.client;

    if (client == null || filePath.trim().isEmpty) {
      return null;
    }

    try {
      return await client.storage
          .from(_bucket)
          .createSignedUrl(filePath, 3600);
    } catch (error) {
      debugPrint('Signed URL unavailable for $filePath: $error');
      return null;
    }
  }

  static Future<void> approveSubmission(String id, String? feedback) {
    return _review(id: id, status: 'approved', feedback: feedback);
  }

  static Future<void> rejectSubmission(String id, String feedback) {
    return _review(id: id, status: 'rejected', feedback: feedback);
  }

  /// Sets the review status. `reviewed_by` / `reviewed_at` are intentionally not
  /// written here — the review-authority trigger stamps them, and anything sent
  /// from the client would be overwritten anyway.
  static Future<void> _review({
    required String id,
    required String status,
    required String? feedback,
  }) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null) {
      throw const SubmissionReviewException(
        'You must be signed in to review submissions.',
      );
    }

    final trimmed = feedback?.trim();

    try {
      await client
          .from('student_submissions')
          .update({
            'status': status,
            'teacher_feedback': (trimmed?.isEmpty ?? true) ? null : trimmed,
          })
          .eq('id', id);
    } catch (error) {
      throw SubmissionReviewException(_friendlyError(error));
    }
  }

  /// Attaches student names by looking profiles up separately. The teacher can
  /// read their linked students' profiles (`profiles_read_linked_students`), so
  /// this stays within RLS without relying on an embedded-resource FK hint.
  static Future<List<Submission>> _withStudentNames(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) {
      return [];
    }

    final namesById = await _studentNames(
      rows
          .map((row) => row['student_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet(),
    );

    return rows.map((row) {
      final studentId = row['student_id']?.toString() ?? '';

      return Submission.fromRow(
        row,
        studentName: namesById[studentId] ?? 'Student',
      );
    }).toList();
  }

  static Future<Map<String, String>> _studentNames(Set<String> studentIds) async {
    final client = SupabaseBootstrap.client;

    if (client == null || studentIds.isEmpty) {
      return {};
    }

    try {
      final data = await client
          .from('profiles')
          .select('id,full_name')
          .inFilter('id', studentIds.toList());

      return {
        for (final row in _rowsFromResponse(data))
          if (row['id'] != null)
            row['id'].toString(): row['full_name']?.toString() ?? 'Student',
      };
    } catch (error) {
      debugPrint('Student names unavailable: $error');
      return {};
    }
  }

  static String _friendlyError(Object error) {
    final message = error.toString();

    // The review-authority trigger raises with its own wording; keep it, since
    // it names the exact rule that was broken.
    if (message.contains('cannot set the review status') ||
        message.contains('cannot write teacher review fields') ||
        message.contains('Only a teacher can approve or reject')) {
      return message.replaceFirst(RegExp(r'^.*?exception:\s*'), '');
    }

    if (message.toLowerCase().contains('row-level security')) {
      return 'You do not have permission to review this submission.';
    }

    return 'Could not save the review. Please try again.';
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

/// Human-readable "2 hours ago" for the review queue.
String submissionTimeAgo(DateTime submittedAt, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(submittedAt);

  if (difference.inSeconds < 60) {
    return 'just now';
  }

  if (difference.inMinutes < 60) {
    final value = difference.inMinutes;
    return '$value ${value == 1 ? 'minute' : 'minutes'} ago';
  }

  if (difference.inHours < 24) {
    final value = difference.inHours;
    return '$value ${value == 1 ? 'hour' : 'hours'} ago';
  }

  final value = difference.inDays;
  return '$value ${value == 1 ? 'day' : 'days'} ago';
}

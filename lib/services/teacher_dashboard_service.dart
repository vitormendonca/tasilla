import 'package:flutter/foundation.dart';

import 'supabase_bootstrap.dart';

class TeacherDashboardStats {
  final int activeStudents;
  final int classes;
  final int pendingReviews;
  final int completedSteps;

  const TeacherDashboardStats({
    required this.activeStudents,
    required this.classes,
    required this.pendingReviews,
    required this.completedSteps,
  });

  static const empty = TeacherDashboardStats(
    activeStudents: 0,
    classes: 0,
    pendingReviews: 0,
    completedSteps: 0,
  );
}

class TeacherDashboardService {
  static Future<TeacherDashboardStats> getStats({String? organizationId}) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return TeacherDashboardStats.empty;

    try {
      var studentsQuery = client
          .from('teacher_students')
          .select('student_id')
          .eq('teacher_id', user.id)
          .eq('status', 'active');
      var classesQuery = client
          .from('classes')
          .select('id')
          .eq('teacher_id', user.id);
      var reviewsQuery = client
          .from('student_submissions')
          .select('id')
          .eq('teacher_id', user.id)
          .eq('status', 'submitted');
      var progressQuery = client
          .from('student_step_progress')
          .select('id')
          .eq('teacher_id', user.id)
          .inFilter('status', const ['completed', 'validated', 'approved']);

      if (organizationId != null && organizationId.isNotEmpty) {
        studentsQuery = studentsQuery.eq('organization_id', organizationId);
        classesQuery = classesQuery.eq('organization_id', organizationId);
        reviewsQuery = reviewsQuery.eq('organization_id', organizationId);
        progressQuery = progressQuery.eq('organization_id', organizationId);
      } else {
        studentsQuery = studentsQuery.isFilter('organization_id', null);
        classesQuery = classesQuery.isFilter('organization_id', null);
        reviewsQuery = reviewsQuery.isFilter('organization_id', null);
        progressQuery = progressQuery.isFilter('organization_id', null);
      }

      final results = await Future.wait([
        studentsQuery,
        classesQuery,
        reviewsQuery,
        progressQuery,
      ]);

      return TeacherDashboardStats(
        activeStudents: _rows(results[0]).length,
        classes: _rows(results[1]).length,
        pendingReviews: _rows(results[2]).length,
        completedSteps: _rows(results[3]).length,
      );
    } catch (error) {
      debugPrint('Teacher dashboard stats unavailable: $error');
      rethrow;
    }
  }

  static List<Map<String, dynamic>> _rows(Object? response) {
    if (response is! List) return const [];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }
}

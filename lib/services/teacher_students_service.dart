import 'package:flutter/foundation.dart';

import '../data/students_data.dart';
import 'supabase_bootstrap.dart';

class TeacherStudentSummary {
  final String id;
  final String name;
  final String level;
  final String accessCode;

  const TeacherStudentSummary({
    required this.id,
    required this.name,
    required this.level,
    required this.accessCode,
  });
}

class TeacherStudentsService {
  static Future<List<TeacherStudentSummary>>
  getStudentsForCurrentTeacher({String? organizationId}) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null) {
      return _demoStudents();
    }

    try {
      var query = client
          .from('teacher_students')
          .select('student_id,status,organization_id')
          .eq('teacher_id', user.id)
          .eq('status', 'active');

      final linksData = organizationId == null || organizationId.isEmpty
          ? await query.isFilter('organization_id', null)
          : await query.eq('organization_id', organizationId);

      final studentIds = _rowsFromResponse(linksData)
          .map((row) => row['student_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (studentIds.isEmpty) {
        return [];
      }

      final profilesData = await client
          .from('profiles')
          .select('id,full_name,current_level,access_code')
          .inFilter('id', studentIds);

      final profilesById = {
        for (final row in _rowsFromResponse(profilesData))
          if (row['id'] != null) row['id'].toString(): row,
      };

      return studentIds
          .map((id) {
            final profile = profilesById[id];

            if (profile == null) {
              return null;
            }

            return TeacherStudentSummary(
              id: id,
              name: profile['full_name']?.toString() ?? 'Student',
              level: profile['current_level']?.toString() ?? 'A1',
              accessCode: profile['access_code']?.toString() ?? '',
            );
          })
          .whereType<TeacherStudentSummary>()
          .toList();
    } catch (error) {
      debugPrint('Remote teacher students unavailable: $error');
      return [];
    }
  }

  static Future<String?> linkStudentByAccessCode({
    required String accessCode,
    String? organizationId,
  }) async {
    final client = SupabaseBootstrap.client;
    if (client == null || client.auth.currentUser == null) {
      return 'Sign in before linking a student.';
    }
    try {
      await client.rpc('link_student_by_access_code', params: {
        'student_access_code': accessCode.trim().toUpperCase(),
        'target_organization_id': organizationId,
      });
      return null;
    } catch (error) {
      final message = error.toString();
      if (message.contains('Student plan limit reached')) return 'Student plan limit reached.';
      if (message.contains('Student not found')) return 'Student code not found.';
      if (message.contains('Student must belong to organization')) return 'This student is not enrolled in the selected school.';
      if (message.contains('Organization teacher must select an organization')) return 'Select the school before linking a student.';
      debugPrint('Student link failed: $error');
      return 'Could not link student.';
    }
  }

  static List<TeacherStudentSummary> _demoStudents() {
    return studentsData.map((student) {
      return TeacherStudentSummary(
        id: student.id,
        name: student.name,
        level: student.level,
        accessCode: student.accessCode,
      );
    }).toList();
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

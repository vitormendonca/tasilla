import 'package:flutter/foundation.dart';

import 'supabase_bootstrap.dart';

class ClassSummary {
  final String id;
  final String organizationId;
  final String teacherId;
  final String name;
  final String level;
  final String status;

  const ClassSummary({
    required this.id,
    required this.organizationId,
    required this.teacherId,
    required this.name,
    required this.level,
    required this.status,
  });

  factory ClassSummary.fromMap(Map<String, dynamic> map) {
    return ClassSummary(
      id: map['id']?.toString() ?? '',
      organizationId: map['organization_id']?.toString() ?? '',
      teacherId: map['teacher_id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      level: map['level']?.toString() ?? 'A1',
      status: map['status']?.toString() ?? 'active',
    );
  }
}

class ClassStudentSummary {
  final String id;
  final String classId;
  final String studentId;
  final String status;

  const ClassStudentSummary({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.status,
  });

  factory ClassStudentSummary.fromMap(Map<String, dynamic> map) {
    return ClassStudentSummary(
      id: map['id']?.toString() ?? '',
      classId: map['class_id']?.toString() ?? '',
      studentId: map['student_id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'active',
    );
  }
}

class ClassService {
  static Future<List<ClassSummary>> listForOrganization(
    String organizationId,
  ) async {
    final client = SupabaseBootstrap.client;
    if (client == null || organizationId.isEmpty) return [];

    try {
      final data = await client
          .from('classes')
          .select('id,organization_id,teacher_id,name,level,status')
          .eq('organization_id', organizationId)
          .order('created_at');

      return _rows(data)
          .map(ClassSummary.fromMap)
          .where((item) => item.id.isNotEmpty)
          .toList();
    } catch (error) {
      debugPrint('Classes unavailable: $error');
      return [];
    }
  }

  static Future<ClassSummary?> create({
    required String organizationId,
    required String name,
    String level = 'A1',
  }) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return null;

    try {
      final data = await client
          .from('classes')
          .insert({
            'organization_id': organizationId,
            'teacher_id': user.id,
            'name': name.trim(),
            'level': level,
          })
          .select('id,organization_id,teacher_id,name,level,status')
          .single();

      return ClassSummary.fromMap(Map<String, dynamic>.from(data));
    } catch (error) {
      debugPrint('Class creation failed: $error');
      return null;
    }
  }

  static Future<List<ClassStudentSummary>> listStudents(
    String classId,
  ) async {
    final client = SupabaseBootstrap.client;
    if (client == null || classId.isEmpty) return [];

    try {
      final data = await client
          .from('class_students')
          .select('id,class_id,student_id,status')
          .eq('class_id', classId)
          .order('joined_at');

      return _rows(data)
          .map(ClassStudentSummary.fromMap)
          .where((item) => item.id.isNotEmpty)
          .toList();
    } catch (error) {
      debugPrint('Class students unavailable: $error');
      return [];
    }
  }

  static Future<bool> enrollStudent({
    required String classId,
    required String studentId,
  }) async {
    final client = SupabaseBootstrap.client;
    if (client == null) return false;

    try {
      await client.from('class_students').insert({
        'class_id': classId,
        'student_id': studentId,
      });
      return true;
    } catch (error) {
      debugPrint('Student enrollment failed: $error');
      return false;
    }
  }

  static List<Map<String, dynamic>> _rows(Object? response) {
    if (response is! List) return [];
    return response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }
}
import 'package:shared_preferences/shared_preferences.dart';

import 'supabase_bootstrap.dart';

class StudentTeachingContext {
  final String teacherId;
  final String teacherName;
  final String? organizationId;
  final String? organizationName;

  const StudentTeachingContext({
    required this.teacherId,
    required this.teacherName,
    this.organizationId,
    this.organizationName,
  });

  String get key => '$teacherId|${organizationId ?? 'independent'}';
  String get label => organizationId == null
      ? '$teacherName — Independent'
      : '$teacherName — ${organizationName ?? 'School'}';
}

class StudentTeachingContextService {
  static const _selectedKey = 'student_teaching_context';

  static Future<List<StudentTeachingContext>> getAvailableContexts() async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return const [];

    final links = _rows(await client
        .from('teacher_students')
        .select('teacher_id,organization_id')
        .eq('student_id', user.id)
        .eq('status', 'active'));
    if (links.isEmpty) return const [];

    final teacherIds = links
        .map((row) => row['teacher_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final organizationIds = links
        .map((row) => row['organization_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final teachers = <String, String>{};
    if (teacherIds.isNotEmpty) {
      for (final row in _rows(await client.from('profiles').select('id,full_name').inFilter('id', teacherIds))) {
        final id = row['id']?.toString();
        if (id != null) teachers[id] = row['full_name']?.toString() ?? 'Teacher';
      }
    }

    final organizations = <String, String>{};
    if (organizationIds.isNotEmpty) {
      for (final row in _rows(await client.from('organizations').select('id,name').inFilter('id', organizationIds))) {
        final id = row['id']?.toString();
        if (id != null) organizations[id] = row['name']?.toString() ?? 'School';
      }
    }

    return links.map((row) {
      final teacherId = row['teacher_id']?.toString() ?? '';
      final organizationId = row['organization_id']?.toString();
      return StudentTeachingContext(
        teacherId: teacherId,
        teacherName: teachers[teacherId] ?? 'Teacher',
        organizationId: organizationId,
        organizationName: organizationId == null ? null : organizations[organizationId],
      );
    }).where((context) => context.teacherId.isNotEmpty).toList();
  }

  static Future<StudentTeachingContext?> getActiveContext() async {
    final contexts = await getAvailableContexts();
    if (contexts.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getString(_selectedKey);
    if (selected != null) {
      for (final context in contexts) {
        if (context.key == selected) return context;
      }
      await prefs.remove(_selectedKey);
    }

    if (contexts.length == 1) {
      await prefs.setString(_selectedKey, contexts.first.key);
      return contexts.first;
    }

    return null;
  }

  static Future<void> selectContext(StudentTeachingContext context) async {
    final contexts = await getAvailableContexts();
    if (!contexts.any((candidate) => candidate.key == context.key)) {
      throw StateError('This teaching context is no longer active.');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedKey, context.key);
  }

  static Future<void> clearSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedKey);
  }

  static List<Map<String, dynamic>> _rows(Object? response) {
    if (response is! List) return const [];
    return response.whereType<Map>().map((row) => Map<String, dynamic>.from(row)).toList();
  }
}

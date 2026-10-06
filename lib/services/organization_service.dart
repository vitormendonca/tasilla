import 'package:flutter/foundation.dart';

import 'supabase_bootstrap.dart';

class OrganizationSummary {
  final String id;
  final String name;
  final String slug;
  final String ownerId;

  const OrganizationSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.ownerId,
  });

  factory OrganizationSummary.fromMap(Map<String, dynamic> map) {
    return OrganizationSummary(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      slug: map['slug']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
    );
  }
}

class OrganizationMemberSummary {
  final String id;
  final String organizationId;
  final String userId;
  final String role;

  const OrganizationMemberSummary({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.role,
  });

  factory OrganizationMemberSummary.fromMap(Map<String, dynamic> map) {
    return OrganizationMemberSummary(
      id: map['id']?.toString() ?? '',
      organizationId: map['organization_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
    );
  }
}


class OrganizationStudentSummary {
  final String membershipId;
  final String userId;
  final String fullName;
  final String level;

  const OrganizationStudentSummary({
    required this.membershipId,
    required this.userId,
    required this.fullName,
    required this.level,
  });

  factory OrganizationStudentSummary.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] is Map
        ? Map<String, dynamic>.from(map['profiles'] as Map)
        : const <String, dynamic>{};
    return OrganizationStudentSummary(
      membershipId: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? profile['id']?.toString() ?? '',
      fullName: profile['full_name']?.toString() ?? 'Aluno',
      level: profile['current_level']?.toString() ?? 'A1',
    );
  }
}

class LegacyTeacherStudentSummary {
  final String id;
  final String studentId;
  final String studentName;
  final String level;
  final String status;
  final String? organizationId;

  const LegacyTeacherStudentSummary({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.level,
    required this.status,
    required this.organizationId,
  });

  factory LegacyTeacherStudentSummary.fromMap(
    Map<String, dynamic> map,
    Map<String, Map<String, dynamic>> profiles,
  ) {
    final studentId = map['student_id']?.toString() ?? '';
    final profile = profiles[studentId] ?? const <String, dynamic>{};
    return LegacyTeacherStudentSummary(
      id: map['id']?.toString() ?? '',
      studentId: studentId,
      studentName: profile['full_name']?.toString() ?? 'Aluno',
      level: profile['current_level']?.toString() ?? 'A1',
      status: map['status']?.toString() ?? 'active',
      organizationId: map['organization_id']?.toString(),
    );
  }
}


class SchoolMemberDisplay {
  final String userId;
  final String role;
  final String fullName;
  final String level;
  const SchoolMemberDisplay({required this.userId, required this.role, required this.fullName, required this.level});
  factory SchoolMemberDisplay.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] is Map ? Map<String, dynamic>.from(map['profiles'] as Map) : const <String, dynamic>{};
    return SchoolMemberDisplay(userId: map['user_id']?.toString() ?? '', role: map['role']?.toString() ?? '', fullName: profile['full_name']?.toString() ?? 'Member', level: profile['current_level']?.toString() ?? 'A1');
  }
}

class SchoolDashboardStats {
  final int activeTeachers;
  final int pendingTeacherInvites;
  final int students;
  final int classes;

  const SchoolDashboardStats({
    required this.activeTeachers,
    required this.pendingTeacherInvites,
    required this.students,
    required this.classes,
  });

  int get teacherSeatsUsed => activeTeachers + pendingTeacherInvites;
}

class TeacherInvitationSummary {
  final String id;
  final String organizationId;
  final String email;

  const TeacherInvitationSummary({required this.id, required this.organizationId, required this.email});

  factory TeacherInvitationSummary.fromMap(Map<String, dynamic> map) => TeacherInvitationSummary(
    id: map['id']?.toString() ?? '',
    organizationId: map['organization_id']?.toString() ?? '',
    email: map['invited_email']?.toString() ?? '',
  );
}

class AccountEntitlement {
  final String planCode;
  final int? maxTeachers;
  final int? maxStudents;
  final String status;

  const AccountEntitlement({
    required this.planCode,
    required this.maxTeachers,
    required this.maxStudents,
    required this.status,
  });

  factory AccountEntitlement.fromMap(Map<String, dynamic> map) {
    return AccountEntitlement(
      planCode: map['plan_code']?.toString() ?? 'pilot',
      maxTeachers: map['max_teachers'] as int?,
      maxStudents: map['max_students'] as int?,
      status: map['status']?.toString() ?? 'active',
    );
  }
}

class OrganizationService {

  static Future<List<SchoolMemberDisplay>> getSchoolMembers(String organizationId) async {
    final client = SupabaseBootstrap.client;
    if (client == null || organizationId.isEmpty) return [];
    try {
      final data = await client.from('organization_members').select('user_id,role,profiles(id,full_name,current_level)').eq('organization_id', organizationId).inFilter('role', ['teacher', 'student']).order('created_at');
      return _rowsFromResponse(data).map(SchoolMemberDisplay.fromMap).where((item) => item.userId.isNotEmpty).toList();
    } catch (error) { debugPrint('School members unavailable: $error'); return []; }
  }

  static Future<List<TeacherInvitationSummary>> getSchoolPendingInvitations(String organizationId) async {
    final client = SupabaseBootstrap.client;
    if (client == null || organizationId.isEmpty) return [];
    try {
      final data = await client.from('teacher_invitations').select('id,organization_id,invited_email').eq('organization_id', organizationId).eq('status', 'pending').order('created_at');
      return _rowsFromResponse(data).map(TeacherInvitationSummary.fromMap).toList();
    } catch (error) { debugPrint('School pending invitations unavailable: $error'); return []; }
  }

  static Future<String?> createSchoolClass({required String organizationId, required String teacherId, required String name, required String level}) async {
    final client = SupabaseBootstrap.client;
    if (client == null) return 'School service unavailable.';
    try {
      await client.rpc('create_school_class', params: {
        'target_organization_id': organizationId,
        'target_teacher_id': teacherId,
        'class_name': name.trim(),
        'class_level': level,
      });
      return null;
    } catch (error) {
      final message = error.toString();
      if (message.contains('Teacher must belong to school')) return 'Select a teacher from this school.';
      if (message.contains('Invalid class name')) return 'Class name must contain at least 2 characters.';
      debugPrint('School class creation failed: $error');
      return 'Could not create class.';
    }
  }

  static Future<SchoolDashboardStats> getSchoolDashboardStats(String organizationId) async {
    final client = SupabaseBootstrap.client;
    if (client == null || organizationId.isEmpty) {
      return const SchoolDashboardStats(activeTeachers: 0, pendingTeacherInvites: 0, students: 0, classes: 0);
    }
    try {
      final members = _rowsFromResponse(await client
          .from('organization_members')
          .select('id,role')
          .eq('organization_id', organizationId));
      final invites = _rowsFromResponse(await client
          .from('teacher_invitations')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('status', 'pending'));
      final classes = _rowsFromResponse(await client
          .from('classes')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('status', 'active'));
      return SchoolDashboardStats(
        activeTeachers: members.where((row) => row['role'] == 'teacher').length,
        pendingTeacherInvites: invites.length,
        students: members.where((row) => row['role'] == 'student').length,
        classes: classes.length,
      );
    } catch (error) {
      debugPrint('School dashboard stats unavailable: $error');
      return const SchoolDashboardStats(activeTeachers: 0, pendingTeacherInvites: 0, students: 0, classes: 0);
    }
  }

  static Future<List<TeacherInvitationSummary>> getMyTeacherInvitations() async {
    final client = SupabaseBootstrap.client;
    if (client == null || client.auth.currentUser == null) return [];
    try {
      final data = await client.from('teacher_invitations').select('id,organization_id,invited_email').eq('status', 'pending').order('created_at');
      return _rowsFromResponse(data).map(TeacherInvitationSummary.fromMap).where((item) => item.id.isNotEmpty).toList();
    } catch (error) {
      debugPrint('Teacher invitations unavailable: $error');
      return [];
    }
  }

  static Future<bool> acceptTeacherInvitation(String invitationId) async {
    final client = SupabaseBootstrap.client;
    if (client == null || client.auth.currentUser == null) return false;
    try {
      await client.rpc('accept_teacher_invitation', params: {'invitation_id': invitationId});
      return true;
    } catch (error) {
      debugPrint('Teacher invitation acceptance failed: $error');
      return false;
    }
  }

  static Future<AccountEntitlement?> ensureEntitlement() async {
    final client = SupabaseBootstrap.client;
    if (client == null || client.auth.currentUser == null) return null;
    try {
      final response = await client.rpc('ensure_default_entitlement');
      final row = _singleRow(response);
      return row == null ? null : AccountEntitlement.fromMap(row);
    } catch (error) {
      debugPrint('Entitlement unavailable: $error');
      return null;
    }
  }

  static Future<bool> inviteTeacher({
    required String organizationId,
    required String email,
  }) async {
    final client = SupabaseBootstrap.client;
    if (client == null || client.auth.currentUser == null) return false;
    try {
      await client.rpc('invite_teacher', params: {
        'target_organization_id': organizationId,
        'teacher_email': email.trim().toLowerCase(),
      });
      return true;
    } catch (error) {
      debugPrint('Teacher invitation failed: $error');
      return false;
    }
  }

  static Future<int> getTeacherUsage(String organizationId) async {
    final client = SupabaseBootstrap.client;
    if (client == null || organizationId.isEmpty) return 0;
    try {
      final members = await client
          .from('organization_members')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('role', 'teacher');
      final invites = await client
          .from('teacher_invitations')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('status', 'pending');
      return _rowsFromResponse(members).length + _rowsFromResponse(invites).length;
    } catch (error) {
      debugPrint('Teacher usage unavailable: $error');
      return 0;
    }
  }

  static Future<List<LegacyTeacherStudentSummary>> getLegacyTeacherStudents() async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return [];

    try {
      final data = await client
          .from('teacher_students')
          .select('id,student_id,status,organization_id')
          .eq('teacher_id', user.id)
          .order('created_at');

      final rows = _rowsFromResponse(data);
      final studentIds = rows
          .map((row) => row['student_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      final profiles = <String, Map<String, dynamic>>{};

      if (studentIds.isNotEmpty) {
        final profileData = await client
            .from('profiles')
            .select('id,full_name,current_level')
            .inFilter('id', studentIds);
        for (final profile in _rowsFromResponse(profileData)) {
          final id = profile['id']?.toString();
          if (id != null && id.isNotEmpty) profiles[id] = profile;
        }
      }

      return rows
          .map((row) => LegacyTeacherStudentSummary.fromMap(row, profiles))
          .where((item) => item.id.isNotEmpty && item.studentId.isNotEmpty)
          .toList();
    } catch (error) {
      debugPrint('Legacy teacher-student relationships unavailable: $error');
      return [];
    }
  }

  static Future<bool> mapLegacyTeacherStudent({
    required String relationshipId,
    required String organizationId,
  }) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null || relationshipId.isEmpty || organizationId.isEmpty) {
      return false;
    }

    try {
      await client.rpc(
        'map_teacher_student_to_organization',
        params: {
          'relationship_id': relationshipId,
          'target_organization_id': organizationId,
        },
      );
      return true;
    } catch (error) {
      debugPrint('Legacy relationship mapping failed: $error');
      return false;
    }
  }

  static Future<List<OrganizationSummary>>
  getOrganizationsForCurrentUser() async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null) {
      return [];
    }

    try {
      final data = await client
          .from('organizations')
          .select('id,name,slug,owner_id')
          .order('created_at');

      return _rowsFromResponse(data)
          .map(OrganizationSummary.fromMap)
          .where((organization) => organization.id.isNotEmpty)
          .toList();
    } catch (error) {
      debugPrint('Remote organizations unavailable: $error');
      return [];
    }
  }

  static Future<OrganizationSummary?> createOrganization({
    required String name,
    required String slug,
  }) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null) {
      return null;
    }

    try {
      final response = await client.rpc(
        'create_organization',
        params: {
          'organization_name': name,
          'organization_slug': slug,
        },
      );

      final row = _singleRow(response);

      if (row == null) {
        return null;
      }

      return OrganizationSummary.fromMap(row);
    } catch (error) {
      debugPrint('Organization creation failed: $error');
      return null;
    }
  }

  static Future<List<OrganizationStudentSummary>> getStudentMembers(
    String organizationId,
  ) async {
    final client = SupabaseBootstrap.client;
    if (client == null || organizationId.isEmpty) return [];

    try {
      final data = await client
          .from('organization_members')
          .select('id,user_id,profiles(id,full_name,current_level)')
          .eq('organization_id', organizationId)
          .eq('role', 'student')
          .order('created_at');

      return _rowsFromResponse(data)
          .map(OrganizationStudentSummary.fromMap)
          .where((student) => student.userId.isNotEmpty)
          .toList();
    } catch (error) {
      debugPrint('Organization students unavailable: $error');
      return [];
    }
  }

  static Future<List<OrganizationMemberSummary>> getMembers(
    String organizationId,
  ) async {
    final client = SupabaseBootstrap.client;

    if (client == null || organizationId.isEmpty) {
      return [];
    }

    try {
      final data = await client
          .from('organization_members')
          .select('id,organization_id,user_id,role')
          .eq('organization_id', organizationId)
          .order('created_at');

      return _rowsFromResponse(data)
          .map(OrganizationMemberSummary.fromMap)
          .where((member) => member.id.isNotEmpty)
          .toList();
    } catch (error) {
      debugPrint('Organization members unavailable: $error');
      return [];
    }
  }

  static Future<bool> addMember({
    required String organizationId,
    required String userId,
    required String role,
  }) async {
    final client = SupabaseBootstrap.client;
    final currentUser = client?.auth.currentUser;

    if (client == null || currentUser == null) {
      return false;
    }

    try {
      await client.from('organization_members').insert({
        'organization_id': organizationId,
        'user_id': userId,
        'role': role,
      });

      return true;
    } catch (error) {
      debugPrint('Organization member creation failed: $error');
      return false;
    }
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

  static Map<String, dynamic>? _singleRow(Object? response) {
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    final rows = _rowsFromResponse(response);
    return rows.isEmpty ? null : rows.first;
  }
}
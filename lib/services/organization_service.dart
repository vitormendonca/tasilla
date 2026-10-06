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

class OrganizationService {
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
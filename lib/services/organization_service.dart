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
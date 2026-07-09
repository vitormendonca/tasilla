import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/assigned_activity.dart';
import 'learning_path_progress_service.dart';
import 'supabase_bootstrap.dart';

class AssignmentService {
  static const String _assignedActivitiesKey = 'assigned_activities';

  static Future<List<AssignedActivity>> getAllAssignedActivities() async {
    final remoteAssignments = await _getRemoteAssignments();

    if (remoteAssignments != null) {
      return remoteAssignments;
    }

    return _getLocalAssignments();
  }

  static Future<List<AssignedActivity>> getAssignedActivitiesForStudent({
    required String studentId,
    required String studentName,
  }) async {
    final remoteAssignments = await _getRemoteAssignments(studentId: studentId);

    if (remoteAssignments != null) {
      return remoteAssignments;
    }

    return getAssignedActivitiesByStudentName(studentName);
  }

  static Future<List<AssignedActivity>> _getLocalAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_assignedActivitiesKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final decodedData = jsonDecode(jsonString);

    if (decodedData is! List) {
      return [];
    }

    return decodedData
        .map(
          (item) => AssignedActivity.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static Future<List<AssignedActivity>?> _getRemoteAssignments({
    String? studentId,
  }) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null) {
      return null;
    }

    try {
      var query = client
          .from('assignments')
          .select(
            'id,title,category,level,target_type,status,note,due_date,student_id,class_id',
          )
          .neq('status', 'canceled');

      if (studentId != null && studentId.isNotEmpty) {
        query = query.eq('student_id', studentId);
      }

      final data = await query.order('assigned_at');
      final rows = _rowsFromResponse(data);
      final profileNames = await _loadProfileNames(
        rows.map((row) => row['student_id']),
      );

      return rows.map((row) {
        return _assignedActivityFromRemote(row, profileNames);
      }).toList();
    } catch (error) {
      debugPrint('Remote assignments unavailable: $error');
      return null;
    }
  }

  static Future<bool> assignActivityToStudent({
    required String studentName,
    required String title,
    required String category,
    required String level,
    String? studentId,
    String dueDate = 'No due date',
    String note = '',
  }) async {
    final remoteResult = await _assignRemoteActivityToStudent(
      studentId: studentId,
      studentName: studentName,
      title: title,
      category: category,
      level: level,
      dueDate: dueDate,
      note: note,
    );

    if (remoteResult != null) {
      return remoteResult;
    }

    final currentAssignments = await _getLocalAssignments();

    final alreadyAssigned = currentAssignments.any(
      (assignment) =>
          assignment.assignedToType == 'Student' &&
          assignment.assignedToName == studentName &&
          assignment.title == title &&
          assignment.category == category &&
          assignment.status != 'Reviewed',
    );

    if (alreadyAssigned) {
      return false;
    }

    final newAssignment = AssignedActivity(
      id: 'assignment_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      level: level,
      assignedToName: studentName,
      assignedToType: 'Student',
      dueDate: dueDate,
      status: 'Pending',
      note: note,
    );

    currentAssignments.add(newAssignment);

    await _saveAssignments(currentAssignments);

    return true;
  }

  static Future<bool> assignActivityToClass({
    required String className,
    required String title,
    required String category,
    required String level,
    String dueDate = 'No due date',
    String note = '',
  }) async {
    final currentAssignments = await _getLocalAssignments();

    final alreadyAssigned = currentAssignments.any(
      (assignment) =>
          assignment.assignedToType == 'Class' &&
          assignment.assignedToName == className &&
          assignment.title == title &&
          assignment.category == category &&
          assignment.status != 'Reviewed',
    );

    if (alreadyAssigned) {
      return false;
    }

    final newAssignment = AssignedActivity(
      id: 'assignment_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      level: level,
      assignedToName: className,
      assignedToType: 'Class',
      dueDate: dueDate,
      status: 'Pending',
      note: note,
    );

    currentAssignments.add(newAssignment);

    await _saveAssignments(currentAssignments);

    return true;
  }

  static Future<List<AssignedActivity>> getAssignedActivitiesByStudentName(
    String studentName,
  ) async {
    final currentStudentId = await _currentRemoteStudentId();

    if (currentStudentId != null) {
      final remoteAssignments = await _getRemoteAssignments(
        studentId: currentStudentId,
      );

      if (remoteAssignments != null) {
        return remoteAssignments;
      }
    }

    final remoteAssignments = await _getRemoteAssignments();

    if (remoteAssignments != null) {
      return remoteAssignments
          .where((assignment) => assignment.assignedToName == studentName)
          .toList();
    }

    final allAssignments = await getAllAssignedActivities();

    return allAssignments
        .where(
          (assignment) =>
              assignment.assignedToType == 'Student' &&
              assignment.assignedToName == studentName,
        )
        .toList();
  }

  static Future<List<AssignedActivity>>
  getActiveAssignedActivitiesByStudentName(String studentName) async {
    final allAssignments = await getAllAssignedActivities();

    return allAssignments
        .where(
          (assignment) =>
              assignment.assignedToType == 'Student' &&
              assignment.assignedToName == studentName &&
              assignment.status != 'Reviewed',
        )
        .toList();
  }

  static Future<List<AssignedActivity>>
  getReviewedAssignedActivitiesByStudentName(String studentName) async {
    final allAssignments = await getAllAssignedActivities();

    return allAssignments
        .where(
          (assignment) =>
              assignment.assignedToType == 'Student' &&
              assignment.assignedToName == studentName &&
              assignment.status == 'Reviewed',
        )
        .toList();
  }

  static Future<List<AssignedActivity>> getAssignedActivitiesByClassName(
    String className,
  ) async {
    final allAssignments = await getAllAssignedActivities();

    return allAssignments
        .where(
          (assignment) =>
              assignment.assignedToType == 'Class' &&
              assignment.assignedToName == className,
        )
        .toList();
  }

  static Future<AssignedActivity?> getStudentAssignmentByTitleAndCategory({
    required String studentName,
    required String title,
    required String category,
  }) async {
    final assignments = await getAssignedActivitiesByStudentName(studentName);

    for (final assignment in assignments) {
      if (assignment.title == title &&
          assignment.category == category &&
          assignment.status != 'Reviewed') {
        return assignment;
      }
    }

    return null;
  }

  static Future<void> updateAssignmentStatus({
    required String assignmentId,
    required String newStatus,
  }) async {
    final wasUpdatedRemotely = await _updateRemoteAssignmentStatus(
      assignmentId: assignmentId,
      newStatus: newStatus,
    );

    if (wasUpdatedRemotely) {
      return;
    }

    final currentAssignments = await _getLocalAssignments();

    final updatedAssignments = currentAssignments.map((assignment) {
      if (assignment.id == assignmentId) {
        return AssignedActivity(
          id: assignment.id,
          title: assignment.title,
          category: assignment.category,
          level: assignment.level,
          assignedToName: assignment.assignedToName,
          assignedToType: assignment.assignedToType,
          dueDate: assignment.dueDate,
          status: newStatus,
          note: assignment.note,
        );
      }

      return assignment;
    }).toList();

    await _saveAssignments(updatedAssignments);
  }

  static Future<void> markAssignmentAsReviewed(String assignmentId) async {
    await updateAssignmentStatus(
      assignmentId: assignmentId,
      newStatus: 'Reviewed',
    );
  }

  static Future<bool> markStudentAssignmentAsCompleted({
    required String studentName,
    required String title,
    required String category,
  }) async {
    final wasUpdated = await _updateStudentAssignmentStatus(
      studentName: studentName,
      title: title,
      category: category,
      newStatus: 'Completed',
    );

    if (wasUpdated) {
      await LearningPathProgressService.markNextLessonCompletedForCategory(
        category,
      );
    }

    return wasUpdated;
  }

  static Future<bool> markStudentAssignmentAsReviewNeeded({
    required String studentName,
    required String title,
    required String category,
  }) async {
    return _updateStudentAssignmentStatus(
      studentName: studentName,
      title: title,
      category: category,
      newStatus: 'Review Needed',
    );
  }

  static Future<bool> _updateStudentAssignmentStatus({
    required String studentName,
    required String title,
    required String category,
    required String newStatus,
  }) async {
    final remoteResult = await _updateRemoteStudentAssignmentStatus(
      studentName: studentName,
      title: title,
      category: category,
      newStatus: newStatus,
    );

    if (remoteResult != null) {
      return remoteResult;
    }

    final currentAssignments = await _getLocalAssignments();

    bool wasUpdated = false;

    final updatedAssignments = currentAssignments.map((assignment) {
      final bool isTargetAssignment =
          assignment.assignedToType == 'Student' &&
          assignment.assignedToName == studentName &&
          assignment.title == title &&
          assignment.category == category &&
          assignment.status != 'Reviewed';

      if (isTargetAssignment && !wasUpdated) {
        wasUpdated = true;

        return AssignedActivity(
          id: assignment.id,
          title: assignment.title,
          category: assignment.category,
          level: assignment.level,
          assignedToName: assignment.assignedToName,
          assignedToType: assignment.assignedToType,
          dueDate: assignment.dueDate,
          status: newStatus,
          note: assignment.note,
        );
      }

      return assignment;
    }).toList();

    if (!wasUpdated) {
      return false;
    }

    await _saveAssignments(updatedAssignments);

    return true;
  }

  static Future<void> deleteAssignment(String assignmentId) async {
    final wasDeletedRemotely = await _cancelRemoteAssignment(assignmentId);

    if (wasDeletedRemotely) {
      return;
    }

    final currentAssignments = await _getLocalAssignments();

    final updatedAssignments = currentAssignments
        .where((assignment) => assignment.id != assignmentId)
        .toList();

    await _saveAssignments(updatedAssignments);
  }

  static Future<void> clearAllAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_assignedActivitiesKey);
  }

  static Future<void> _saveAssignments(
    List<AssignedActivity> assignments,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final encodedData = jsonEncode(
      assignments.map((assignment) => assignment.toJson()).toList(),
    );

    await prefs.setString(_assignedActivitiesKey, encodedData);
  }

  static Future<bool?> _assignRemoteActivityToStudent({
    required String? studentId,
    required String studentName,
    required String title,
    required String category,
    required String level,
    required String dueDate,
    required String note,
  }) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null) {
      return null;
    }

    try {
      final targetStudentId = studentId?.isNotEmpty == true
          ? studentId
          : await _findStudentIdByName(studentName);

      if (targetStudentId == null || targetStudentId.isEmpty) {
        return null;
      }

      final existingData = await client
          .from('assignments')
          .select('id,status')
          .eq('teacher_id', user.id)
          .eq('student_id', targetStudentId)
          .eq('title', title)
          .eq('category', category);

      final alreadyAssigned = _rowsFromResponse(existingData).any((row) {
        final status = row['status']?.toString() ?? '';
        return status != 'reviewed' && status != 'canceled';
      });

      if (alreadyAssigned) {
        return false;
      }

      final payload = <String, dynamic>{
        'teacher_id': user.id,
        'student_id': targetStudentId,
        'target_type': 'student',
        'title': title,
        'category': category,
        'level': level,
        'note': note,
        'status': 'pending',
      };

      final remoteDueDate = _dateOrNull(dueDate);

      if (remoteDueDate != null) {
        payload['due_date'] = remoteDueDate;
      }

      await client.from('assignments').insert(payload);

      return true;
    } catch (error) {
      debugPrint('Remote assign failed: $error');
      return null;
    }
  }

  static Future<bool> _updateRemoteAssignmentStatus({
    required String assignmentId,
    required String newStatus,
  }) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null || !assignmentId.contains('-')) {
      return false;
    }

    try {
      await client
          .from('assignments')
          .update(_statusPayload(newStatus))
          .eq('id', assignmentId);

      return true;
    } catch (error) {
      debugPrint('Remote assignment status update failed: $error');
      return false;
    }
  }

  static Future<bool?> _updateRemoteStudentAssignmentStatus({
    required String studentName,
    required String title,
    required String category,
    required String newStatus,
  }) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null) {
      return null;
    }

    try {
      final targetStudentId =
          await _currentRemoteStudentId() ??
          await _findStudentIdByName(studentName);

      if (targetStudentId == null || targetStudentId.isEmpty) {
        return null;
      }

      final data = await client
          .from('assignments')
          .select('id,status')
          .eq('student_id', targetStudentId)
          .eq('title', title)
          .eq('category', category);

      String? assignmentId;

      for (final row in _rowsFromResponse(data)) {
        final status = row['status']?.toString() ?? '';

        if (status != 'reviewed' && status != 'canceled') {
          assignmentId = row['id']?.toString();
          break;
        }
      }

      if (assignmentId == null) {
        return false;
      }

      await client
          .from('assignments')
          .update(_statusPayload(newStatus))
          .eq('id', assignmentId);

      return true;
    } catch (error) {
      debugPrint('Remote student assignment update failed: $error');
      return null;
    }
  }

  static Future<bool> _cancelRemoteAssignment(String assignmentId) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null || !assignmentId.contains('-')) {
      return false;
    }

    try {
      await client
          .from('assignments')
          .update({'status': 'canceled'})
          .eq('id', assignmentId);

      return true;
    } catch (error) {
      debugPrint('Remote assignment cancel failed: $error');
      return false;
    }
  }

  static Future<String?> _currentRemoteStudentId() async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('currentUserRole');

    if (role == 'student') {
      return user.id;
    }

    return null;
  }

  static Future<String?> _findStudentIdByName(String studentName) async {
    final client = SupabaseBootstrap.client;

    if (client == null || studentName.trim().isEmpty) {
      return null;
    }

    final data = await client
        .from('profiles')
        .select('id')
        .eq('role', 'student')
        .eq('full_name', studentName.trim())
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return data['id']?.toString();
  }

  static Future<Map<String, String>> _loadProfileNames(
    Iterable<Object?> values,
  ) async {
    final client = SupabaseBootstrap.client;

    if (client == null) {
      return {};
    }

    final ids = values
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) {
      return {};
    }

    final data = await client
        .from('profiles')
        .select('id,full_name')
        .inFilter('id', ids);

    return {
      for (final row in _rowsFromResponse(data))
        if (row['id'] != null)
          row['id'].toString(): row['full_name']?.toString() ?? 'Student',
    };
  }

  static AssignedActivity _assignedActivityFromRemote(
    Map<String, dynamic> row,
    Map<String, String> profileNames,
  ) {
    final targetType = row['target_type']?.toString() == 'class'
        ? 'Class'
        : 'Student';
    final studentId = row['student_id']?.toString() ?? '';

    return AssignedActivity(
      id: row['id']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      category: row['category']?.toString() ?? '',
      level: row['level']?.toString() ?? 'A1',
      assignedToName: targetType == 'Student'
          ? profileNames[studentId] ?? 'Student'
          : 'Class',
      assignedToType: targetType,
      dueDate: row['due_date']?.toString() ?? 'No due date',
      status: _localStatus(row['status']?.toString() ?? 'pending'),
      note: row['note']?.toString() ?? '',
    );
  }

  static Map<String, dynamic> _statusPayload(String status) {
    final remoteStatus = _remoteStatus(status);
    final payload = <String, dynamic>{'status': remoteStatus};

    if (remoteStatus == 'completed' || remoteStatus == 'review_needed') {
      payload['completed_at'] = DateTime.now().toIso8601String();
    }

    if (remoteStatus == 'reviewed') {
      payload['reviewed_at'] = DateTime.now().toIso8601String();
    }

    return payload;
  }

  static String _remoteStatus(String status) {
    switch (status) {
      case 'Completed':
        return 'completed';
      case 'Review Needed':
        return 'review_needed';
      case 'Reviewed':
        return 'reviewed';
      case 'Canceled':
        return 'canceled';
      case 'Pending':
      default:
        return 'pending';
    }
  }

  static String _localStatus(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'review_needed':
        return 'Review Needed';
      case 'reviewed':
        return 'Reviewed';
      case 'canceled':
        return 'Canceled';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  static String? _dateOrNull(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty || trimmed == 'No due date') {
      return null;
    }

    final parsed = DateTime.tryParse(trimmed);

    if (parsed == null) {
      return null;
    }

    return parsed.toIso8601String().substring(0, 10);
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

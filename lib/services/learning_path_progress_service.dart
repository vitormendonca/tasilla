import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/learning_path_data.dart';
import '../models/assigned_activity.dart';
import '../models/learning_path_step.dart';
import 'supabase_bootstrap.dart';

class LearningPathSkillProgress {
  final String skillId;
  final int completedLessons;
  final int totalLessons;
  final int completedReviews;
  final int totalReviews;
  final bool finalTestCompleted;

  const LearningPathSkillProgress({
    required this.skillId,
    required this.completedLessons,
    required this.totalLessons,
    required this.completedReviews,
    required this.totalReviews,
    required this.finalTestCompleted,
  });

  int get completedSteps {
    return completedLessons + completedReviews + (finalTestCompleted ? 1 : 0);
  }

  int get totalSteps {
    return totalLessons + totalReviews + 1;
  }

  double get lessonProgress {
    if (totalLessons == 0) {
      return 0;
    }

    return completedLessons / totalLessons;
  }
}

class LearningPathProgressService {
  static const String _completedStepsPrefix = 'learning_path_completed_steps';
  static const String _validatedLevelsPrefix = 'learning_path_validated_levels';

  static Future<Set<String>> getCompletedStepIds() async {
    final remoteCompleted = await _getRemoteCompletedStepIds();

    if (remoteCompleted != null) {
      await _saveLocalCompletedStepIds(remoteCompleted);
      return remoteCompleted;
    }

    return _getLocalCompletedStepIds();
  }

  static Future<Set<String>> _getLocalCompletedStepIds() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _completedStepsKey(prefs);
    final jsonString = prefs.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      return {};
    }

    return decoded.map((item) => item.toString()).toSet();
  }

  static Future<void> markStepCompleted(String stepId) async {
    await _markRemoteStepCompleted(stepId);
    final completed = await _getLocalCompletedStepIds();

    completed.add(stepId);

    await _saveLocalCompletedStepIds(completed);
  }

  static Future<void> markNextLessonCompletedForCategory(
    String category,
  ) async {
    final skillId = skillIdForAssignmentCategory(category);

    if (skillId == null) {
      return;
    }

    await markNextLessonCompletedForSkill(skillId);
  }

  static Future<void> markNextLessonCompletedForSkill(String skillId) async {
    final completed = await getCompletedStepIds();
    final lessonSteps = getLearningPathStepsBySkill(
      skillId,
    ).where((step) => step.type == LearningPathStepType.lesson).toList();

    for (final step in lessonSteps) {
      if (!completed.contains(step.id)) {
        await markStepCompleted(step.id);
        return;
      }
    }
  }

  static Future<void> syncCompletedAssignmentsToLearningPath(
    Iterable<AssignedActivity> assignments,
  ) async {
    final requiredLessonsBySkill = <String, int>{};

    for (final assignment in assignments) {
      final status = assignment.status.toLowerCase().trim();

      if (status != 'completed' && status != 'reviewed') {
        continue;
      }

      final skillId = skillIdForAssignmentCategory(assignment.category);

      if (skillId == null) {
        continue;
      }

      requiredLessonsBySkill[skillId] =
          (requiredLessonsBySkill[skillId] ?? 0) + 1;
    }

    if (requiredLessonsBySkill.isEmpty) {
      return;
    }

    final completed = await getCompletedStepIds();

    for (final entry in requiredLessonsBySkill.entries) {
      final lessonSteps = getLearningPathStepsBySkill(
        entry.key,
      ).where((step) => step.type == LearningPathStepType.lesson).toList();

      final completedLessonCount = lessonSteps
          .where((step) => completed.contains(step.id))
          .length;
      final missingLessonCount = entry.value - completedLessonCount;

      if (missingLessonCount <= 0) {
        continue;
      }

      var marked = 0;

      for (final step in lessonSteps) {
        if (completed.contains(step.id)) {
          continue;
        }

        await markStepCompleted(step.id);
        completed.add(step.id);
        marked++;

        if (marked >= missingLessonCount) {
          break;
        }
      }
    }
  }

  static String? skillIdForAssignmentCategory(String category) {
    final normalized = category.toLowerCase().trim();

    switch (normalized) {
      case 'listening':
        return 'listening';
      case 'speaking':
        return 'speaking';
      case 'reading':
        return 'reading';
      case 'vocabulary':
        return 'vocabulary';
      case 'homework':
      case 'grammar':
      case 'practice':
      case 'grammar & practice':
        return 'homework';
      default:
        return null;
    }
  }

  static Future<bool> isStepCompleted(String stepId) async {
    final completed = await getCompletedStepIds();
    return completed.contains(stepId);
  }

  static Future<Set<String>> getValidatedLevels() async {
    final remoteValidatedLevels = await _getRemoteValidatedLevels();

    if (remoteValidatedLevels != null) {
      await _saveLocalValidatedLevels(remoteValidatedLevels);
      return remoteValidatedLevels;
    }

    return _getLocalValidatedLevels();
  }

  static Future<Set<String>> _getLocalValidatedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _validatedLevelsKey(prefs);
    final jsonString = prefs.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      return {};
    }

    return decoded.map((item) => item.toString()).toSet();
  }

  static Future<bool> isLevelValidated(String level) async {
    final validatedLevels = await getValidatedLevels();
    return validatedLevels.contains(level.toUpperCase());
  }

  static Future<void> validateLevel(String level) async {
    final normalizedLevel = level.toUpperCase();
    final completed = await _getLocalCompletedStepIds();
    final validatedLevels = await _getLocalValidatedLevels();

    final levelStepIds = _stepIdsForLevel(normalizedLevel);

    await _validateRemoteLevel(
      level: normalizedLevel,
      stepIds: levelStepIds.toList(),
    );

    completed.addAll(levelStepIds);
    validatedLevels.add(normalizedLevel);

    await _saveLocalCompletedStepIds(completed);
    await _saveLocalValidatedLevels(validatedLevels);
  }

  static Future<void> recordLevelCheckAttempt({
    required String level,
    required int score,
    required bool passed,
    required Map<String, String> answers,
  }) async {
    await _recordRemoteLevelCheckAttempt(
      level: level.toUpperCase(),
      score: score,
      passed: passed,
      answers: answers,
    );
  }

  static Future<void> recordStepAttempt({
    required String stepId,
    required double score,
    required bool passed,
  }) async {
    await _recordRemoteStepAttempt(
      stepId: stepId,
      score: score,
      passed: passed,
    );
  }

  static Iterable<String> _stepIdsForLevel(String level) {
    return learningPathSteps
        .where((step) => step.level.toUpperCase() == level)
        .map((step) => step.id);
  }

  static bool isStepUnlocked({
    required LearningPathStep step,
    required Set<String> completedStepIds,
  }) {
    final skillSteps = getLearningPathStepsBySkill(step.skillId);
    final stepIndex = skillSteps.indexWhere((item) => item.id == step.id);

    if (stepIndex <= 0) {
      return true;
    }

    final previousStep = skillSteps[stepIndex - 1];
    return completedStepIds.contains(previousStep.id);
  }

  static Future<LearningPathSkillProgress> getSkillProgress(
    String skillId,
  ) async {
    final completed = await getCompletedStepIds();
    return getSkillProgressFromCompleted(
      skillId: skillId,
      completedStepIds: completed,
    );
  }

  static Future<Map<String, LearningPathSkillProgress>>
  getAllSkillProgress() async {
    final completed = await getCompletedStepIds();

    return getAllSkillProgressFromCompleted(completed);
  }

  static Future<Map<String, LearningPathSkillProgress>>
  getAllSkillProgressForStudent({
    required String studentId,
    required String studentName,
  }) async {
    final completed = await getCompletedStepIdsForStudent(
      studentId: studentId,
      studentName: studentName,
    );

    return getAllSkillProgressFromCompleted(completed);
  }

  static Future<Set<String>> getCompletedStepIdsForStudent({
    required String studentId,
    required String studentName,
  }) async {
    final remoteCompleted = await _getRemoteCompletedStepIdsForStudent(
      studentId,
    );

    if (remoteCompleted != null) {
      return remoteCompleted;
    }

    return _getLocalCompletedStepIdsForIdentity(
      studentId: studentId,
      studentName: studentName,
    );
  }

  static Map<String, LearningPathSkillProgress>
  getAllSkillProgressFromCompleted(Set<String> completedStepIds) {
    return {
      for (final skill in learningSkillDefinitions)
        skill.id: getSkillProgressFromCompleted(
          skillId: skill.id,
          completedStepIds: completedStepIds,
        ),
    };
  }

  static LearningPathSkillProgress getSkillProgressFromCompleted({
    required String skillId,
    required Set<String> completedStepIds,
  }) {
    final skillSteps = getLearningPathStepsBySkill(skillId);
    final lessonSteps = skillSteps
        .where((step) => step.type == LearningPathStepType.lesson)
        .toList();
    final reviewSteps = skillSteps
        .where((step) => step.type == LearningPathStepType.review)
        .toList();
    LearningPathStep? finalTestStep;

    for (final step in skillSteps) {
      if (step.type == LearningPathStepType.finalTest) {
        finalTestStep = step;
        break;
      }
    }

    final completedLessons = lessonSteps
        .where((step) => completedStepIds.contains(step.id))
        .length;
    final completedReviews = reviewSteps
        .where((step) => completedStepIds.contains(step.id))
        .length;

    return LearningPathSkillProgress(
      skillId: skillId,
      completedLessons: completedLessons,
      totalLessons: lessonSteps.length,
      completedReviews: completedReviews,
      totalReviews: reviewSteps.length,
      finalTestCompleted:
          finalTestStep != null && completedStepIds.contains(finalTestStep.id),
    );
  }

  static Future<String> _completedStepsKey(SharedPreferences prefs) async {
    final studentId = prefs.getString('currentStudentId');
    final studentName = prefs.getString('currentStudentName');

    return _completedStepsKeyForIdentity(
      studentId: studentId,
      studentName: studentName,
    );
  }

  static Future<String> _validatedLevelsKey(SharedPreferences prefs) async {
    final studentId = prefs.getString('currentStudentId');
    final studentName = prefs.getString('currentStudentName');

    return _validatedLevelsKeyForIdentity(
      studentId: studentId,
      studentName: studentName,
    );
  }

  static String _normalizeKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
  }

  static Future<void> _saveLocalCompletedStepIds(Set<String> completed) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _completedStepsKey(prefs);

    await prefs.setString(key, jsonEncode(completed.toList()));
  }

  static Future<void> _saveLocalValidatedLevels(Set<String> levels) async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _validatedLevelsKey(prefs);

    await prefs.setString(key, jsonEncode(levels.toList()));
  }

  static Future<Set<String>> _getLocalCompletedStepIdsForIdentity({
    required String studentId,
    required String studentName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _completedStepsKeyForIdentity(
      studentId: studentId,
      studentName: studentName,
    );
    final jsonString = prefs.getString(key);

    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      return {};
    }

    return decoded.map((item) => item.toString()).toSet();
  }

  static String _completedStepsKeyForIdentity({
    String? studentId,
    String? studentName,
  }) {
    return '${_completedStepsPrefix}_${_studentStorageKey(studentId: studentId, studentName: studentName)}';
  }

  static String _validatedLevelsKeyForIdentity({
    String? studentId,
    String? studentName,
  }) {
    return '${_validatedLevelsPrefix}_${_studentStorageKey(studentId: studentId, studentName: studentName)}';
  }

  static String _studentStorageKey({String? studentId, String? studentName}) {
    final studentKey = (studentId?.isNotEmpty ?? false)
        ? studentId!
        : (studentName?.isNotEmpty ?? false)
        ? studentName!
        : 'guest';

    return _normalizeKey(studentKey);
  }

  static Future<String?> _remoteStudentId() async {
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

  static Future<Set<String>?> _getRemoteCompletedStepIds() async {
    final client = SupabaseBootstrap.client;
    final studentId = await _remoteStudentId();

    if (client == null || studentId == null) {
      return null;
    }

    try {
      final data = await client
          .from('student_step_progress')
          .select('learning_step_id')
          .eq('student_id', studentId)
          .inFilter('status', const ['completed', 'validated', 'approved']);

      return _rowsFromResponse(data)
          .map((row) => row['learning_step_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (error) {
      debugPrint('Remote learning path progress unavailable: $error');
      return null;
    }
  }

  static Future<Set<String>?> _getRemoteCompletedStepIdsForStudent(
    String studentId,
  ) async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client == null || user == null || studentId.isEmpty) {
      return null;
    }

    try {
      final data = await client
          .from('student_step_progress')
          .select('learning_step_id')
          .eq('student_id', studentId)
          .inFilter('status', const ['completed', 'validated', 'approved']);

      return _rowsFromResponse(data)
          .map((row) => row['learning_step_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
    } catch (error) {
      debugPrint('Remote student learning path progress unavailable: $error');
      return null;
    }
  }

  static Future<bool> _markRemoteStepCompleted(String stepId) async {
    final client = SupabaseBootstrap.client;
    final studentId = await _remoteStudentId();

    if (client == null || studentId == null) {
      return false;
    }

    try {
      await client.from('student_step_progress').upsert({
        'student_id': studentId,
        'learning_step_id': stepId,
        'status': 'completed',
        'validated_by_level_check': false,
        'completed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'student_id,learning_step_id');

      return true;
    } catch (error) {
      debugPrint('Remote step completion failed: $error');
      return false;
    }
  }

  static Future<Set<String>?> _getRemoteValidatedLevels() async {
    final client = SupabaseBootstrap.client;
    final studentId = await _remoteStudentId();

    if (client == null || studentId == null) {
      return null;
    }

    try {
      final data = await client
          .from('student_step_progress')
          .select('learning_step_id')
          .eq('student_id', studentId)
          .eq('validated_by_level_check', true);

      final stepLevelsById = {
        for (final step in learningPathSteps) step.id: step.level.toUpperCase(),
      };

      return _rowsFromResponse(data)
          .map((row) => row['learning_step_id']?.toString() ?? '')
          .where((id) => stepLevelsById.containsKey(id))
          .map((id) => stepLevelsById[id]!)
          .toSet();
    } catch (error) {
      debugPrint('Remote validated levels unavailable: $error');
      return null;
    }
  }

  static Future<void> _validateRemoteLevel({
    required String level,
    required List<String> stepIds,
  }) async {
    final client = SupabaseBootstrap.client;
    final studentId = await _remoteStudentId();

    if (client == null || studentId == null || stepIds.isEmpty) {
      return;
    }

    try {
      final completedAt = DateTime.now().toIso8601String();
      final rows = stepIds.map((stepId) {
        return {
          'student_id': studentId,
          'learning_step_id': stepId,
          'status': 'validated',
          'validated_by_level_check': true,
          'completed_at': completedAt,
        };
      }).toList();

      await client
          .from('student_step_progress')
          .upsert(rows, onConflict: 'student_id,learning_step_id');
    } catch (error) {
      debugPrint('Remote level validation failed for $level: $error');
    }
  }

  static Future<void> _recordRemoteLevelCheckAttempt({
    required String level,
    required int score,
    required bool passed,
    required Map<String, String> answers,
  }) async {
    final client = SupabaseBootstrap.client;
    final studentId = await _remoteStudentId();

    if (client == null || studentId == null) {
      return;
    }

    try {
      await client.from('level_check_attempts').insert({
        'student_id': studentId,
        'level': level,
        'score': score,
        'passed': passed,
        'answers': answers,
      });
    } catch (error) {
      debugPrint('Remote level check attempt failed: $error');
    }
  }

  static Future<void> _recordRemoteStepAttempt({
    required String stepId,
    required double score,
    required bool passed,
  }) async {
    final client = SupabaseBootstrap.client;
    final studentId = await _remoteStudentId();

    if (client == null || studentId == null) {
      return;
    }

    try {
      await client.from('student_step_progress').upsert({
        'student_id': studentId,
        'learning_step_id': stepId,
        'status': passed ? 'completed' : 'review_needed',
        'score': score,
        'validated_by_level_check': false,
        'completed_at': DateTime.now().toIso8601String(),
      }, onConflict: 'student_id,learning_step_id');
    } catch (error) {
      debugPrint('Remote step attempt recording failed: $error');
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
}

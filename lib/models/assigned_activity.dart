import 'learning_enums.dart';

class AssignedActivity {
  final String id;

  final String title;
  final String category; // Listening, Vocabulary, Reading, Homework
  final String level;
  final String levelId;
  final String cycleId;
  final LearningSkill? skill;
  final ActivityKind? activityKind;
  final String cefrLevel;
  final String canDoStatement;
  final double passingScore;

  final String assignedToName;
  final String assignedToType; // Student or Class

  final String dueDate;
  final String status; // Pending, Completed, Review Needed
  final int? score;

  final String note;

  const AssignedActivity({
    required this.id,
    required this.title,
    required this.category,
    required this.level,
    this.levelId = '',
    this.cycleId = '',
    this.skill,
    this.activityKind,
    this.cefrLevel = '',
    this.canDoStatement = '',
    this.passingScore = 0.75,
    required this.assignedToName,
    required this.assignedToType,
    required this.dueDate,
    required this.status,
    this.score,
    required this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'level': level,
      'levelId': levelId,
      'cycleId': cycleId,
      'skill': skill?.storageKey,
      'activityKind': activityKind?.storageKey,
      'cefrLevel': cefrLevel,
      'canDoStatement': canDoStatement,
      'passingScore': passingScore,
      'assignedToName': assignedToName,
      'assignedToType': assignedToType,
      'dueDate': dueDate,
      'status': status,
      'score': score,
      'note': note,
    };
  }

  factory AssignedActivity.fromJson(Map<String, dynamic> json) {
    return AssignedActivity(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      level: json['level'] ?? '',
      levelId: json['levelId'] ?? '',
      cycleId: json['cycleId'] ?? '',
      skill: _learningSkillFromStorageKey(json['skill']?.toString()),
      activityKind: _activityKindFromStorageKey(
        json['activityKind']?.toString(),
      ),
      cefrLevel: json['cefrLevel'] ?? '',
      canDoStatement: json['canDoStatement'] ?? '',
      passingScore: _doubleFromJson(json['passingScore']) ?? 0.75,
      assignedToName: json['assignedToName'] ?? '',
      assignedToType: json['assignedToType'] ?? 'Student',
      dueDate: json['dueDate'] ?? 'No due date',
      status: json['status'] ?? 'Pending',
      score: _intFromJson(json['score']),
      note: json['note'] ?? '',
    );
  }

  static LearningSkill? _learningSkillFromStorageKey(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    for (final skill in LearningSkill.values) {
      if (skill.storageKey == value) {
        return skill;
      }
    }

    return null;
  }

  static ActivityKind? _activityKindFromStorageKey(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    for (final kind in ActivityKind.values) {
      if (kind.storageKey == value) {
        return kind;
      }
    }

    return null;
  }

  static int? _intFromJson(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  static double? _doubleFromJson(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}

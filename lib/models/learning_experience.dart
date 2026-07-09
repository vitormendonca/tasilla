import 'activity_question.dart';
import 'learning_enums.dart';

enum LearningExperienceStatus { draft, published, archived }

enum WritingMode {
  guidedIntroduction,
  guidedProfile,
  guidedFamilyDescription,
  guidedRoutine,
  guidedSchedule,
  guidedPreferences,
  guidedPlaces,
  guidedInstructions,
  guidedOrder,
  guidedWorkStudy,
  shortMessage,
  miniProfile,
  freeResponse,
}

enum ReadingFormat { paragraph, dialogue, notice, message, form }

extension LearningExperienceStatusStorage on LearningExperienceStatus {
  String get storageKey {
    switch (this) {
      case LearningExperienceStatus.draft:
        return 'draft';
      case LearningExperienceStatus.published:
        return 'published';
      case LearningExperienceStatus.archived:
        return 'archived';
    }
  }
}

extension WritingModeStorage on WritingMode {
  String get storageKey {
    switch (this) {
      case WritingMode.guidedIntroduction:
        return 'guided_introduction';
      case WritingMode.guidedProfile:
        return 'guided_profile';
      case WritingMode.guidedFamilyDescription:
        return 'guided_family_description';
      case WritingMode.guidedRoutine:
        return 'guided_routine';
      case WritingMode.guidedSchedule:
        return 'guided_schedule';
      case WritingMode.guidedPreferences:
        return 'guided_preferences';
      case WritingMode.guidedPlaces:
        return 'guided_places';
      case WritingMode.guidedInstructions:
        return 'guided_instructions';
      case WritingMode.guidedOrder:
        return 'guided_order';
      case WritingMode.guidedWorkStudy:
        return 'guided_work_study';
      case WritingMode.shortMessage:
        return 'short_message';
      case WritingMode.miniProfile:
        return 'mini_profile';
      case WritingMode.freeResponse:
        return 'free_response';
    }
  }
}

extension ReadingFormatStorage on ReadingFormat {
  String get storageKey {
    switch (this) {
      case ReadingFormat.paragraph:
        return 'paragraph';
      case ReadingFormat.dialogue:
        return 'dialogue';
      case ReadingFormat.notice:
        return 'notice';
      case ReadingFormat.message:
        return 'message';
      case ReadingFormat.form:
        return 'form';
    }
  }
}

class ContentExample {
  final String prompt;
  final String response;

  const ContentExample({required this.prompt, required this.response});

  Map<String, dynamic> toJson() {
    return {'prompt': prompt, 'response': response};
  }

  factory ContentExample.fromJson(Map<String, dynamic> json) {
    return ContentExample(
      prompt: json['prompt']?.toString() ?? '',
      response: json['response']?.toString() ?? '',
    );
  }
}

class VocabularyBlock {
  final String title;
  final List<String> words;
  final List<String> exampleSentences;

  const VocabularyBlock({
    required this.title,
    this.words = const [],
    this.exampleSentences = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'words': words,
      'exampleSentences': exampleSentences,
    };
  }

  factory VocabularyBlock.fromJson(Map<String, dynamic> json) {
    return VocabularyBlock(
      title: json['title']?.toString() ?? '',
      words: _stringList(json['words']),
      exampleSentences: _stringList(json['exampleSentences']),
    );
  }
}

class GrammarBlock {
  final String title;
  final String explanation;
  final List<String> patterns;
  final List<String> examples;

  const GrammarBlock({
    required this.title,
    required this.explanation,
    this.patterns = const [],
    this.examples = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'explanation': explanation,
      'patterns': patterns,
      'examples': examples,
    };
  }

  factory GrammarBlock.fromJson(Map<String, dynamic> json) {
    return GrammarBlock(
      title: json['title']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      patterns: _stringList(json['patterns']),
      examples: _stringList(json['examples']),
    );
  }
}

class QuizBlock {
  final List<ActivityQuestion> questions;
  final Map<String, String> explanations;

  const QuizBlock({this.questions = const [], this.explanations = const {}});

  Map<String, dynamic> toJson() {
    return {
      'questions': questions.map(_questionToJson).toList(),
      'explanations': explanations,
    };
  }

  factory QuizBlock.fromJson(Map<String, dynamic> json) {
    return QuizBlock(
      questions: _questionList(json['questions']),
      explanations: _stringMap(json['explanations']),
    );
  }
}

class ListeningBlock {
  final String audioTitle;
  final String audioScript;
  final String? audioPath;
  final String audioStatus;
  final int maxAudioPlays;
  final List<ActivityQuestion> listeningQuestions;
  final int numberOfSpeakers;

  const ListeningBlock({
    required this.audioTitle,
    required this.audioScript,
    this.audioPath,
    this.audioStatus = 'pending_generation',
    this.maxAudioPlays = 2,
    this.listeningQuestions = const [],
    this.numberOfSpeakers = 1,
  });

  bool get hasPlannedAudioPath {
    return audioPath != null && audioPath!.trim().isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'audioTitle': audioTitle,
      'audioScript': audioScript,
      'audioPath': audioPath,
      'audioStatus': audioStatus,
      'maxAudioPlays': maxAudioPlays,
      'listeningQuestions': listeningQuestions.map(_questionToJson).toList(),
      'numberOfSpeakers': numberOfSpeakers,
    };
  }

  factory ListeningBlock.fromJson(Map<String, dynamic> json) {
    return ListeningBlock(
      audioTitle: json['audioTitle']?.toString() ?? '',
      audioScript: json['audioScript']?.toString() ?? '',
      audioPath: json['audioPath']?.toString(),
      audioStatus: json['audioStatus']?.toString() ?? 'pending_generation',
      maxAudioPlays: _intFromJson(json['maxAudioPlays']) ?? 2,
      listeningQuestions: _questionList(json['listeningQuestions']),
      numberOfSpeakers: _intFromJson(json['numberOfSpeakers']) ?? 1,
    );
  }
}

class ReadingBlock {
  final String readingTitle;
  final String readingText;
  final ReadingFormat readingFormat;
  final List<ActivityQuestion> readingQuestions;

  const ReadingBlock({
    required this.readingTitle,
    required this.readingText,
    this.readingFormat = ReadingFormat.paragraph,
    this.readingQuestions = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'readingTitle': readingTitle,
      'readingText': readingText,
      'readingFormat': readingFormat.storageKey,
      'readingQuestions': readingQuestions.map(_questionToJson).toList(),
    };
  }

  factory ReadingBlock.fromJson(Map<String, dynamic> json) {
    return ReadingBlock(
      readingTitle: json['readingTitle']?.toString() ?? '',
      readingText: json['readingText']?.toString() ?? '',
      readingFormat: _readingFormatFromStorageKey(
        json['readingFormat']?.toString(),
      ),
      readingQuestions: _questionList(json['readingQuestions']),
    );
  }
}

class WritingTask {
  final String writingPrompt;
  final WritingMode writingMode;
  final List<String> wordBank;
  final List<String> minimumRequirements;
  final int minSentences;
  final int maxSentences;
  final bool requiresTeacherReview;

  const WritingTask({
    required this.writingPrompt,
    required this.writingMode,
    this.wordBank = const [],
    this.minimumRequirements = const [],
    this.minSentences = 1,
    this.maxSentences = 4,
    this.requiresTeacherReview = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'writingPrompt': writingPrompt,
      'writingMode': writingMode.storageKey,
      'wordBank': wordBank,
      'minimumRequirements': minimumRequirements,
      'minSentences': minSentences,
      'maxSentences': maxSentences,
      'requiresTeacherReview': requiresTeacherReview,
    };
  }

  factory WritingTask.fromJson(Map<String, dynamic> json) {
    return WritingTask(
      writingPrompt: json['writingPrompt']?.toString() ?? '',
      writingMode: _writingModeFromStorageKey(json['writingMode']?.toString()),
      wordBank: _stringList(json['wordBank']),
      minimumRequirements: _stringList(json['minimumRequirements']),
      minSentences: _intFromJson(json['minSentences']) ?? 1,
      maxSentences: _intFromJson(json['maxSentences']) ?? 4,
      requiresTeacherReview: json['requiresTeacherReview'] == true,
    );
  }
}

class SpeakingTask {
  final String speakingPrompt;
  final bool recordingRequired;
  final int maxRecordingSeconds;
  final bool minimumSubmissionRequired;
  final bool requiresTeacherReview;

  const SpeakingTask({
    required this.speakingPrompt,
    this.recordingRequired = true,
    this.maxRecordingSeconds = 60,
    this.minimumSubmissionRequired = true,
    this.requiresTeacherReview = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'speakingPrompt': speakingPrompt,
      'recordingRequired': recordingRequired,
      'maxRecordingSeconds': maxRecordingSeconds,
      'minimumSubmissionRequired': minimumSubmissionRequired,
      'requiresTeacherReview': requiresTeacherReview,
    };
  }

  factory SpeakingTask.fromJson(Map<String, dynamic> json) {
    return SpeakingTask(
      speakingPrompt: json['speakingPrompt']?.toString() ?? '',
      recordingRequired: json['recordingRequired'] != false,
      maxRecordingSeconds: _intFromJson(json['maxRecordingSeconds']) ?? 60,
      minimumSubmissionRequired: json['minimumSubmissionRequired'] != false,
      requiresTeacherReview: json['requiresTeacherReview'] == true,
    );
  }
}

class RubricCriterion {
  final String title;
  final String description;
  final int maxScore;

  const RubricCriterion({
    required this.title,
    required this.description,
    this.maxScore = 5,
  });

  Map<String, dynamic> toJson() {
    return {'title': title, 'description': description, 'maxScore': maxScore};
  }

  factory RubricCriterion.fromJson(Map<String, dynamic> json) {
    return RubricCriterion(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      maxScore: _intFromJson(json['maxScore']) ?? 5,
    );
  }
}

class Rubric {
  final List<RubricCriterion> criteria;

  const Rubric({this.criteria = const []});

  Map<String, dynamic> toJson() {
    return {'criteria': criteria.map((item) => item.toJson()).toList()};
  }

  factory Rubric.fromJson(Map<String, dynamic> json) {
    return Rubric(
      criteria: _mapList(
        json['criteria'],
      ).map(RubricCriterion.fromJson).toList(),
    );
  }
}

class LearningExperience {
  final String id;
  final int order;
  final String title;
  final String description;
  final String level;
  final String cefrLevel;
  final String unitId;
  final int difficultyLevel;
  final int estimatedMinutes;
  final bool requiredForCertificate;
  final LearningSkill primarySkill;
  final List<LearningSkill> secondarySkills;
  final ActivityKind activityKind;
  final String canDoStatement;
  final String contentVersion;
  final LearningExperienceStatus status;
  final DateTime? lastUpdated;
  final String createdBy;
  final String introductionText;
  final List<VocabularyBlock> vocabularyBlocks;
  final List<GrammarBlock> grammarBlocks;
  final List<ContentExample> examples;
  final QuizBlock? quizBlock;
  final ListeningBlock? listeningBlock;
  final ReadingBlock? readingBlock;
  final WritingTask? writingTask;
  final SpeakingTask? speakingTask;
  final String teacherNotes;
  final Rubric? rubric;
  final double passingScore;
  final int attempts;
  final bool completed;
  final bool needsReview;

  const LearningExperience({
    required this.id,
    required this.order,
    required this.title,
    required this.description,
    required this.level,
    required this.cefrLevel,
    required this.unitId,
    required this.difficultyLevel,
    required this.estimatedMinutes,
    required this.requiredForCertificate,
    required this.primarySkill,
    this.secondarySkills = const [],
    required this.activityKind,
    required this.canDoStatement,
    required this.contentVersion,
    required this.status,
    this.lastUpdated,
    this.createdBy = 'levels_curriculum',
    this.introductionText = '',
    this.vocabularyBlocks = const [],
    this.grammarBlocks = const [],
    this.examples = const [],
    this.quizBlock,
    this.listeningBlock,
    this.readingBlock,
    this.writingTask,
    this.speakingTask,
    this.teacherNotes = '',
    this.rubric,
    this.passingScore = 0.75,
    this.attempts = 0,
    this.completed = false,
    this.needsReview = false,
  }) : assert(difficultyLevel >= 1 && difficultyLevel <= 5);

  bool get hasPlannedAudio {
    return listeningBlock?.hasPlannedAudioPath ?? false;
  }

  bool get requiresTeacherReview {
    return (writingTask?.requiresTeacherReview ?? false) ||
        (speakingTask?.requiresTeacherReview ?? false) ||
        needsReview;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'title': title,
      'description': description,
      'level': level,
      'cefrLevel': cefrLevel,
      'unitId': unitId,
      'difficultyLevel': difficultyLevel,
      'estimatedMinutes': estimatedMinutes,
      'requiredForCertificate': requiredForCertificate,
      'primarySkill': primarySkill.storageKey,
      'secondarySkills': secondarySkills
          .map((skill) => skill.storageKey)
          .toList(),
      'activityKind': activityKind.storageKey,
      'canDoStatement': canDoStatement,
      'contentVersion': contentVersion,
      'status': status.storageKey,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'createdBy': createdBy,
      'introductionText': introductionText,
      'vocabularyBlocks': vocabularyBlocks
          .map((block) => block.toJson())
          .toList(),
      'grammarBlocks': grammarBlocks.map((block) => block.toJson()).toList(),
      'examples': examples.map((example) => example.toJson()).toList(),
      'quizBlock': quizBlock?.toJson(),
      'listeningBlock': listeningBlock?.toJson(),
      'readingBlock': readingBlock?.toJson(),
      'writingTask': writingTask?.toJson(),
      'speakingTask': speakingTask?.toJson(),
      'teacherNotes': teacherNotes,
      'rubric': rubric?.toJson(),
      'passingScore': passingScore,
      'attempts': attempts,
      'completed': completed,
      'needsReview': needsReview,
    };
  }

  factory LearningExperience.fromJson(Map<String, dynamic> json) {
    return LearningExperience(
      id: json['id']?.toString() ?? '',
      order: _intFromJson(json['order']) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      cefrLevel: json['cefrLevel']?.toString() ?? '',
      unitId: json['unitId']?.toString() ?? '',
      difficultyLevel: _intFromJson(json['difficultyLevel']) ?? 1,
      estimatedMinutes: _intFromJson(json['estimatedMinutes']) ?? 10,
      requiredForCertificate: json['requiredForCertificate'] == true,
      primarySkill: _learningSkillFromStorageKey(
        json['primarySkill']?.toString(),
      ),
      secondarySkills: _stringList(
        json['secondarySkills'],
      ).map(_learningSkillFromStorageKey).toList(),
      activityKind: _activityKindFromStorageKey(
        json['activityKind']?.toString(),
      ),
      canDoStatement: json['canDoStatement']?.toString() ?? '',
      contentVersion: json['contentVersion']?.toString() ?? 'draft',
      status: _statusFromStorageKey(json['status']?.toString()),
      lastUpdated: _dateTimeFromJson(json['lastUpdated']),
      createdBy: json['createdBy']?.toString() ?? 'levels_curriculum',
      introductionText: json['introductionText']?.toString() ?? '',
      vocabularyBlocks: _mapList(
        json['vocabularyBlocks'],
      ).map(VocabularyBlock.fromJson).toList(),
      grammarBlocks: _mapList(
        json['grammarBlocks'],
      ).map(GrammarBlock.fromJson).toList(),
      examples: _mapList(
        json['examples'],
      ).map(ContentExample.fromJson).toList(),
      quizBlock: _nullableMap(json['quizBlock'], QuizBlock.fromJson),
      listeningBlock: _nullableMap(
        json['listeningBlock'],
        ListeningBlock.fromJson,
      ),
      readingBlock: _nullableMap(json['readingBlock'], ReadingBlock.fromJson),
      writingTask: _nullableMap(json['writingTask'], WritingTask.fromJson),
      speakingTask: _nullableMap(json['speakingTask'], SpeakingTask.fromJson),
      teacherNotes: json['teacherNotes']?.toString() ?? '',
      rubric: _nullableMap(json['rubric'], Rubric.fromJson),
      passingScore: _doubleFromJson(json['passingScore']) ?? 0.75,
      attempts: _intFromJson(json['attempts']) ?? 0,
      completed: json['completed'] == true,
      needsReview: json['needsReview'] == true,
    );
  }
}

T? _nullableMap<T>(Object? value, T Function(Map<String, dynamic>) builder) {
  if (value is! Map) {
    return null;
  }

  return builder(Map<String, dynamic>.from(value));
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) {
    return [];
  }

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return [];
  }

  return value.map((item) => item.toString()).toList();
}

Map<String, String> _stringMap(Object? value) {
  if (value is! Map) {
    return {};
  }

  return value.map((key, item) => MapEntry(key.toString(), item.toString()));
}

int? _intFromJson(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '');
}

double? _doubleFromJson(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '');
}

DateTime? _dateTimeFromJson(Object? value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}

LearningSkill _learningSkillFromStorageKey(String? value) {
  for (final skill in LearningSkill.values) {
    if (skill.storageKey == value || skill.name == value) {
      return skill;
    }
  }

  return LearningSkill.mixed;
}

ActivityKind _activityKindFromStorageKey(String? value) {
  for (final kind in ActivityKind.values) {
    if (kind.storageKey == value || kind.name == value) {
      return kind;
    }
  }

  return ActivityKind.coreActivity;
}

LearningExperienceStatus _statusFromStorageKey(String? value) {
  for (final status in LearningExperienceStatus.values) {
    if (status.storageKey == value || status.name == value) {
      return status;
    }
  }

  return LearningExperienceStatus.draft;
}

WritingMode _writingModeFromStorageKey(String? value) {
  for (final mode in WritingMode.values) {
    if (mode.storageKey == value || mode.name == value) {
      return mode;
    }
  }

  return WritingMode.freeResponse;
}

ReadingFormat _readingFormatFromStorageKey(String? value) {
  for (final format in ReadingFormat.values) {
    if (format.storageKey == value || format.name == value) {
      return format;
    }
  }

  return ReadingFormat.paragraph;
}

List<ActivityQuestion> _questionList(Object? value) {
  return _mapList(value).map(_questionFromJson).toList();
}

Map<String, dynamic> _questionToJson(ActivityQuestion question) {
  return {
    'id': question.id,
    'type': question.type.name,
    'question': question.question,
    'options': question.options,
    'correctAnswer': question.correctAnswer,
    'audioPath': question.audioPath,
    'words': question.words,
  };
}

ActivityQuestion _questionFromJson(Map<String, dynamic> json) {
  return ActivityQuestion(
    id: json['id']?.toString() ?? '',
    type: _questionTypeFromStorageKey(json['type']?.toString()),
    question: json['question']?.toString() ?? '',
    options: _stringList(json['options']),
    correctAnswer: json['correctAnswer']?.toString() ?? '',
    audioPath: json['audioPath']?.toString(),
    words: _stringList(json['words']),
  );
}

QuestionType _questionTypeFromStorageKey(String? value) {
  for (final type in QuestionType.values) {
    if (type.name == value) {
      return type;
    }
  }

  return QuestionType.multipleChoice;
}

import '../models/certificate_criteria.dart';
import '../models/activity_question.dart';
import '../models/learning_activity.dart';
import '../models/learning_cycle.dart';
import '../models/learning_enums.dart';
import '../models/learning_experience.dart';
import '../models/level_track.dart';
import 'a1_learning_experience_data.dart';

const CertificateCriteria a1CertificateCriteria = CertificateCriteria(
  minimumCompletionRate: 0.90,
  minimumOverallAverage: 0.75,
  minimumFinalExamScore: 0.75,
  minimumSkillAverage: 0.65,
  minimumSpeakingSubmissions: 10,
  minimumWritingSubmissions: 10,
  requireAllReviewsCompleted: true,
  requireAllCheckpointsCompleted: true,
);

const LevelTrack a1LevelTrack = LevelTrack(
  id: 'a1',
  title: 'A1 English Track',
  level: 'A1',
  description: 'Beginner English track aligned with CEFR A1 descriptors.',
  totalCoreActivities: 40,
  totalReinforcementActivities: 18,
  totalReviews: 6,
  totalCheckpoints: 3,
  totalPortfolioTasks: 2,
  totalFinalExams: 1,
  certificateCriteria: a1CertificateCriteria,
);

const List<LearningCycle> a1LearningCycles = [
  LearningCycle(
    id: 'a1_cycle_1',
    levelId: 'a1',
    cycleNumber: 1,
    title: 'A1.1 Introductions',
    canDoStatement: 'Introduce yourself and recognize basic greetings.',
    targetLanguage: ['hello', 'goodbye', 'my name is', 'I am'],
    skillsIncluded: _coreSkills,
  ),
  LearningCycle(
    id: 'a1_cycle_2',
    levelId: 'a1',
    cycleNumber: 2,
    title: 'A1.2 Personal Information',
    canDoStatement: 'Share and understand simple personal information.',
    targetLanguage: ['name', 'country', 'city', 'age'],
    skillsIncluded: _coreSkills,
  ),
  LearningCycle(
    id: 'a1_cycle_3',
    levelId: 'a1',
    cycleNumber: 3,
    title: 'A1.3 Family and People',
    canDoStatement: 'Talk about family and people using simple language.',
    targetLanguage: ['family', 'mother', 'father', 'friend'],
    skillsIncluded: _coreSkills,
  ),
  LearningCycle(
    id: 'a1_cycle_4',
    levelId: 'a1',
    cycleNumber: 4,
    title: 'A1.4 Daily Routine',
    canDoStatement: 'Describe basic daily routines.',
    targetLanguage: ['wake up', 'go to work', 'study', 'sleep'],
    skillsIncluded: _coreSkills,
  ),
  LearningCycle(
    id: 'a1_cycle_5',
    levelId: 'a1',
    cycleNumber: 5,
    title: 'A1.5 Numbers, Time and Days',
    canDoStatement: 'Use numbers, time and days in simple contexts.',
    targetLanguage: ['numbers', 'time', 'days', 'today'],
    skillsIncluded: _coreSkills,
  ),
  LearningCycle(
    id: 'a1_cycle_6',
    levelId: 'a1',
    cycleNumber: 6,
    title: 'A1.6 Likes and Preferences',
    canDoStatement: 'Express likes, dislikes and preferences.',
    targetLanguage: ['I like', 'I do not like', 'favorite', 'prefer'],
    skillsIncluded: _coreSkills,
  ),
  LearningCycle(
    id: 'a1_cycle_7',
    levelId: 'a1',
    cycleNumber: 7,
    title: 'A1.7 Places in Town',
    canDoStatement: 'Identify places in town and simple directions.',
    targetLanguage: ['school', 'market', 'bank', 'near'],
    skillsIncluded: _coreSkills,
  ),
  LearningCycle(
    id: 'a1_cycle_8',
    levelId: 'a1',
    cycleNumber: 8,
    title: 'A1.8 Instructions and Classroom Language',
    canDoStatement: 'Follow classroom instructions and learning language.',
    targetLanguage: ['listen', 'read', 'choose', 'answer'],
    skillsIncluded: _coreSkills,
  ),
  LearningCycle(
    id: 'a1_cycle_9',
    levelId: 'a1',
    cycleNumber: 9,
    title: 'A1.9 Shopping and Ordering',
    canDoStatement: 'Handle simple shopping and ordering situations.',
    targetLanguage: ['how much', 'I want', 'please', 'thank you'],
    skillsIncluded: _coreSkills,
  ),
  LearningCycle(
    id: 'a1_cycle_10',
    levelId: 'a1',
    cycleNumber: 10,
    title: 'A1.10 Work and Study',
    canDoStatement: 'Talk simply about work and study.',
    targetLanguage: ['job', 'student', 'teacher', 'work'],
    skillsIncluded: _coreSkills,
  ),
  LearningCycle(
    id: 'a1_cycle_11',
    levelId: 'a1',
    cycleNumber: 11,
    title: 'A1.11 Short Messages and Notices',
    canDoStatement: 'Understand and write short messages and notices.',
    targetLanguage: ['message', 'notice', 'address', 'phone number'],
    skillsIncluded: _coreSkills,
  ),
  LearningCycle(
    id: 'a1_cycle_12',
    levelId: 'a1',
    cycleNumber: 12,
    title: 'A1.12 A1 Integration Review',
    canDoStatement: 'Integrate core A1 skills in familiar situations.',
    targetLanguage: ['review', 'complete', 'ask', 'answer'],
    skillsIncluded: _coreSkills,
  ),
];

const List<LearningSkill> _coreSkills = [
  LearningSkill.listening,
  LearningSkill.reading,
  LearningSkill.vocabularyUseOfEnglish,
  LearningSkill.writing,
  LearningSkill.speaking,
];

LearningCycle? getA1LearningCycleById(String cycleId) {
  for (final cycle in a1LearningCycles) {
    if (cycle.id == cycleId) {
      return cycle;
    }
  }

  return null;
}

List<LearningActivity> getA1LearningActivities() {
  return getA1LearningExperiences().map((experience) {
    return LearningActivity(
      id: experience.id,
      levelId: 'a1',
      cycleId: experience.unitId,
      title: experience.title,
      description: experience.description,
      cefrLevel: experience.cefrLevel,
      canDoStatement: experience.canDoStatement,
      skill: experience.primarySkill,
      activityKind: experience.activityKind,
      passingScore: experience.passingScore,
      questions: _questionsFor(experience),
      audioPath: experience.listeningBlock?.audioPath,
      textContent: _textContentFor(experience),
      instructions: _instructionsFor(experience),
    );
  }).toList();
}

List<ActivityQuestion> _questionsFor(LearningExperience experience) {
  return [
    ...?experience.quizBlock?.questions,
    ...?experience.listeningBlock?.listeningQuestions,
    ...?experience.readingBlock?.readingQuestions,
  ];
}

String? _textContentFor(LearningExperience experience) {
  return experience.readingBlock?.readingText ??
      (experience.introductionText.isEmpty
          ? null
          : experience.introductionText);
}

String? _instructionsFor(LearningExperience experience) {
  final prompts = [
    experience.writingTask?.writingPrompt,
    experience.speakingTask?.speakingPrompt,
  ].whereType<String>().where((prompt) => prompt.trim().isNotEmpty).toList();

  if (prompts.isEmpty) {
    return null;
  }

  return prompts.join('\n');
}

import '../models/activity_question.dart';
import '../models/learning_enums.dart';
import '../models/learning_experience.dart';

const String a1ContentVersion = 'a1.2026.06.phase1';
final DateTime _a1ContentUpdatedAt = DateTime.utc(2026, 6, 10);

final List<LearningExperience> a1LearningExperiences = List.unmodifiable(
  _buildA1LearningExperiences(),
);

List<LearningExperience> getA1LearningExperiences() {
  return a1LearningExperiences;
}

LearningExperience? getA1LearningExperienceById(String id) {
  for (final experience in a1LearningExperiences) {
    if (experience.id == id) {
      return experience;
    }
  }

  return null;
}

List<LearningExperience> _buildA1LearningExperiences() {
  final experiences = <LearningExperience>[];
  var order = 1;

  void add(LearningExperience experience) {
    experiences.add(experience);
    order++;
  }

  for (var number = 1; number <= 10; number++) {
    add(_coreExperience(number: number, order: order));
  }
  for (var number = 1; number <= 4; number++) {
    add(_reinforcementExperience(number: number, order: order));
  }
  add(_reviewExperience(number: 1, order: order));
  add(_checkpointExperience(number: 1, order: order));

  for (var number = 11; number <= 20; number++) {
    add(_coreExperience(number: number, order: order));
  }
  for (var number = 5; number <= 9; number++) {
    add(_reinforcementExperience(number: number, order: order));
  }
  add(_reviewExperience(number: 2, order: order));

  for (var number = 21; number <= 30; number++) {
    add(_coreExperience(number: number, order: order));
  }
  for (var number = 10; number <= 14; number++) {
    add(_reinforcementExperience(number: number, order: order));
  }
  add(_reviewExperience(number: 3, order: order));
  add(_checkpointExperience(number: 2, order: order));

  for (var number = 31; number <= 40; number++) {
    add(_coreExperience(number: number, order: order));
  }
  for (var number = 15; number <= 18; number++) {
    add(_reinforcementExperience(number: number, order: order));
  }
  for (var number = 4; number <= 6; number++) {
    add(_reviewExperience(number: number, order: order));
  }
  add(_checkpointExperience(number: 3, order: order));
  add(_portfolioExperience(number: 1, order: order));
  add(_portfolioExperience(number: 2, order: order));
  add(_finalExamExperience(order: order));

  assert(experiences.length == 70);
  return experiences;
}

LearningExperience _coreExperience({required int number, required int order}) {
  final seed = _coreSeeds[number - 1];
  final id = 'A1-EXP-${_threeDigits(number)}';
  final isTeacherReviewed =
      seed.primarySkill == LearningSkill.writing ||
      seed.primarySkill == LearningSkill.speaking && number >= 31;

  return LearningExperience(
    id: id,
    order: order,
    title: seed.title,
    description: seed.description,
    level: 'A1',
    cefrLevel: 'A1',
    unitId: _unitIdForCore(number),
    difficultyLevel: seed.difficultyLevel ?? _difficultyForCore(number),
    estimatedMinutes: seed.estimatedMinutes ?? _estimatedMinutesForCore(number),
    requiredForCertificate: true,
    primarySkill: seed.primarySkill,
    secondarySkills: seed.secondarySkills.isEmpty
        ? _secondarySkillsFor(seed.primarySkill)
        : seed.secondarySkills,
    activityKind: ActivityKind.coreActivity,
    canDoStatement: seed.canDoStatement,
    contentVersion: a1ContentVersion,
    status: LearningExperienceStatus.published,
    lastUpdated: _a1ContentUpdatedAt,
    introductionText: seed.introduction,
    vocabularyBlocks: [
      VocabularyBlock(
        title: '${seed.shortTopic} words',
        words: seed.words,
        exampleSentences: seed.examples,
      ),
    ],
    grammarBlocks: [
      GrammarBlock(
        title: seed.grammarTitle,
        explanation: seed.grammarExplanation,
        patterns: seed.patterns,
        examples: seed.examples,
      ),
    ],
    examples: [
      ContentExample(prompt: seed.examplePrompt, response: seed.exampleAnswer),
    ],
    quizBlock: _quizBlock(id, seed),
    listeningBlock: _listeningBlockFor(id, seed),
    readingBlock: _readingBlockFor(id, seed),
    writingTask: _writingTaskFor(seed, requiresReview: isTeacherReviewed),
    speakingTask: _speakingTaskFor(seed, requiresReview: isTeacherReviewed),
    teacherNotes:
        'MVP content shell. Keep audio optional until final files are added.',
    rubric: isTeacherReviewed ? _productionRubric : null,
  );
}

LearningExperience _reinforcementExperience({
  required int number,
  required int order,
}) {
  final topic = _reinforcementTopics[number - 1];
  final skill = _reinforcementSkillFor(number);
  final id = 'A1-REF-${_threeDigits(number)}';

  return LearningExperience(
    id: id,
    order: order,
    title: 'Smart Reinforcement $number: $topic',
    description:
        'Short adaptive practice to strengthen recent A1 language before moving on.',
    level: 'A1',
    cefrLevel: 'A1',
    unitId: 'a1_reinforcement_${((number - 1) ~/ 5) + 1}',
    difficultyLevel: number <= 6
        ? 1
        : number <= 12
        ? 2
        : 3,
    estimatedMinutes: 8,
    requiredForCertificate: false,
    primarySkill: skill,
    secondarySkills: _secondarySkillsFor(skill),
    activityKind: ActivityKind.reinforcementActivity,
    canDoStatement: 'Review and strengthen $topic in a familiar A1 context.',
    contentVersion: a1ContentVersion,
    status: LearningExperienceStatus.published,
    lastUpdated: _a1ContentUpdatedAt,
    introductionText:
        'Use this practice when the student needs one more guided pass through $topic.',
    vocabularyBlocks: [
      VocabularyBlock(title: '$topic review words', words: _reviewWords(topic)),
    ],
    quizBlock: QuizBlock(
      questions: [
        ActivityQuestion(
          id: '${id}_q1',
          type: QuestionType.multipleChoice,
          question: 'Choose the clearest A1 sentence for $topic.',
          options: [
            'I can use $topic in a simple sentence.',
            'Yesterday is name book.',
            'How many old from?',
          ],
          correctAnswer: 'I can use $topic in a simple sentence.',
        ),
      ],
      explanations: {
        '${id}_q1': 'The correct option is a complete simple A1 sentence.',
      },
    ),
  );
}

LearningExperience _reviewExperience({
  required int number,
  required int order,
}) {
  final id = 'A1-REV-${_threeDigits(number)}';
  final coveredRange = _reviewCoveredRange(number);

  return LearningExperience(
    id: id,
    order: order,
    title: _reviewTitle(number),
    description:
        'Integrated review for listening, reading, use of English, writing and speaking.',
    level: 'A1',
    cefrLevel: 'A1',
    unitId: 'a1_mixed_review_$number',
    difficultyLevel: number <= 2
        ? 2
        : number <= 4
        ? 3
        : 4,
    estimatedMinutes: 18,
    requiredForCertificate: true,
    primarySkill: LearningSkill.mixed,
    secondarySkills: const [
      LearningSkill.listening,
      LearningSkill.reading,
      LearningSkill.vocabularyUseOfEnglish,
      LearningSkill.writing,
      LearningSkill.speaking,
    ],
    activityKind: ActivityKind.review,
    canDoStatement:
        'Connect recent A1 language across more than one skill area.',
    contentVersion: a1ContentVersion,
    status: LearningExperienceStatus.published,
    lastUpdated: _a1ContentUpdatedAt,
    introductionText:
        'This review checks whether the student can combine the work from $coveredRange.',
    quizBlock: QuizBlock(
      questions: [
        ActivityQuestion(
          id: '${id}_q1',
          type: QuestionType.multipleChoice,
          question: 'What should a mixed review include?',
          options: [
            'More than one A1 skill',
            'Only new vocabulary',
            'Only free conversation',
          ],
          correctAnswer: 'More than one A1 skill',
        ),
      ],
    ),
    speakingTask: SpeakingTask(
      speakingPrompt:
          'Answer two short questions using the language from $coveredRange.',
      maxRecordingSeconds: 60,
      requiresTeacherReview: number >= 5,
    ),
    writingTask: WritingTask(
      writingPrompt:
          'Write three short sentences using language from $coveredRange.',
      writingMode: WritingMode.freeResponse,
      minSentences: 3,
      maxSentences: 5,
      requiresTeacherReview: number >= 5,
    ),
    rubric: number >= 5 ? _productionRubric : null,
  );
}

LearningExperience _checkpointExperience({
  required int number,
  required int order,
}) {
  final id = 'A1-CHECK-${_threeDigits(number)}';
  final title = switch (number) {
    1 => 'Foundation Checkpoint',
    2 => 'Communication Checkpoint',
    _ => 'A1 Certification Readiness',
  };
  final covered = switch (number) {
    1 => 'A1-EXP-001 to A1-EXP-010',
    2 => 'A1-EXP-011 to A1-EXP-030',
    _ => 'A1-EXP-031 to A1-EXP-040',
  };

  return LearningExperience(
    id: id,
    order: order,
    title: title,
    description:
        'Progress checkpoint with teacher-visible feedback and review recommendations.',
    level: 'A1',
    cefrLevel: 'A1',
    unitId: 'a1_checkpoint_$number',
    difficultyLevel: number == 1
        ? 2
        : number == 2
        ? 3
        : 5,
    estimatedMinutes: 25,
    requiredForCertificate: true,
    primarySkill: LearningSkill.mixed,
    secondarySkills: const [
      LearningSkill.listening,
      LearningSkill.reading,
      LearningSkill.vocabularyUseOfEnglish,
      LearningSkill.writing,
      LearningSkill.speaking,
    ],
    activityKind: ActivityKind.checkpoint,
    canDoStatement: 'Show readiness after completing $covered.',
    contentVersion: a1ContentVersion,
    status: LearningExperienceStatus.published,
    lastUpdated: _a1ContentUpdatedAt,
    introductionText:
        'Checkpoint sections cover $covered and can recommend targeted review.',
    quizBlock: QuizBlock(
      questions: [
        ActivityQuestion(
          id: '${id}_q1',
          type: QuestionType.multipleChoice,
          question: 'What happens if a checkpoint is weak?',
          options: [
            'The teacher can recommend review',
            'The certificate is automatic',
            'The student skips the level',
          ],
          correctAnswer: 'The teacher can recommend review',
        ),
      ],
    ),
    rubric: _checkpointRubric,
  );
}

LearningExperience _portfolioExperience({
  required int number,
  required int order,
}) {
  final isWriting = number == 1;
  final id = 'A1-PORT-00$number';

  return LearningExperience(
    id: id,
    order: order,
    title: isWriting ? 'My A1 Story' : 'My A1 Presentation',
    description:
        'Certificate evidence task reviewed by a teacher before final certification.',
    level: 'A1',
    cefrLevel: 'A1',
    unitId: 'a1_certificate_portfolio',
    difficultyLevel: 5,
    estimatedMinutes: isWriting ? 25 : 15,
    requiredForCertificate: true,
    primarySkill: isWriting ? LearningSkill.writing : LearningSkill.speaking,
    secondarySkills: const [LearningSkill.vocabularyUseOfEnglish],
    activityKind: ActivityKind.portfolioTask,
    canDoStatement: isWriting
        ? 'Write a complete A1 text about yourself and familiar life.'
        : 'Record a 2 to 3 minute A1 presentation about yourself.',
    contentVersion: a1ContentVersion,
    status: LearningExperienceStatus.published,
    lastUpdated: _a1ContentUpdatedAt,
    introductionText:
        'This task stores evidence for the A1 certificate portfolio.',
    writingTask: isWriting
        ? const WritingTask(
            writingPrompt:
                'Write My A1 Story. Include personal information, family or one person, routine, work or study, likes and dislikes, and a future plan or goal. Minimum: 120 words or teacher-configured equivalent.',
            writingMode: WritingMode.miniProfile,
            wordBank: ['name', 'live', 'family', 'like', 'every day'],
            minimumRequirements: [
              'Include basic personal information',
              'Include family or one person',
              'Include routine',
              'Include work or study',
              'Include likes or dislikes',
              'Include a future plan or goal',
            ],
            minSentences: 10,
            maxSentences: 18,
            requiresTeacherReview: true,
          )
        : null,
    speakingTask: isWriting
        ? null
        : const SpeakingTask(
            speakingPrompt:
                'Record My A1 Presentation. Include introduction, country or city, family or one person, routine, work or study, likes and dislikes, and your English goal.',
            maxRecordingSeconds: 180,
            requiresTeacherReview: true,
          ),
    rubric: isWriting ? _writingPortfolioRubric : _speakingPortfolioRubric,
    teacherNotes:
        'Portfolio approval should be stored as certificate evidence in a later phase.',
  );
}

LearningExperience _finalExamExperience({required int order}) {
  return LearningExperience(
    id: 'A1-FINAL-EXAM',
    order: order,
    title: 'A1 Final Exam',
    description:
        'Five-section certification exam: listening, reading, use of English, writing and speaking.',
    level: 'A1',
    cefrLevel: 'A1',
    unitId: 'a1_final_exam',
    difficultyLevel: 5,
    estimatedMinutes: 50,
    requiredForCertificate: true,
    primarySkill: LearningSkill.mixed,
    secondarySkills: const [
      LearningSkill.listening,
      LearningSkill.reading,
      LearningSkill.vocabularyUseOfEnglish,
      LearningSkill.writing,
      LearningSkill.speaking,
    ],
    activityKind: ActivityKind.finalExam,
    canDoStatement:
        'Demonstrate integrated A1 ability across all certificate sections.',
    contentVersion: a1ContentVersion,
    status: LearningExperienceStatus.published,
    lastUpdated: _a1ContentUpdatedAt,
    introductionText:
        'Each final exam section has a 20 percent weight. Passing score is 75 percent.',
    listeningBlock: const ListeningBlock(
      audioTitle: 'A1 final listening section',
      audioScript:
          'Two people introduce themselves and talk about familiar everyday information.',
      audioPath: 'assets/audio/a1/a1_final_exam_listening.mp3',
      maxAudioPlays: 2,
      numberOfSpeakers: 2,
    ),
    readingBlock: const ReadingBlock(
      readingTitle: 'A1 final reading section',
      readingText:
          'Read a short profile, a simple message and a public notice. Answer basic comprehension questions.',
      readingFormat: ReadingFormat.notice,
    ),
    writingTask: const WritingTask(
      writingPrompt:
          'Write a short A1 message or profile using familiar information.',
      writingMode: WritingMode.shortMessage,
      minSentences: 5,
      maxSentences: 8,
      requiresTeacherReview: true,
    ),
    speakingTask: const SpeakingTask(
      speakingPrompt:
          'Answer short personal questions and give a prepared A1 presentation.',
      maxRecordingSeconds: 120,
      requiresTeacherReview: true,
    ),
    quizBlock: const QuizBlock(
      questions: [
        ActivityQuestion(
          id: 'A1-FINAL-EXAM_q1',
          type: QuestionType.multipleChoice,
          question: 'What is the minimum final exam score?',
          options: ['75%', '50%', '100%'],
          correctAnswer: '75%',
        ),
      ],
    ),
    rubric: _finalExamRubric,
  );
}

QuizBlock _quizBlock(String id, _CoreExperienceSeed seed) {
  return QuizBlock(
    questions: [
      ActivityQuestion(
        id: '${id}_q1',
        type: QuestionType.multipleChoice,
        question: seed.checkQuestion,
        options: seed.checkOptions,
        correctAnswer: seed.correctOption,
      ),
      ...seed.extraQuestions,
    ],
    explanations: {'${id}_q1': seed.checkExplanation},
  );
}

ListeningBlock? _listeningBlockFor(String id, _CoreExperienceSeed seed) {
  if (seed.audioScript.trim().isEmpty) {
    return null;
  }

  return ListeningBlock(
    audioTitle: '${seed.shortTopic} listening',
    audioScript: seed.audioScript,
    audioPath: seed.audioPath.isEmpty ? _plannedAudioPath(id) : seed.audioPath,
    maxAudioPlays: seed.maxAudioPlays,
    listeningQuestions: [
      ActivityQuestion(
        id: '${id}_listen_q1',
        type: QuestionType.multipleChoice,
        question: 'What is the main idea?',
        options: [
          seed.correctOption,
          seed.checkOptions[1],
          seed.checkOptions[2],
        ],
        correctAnswer: seed.correctOption,
      ),
    ],
    numberOfSpeakers: seed.numberOfSpeakers,
  );
}

ReadingBlock? _readingBlockFor(String id, _CoreExperienceSeed seed) {
  if (seed.readingText.trim().isEmpty) {
    return null;
  }

  return ReadingBlock(
    readingTitle: '${seed.shortTopic} reading',
    readingText: seed.readingText,
    readingFormat: seed.readingFormat,
    readingQuestions: [
      ActivityQuestion(
        id: '${id}_read_q1',
        type: QuestionType.multipleChoice,
        question: 'What does the text help the student understand?',
        options: [
          seed.correctOption,
          seed.checkOptions[1],
          seed.checkOptions[2],
        ],
        correctAnswer: seed.correctOption,
      ),
    ],
  );
}

WritingTask? _writingTaskFor(
  _CoreExperienceSeed seed, {
  required bool requiresReview,
}) {
  if (seed.writingPrompt.trim().isEmpty) {
    return null;
  }

  return WritingTask(
    writingPrompt: seed.writingPrompt,
    writingMode: seed.writingMode,
    wordBank: seed.words,
    minimumRequirements: seed.minimumRequirements,
    minSentences: seed.minSentences,
    maxSentences: seed.maxSentences,
    requiresTeacherReview: requiresReview,
  );
}

SpeakingTask? _speakingTaskFor(
  _CoreExperienceSeed seed, {
  required bool requiresReview,
}) {
  if (seed.speakingPrompt.trim().isEmpty) {
    return null;
  }

  return SpeakingTask(
    speakingPrompt: seed.speakingPrompt,
    maxRecordingSeconds: seed.maxRecordingSeconds,
    requiresTeacherReview: requiresReview,
  );
}

String _unitIdForCore(int number) {
  if (number <= 10) {
    return 'a1_foundation';
  }
  if (number <= 20) {
    return 'a1_personal_life';
  }
  if (number <= 30) {
    return 'a1_everyday_situations';
  }

  return 'a1_independence';
}

int _difficultyForCore(int number) {
  if (number <= 10) {
    return 1;
  }
  if (number <= 20) {
    return 2;
  }
  if (number <= 30) {
    return 3;
  }

  return 4;
}

int _estimatedMinutesForCore(int number) {
  if (number <= 10) {
    return 10;
  }
  if (number <= 30) {
    return 12;
  }

  return 15;
}

LearningSkill _reinforcementSkillFor(int number) {
  const skills = [
    LearningSkill.vocabularyUseOfEnglish,
    LearningSkill.listening,
    LearningSkill.reading,
    LearningSkill.writing,
    LearningSkill.speaking,
    LearningSkill.mixed,
  ];

  return skills[(number - 1) % skills.length];
}

List<LearningSkill> _secondarySkillsFor(LearningSkill primarySkill) {
  switch (primarySkill) {
    case LearningSkill.listening:
      return const [
        LearningSkill.vocabularyUseOfEnglish,
        LearningSkill.speaking,
      ];
    case LearningSkill.reading:
      return const [
        LearningSkill.vocabularyUseOfEnglish,
        LearningSkill.writing,
      ];
    case LearningSkill.vocabularyUseOfEnglish:
      return const [LearningSkill.reading, LearningSkill.writing];
    case LearningSkill.writing:
      return const [
        LearningSkill.vocabularyUseOfEnglish,
        LearningSkill.reading,
      ];
    case LearningSkill.speaking:
      return const [
        LearningSkill.listening,
        LearningSkill.vocabularyUseOfEnglish,
      ];
    case LearningSkill.mixed:
      return const [
        LearningSkill.listening,
        LearningSkill.reading,
        LearningSkill.vocabularyUseOfEnglish,
        LearningSkill.writing,
        LearningSkill.speaking,
      ];
  }
}

String _reviewCoveredRange(int number) {
  switch (number) {
    case 1:
      return 'A1-EXP-001 to A1-EXP-010';
    case 2:
      return 'A1-EXP-011 to A1-EXP-020';
    case 3:
      return 'A1-EXP-021 to A1-EXP-030';
    case 4:
      return 'A1-EXP-031 to A1-EXP-040';
    case 5:
      return 'the full A1 track';
    default:
      return 'final A1 exam preparation';
  }
}

String _reviewTitle(int number) {
  switch (number) {
    case 1:
      return 'A1 Foundation Review';
    case 2:
      return 'A1 Personal Life Review';
    case 3:
      return 'A1 Everyday Situations Review';
    case 4:
      return 'A1 Independence Review';
    case 5:
      return 'Complete A1 Mixed Review';
    default:
      return 'Pre Exam Review';
  }
}

List<String> _reviewWords(String topic) {
  final normalized = topic.toLowerCase();

  if (normalized.contains('family')) {
    return const ['mother', 'father', 'sister', 'brother'];
  }
  if (normalized.contains('food') || normalized.contains('ordering')) {
    return const ['menu', 'water', 'coffee', 'please'];
  }
  if (normalized.contains('directions') || normalized.contains('town')) {
    return const ['left', 'right', 'near', 'station'];
  }
  if (normalized.contains('work') || normalized.contains('study')) {
    return const ['job', 'student', 'teacher', 'office'];
  }

  return const ['hello', 'name', 'live', 'like'];
}

String _plannedAudioPath(String id) {
  return 'assets/audio/a1/${id.toLowerCase().replaceAll('-', '_')}.mp3';
}

String _threeDigits(int number) {
  return number.toString().padLeft(3, '0');
}

const Rubric _productionRubric = Rubric(
  criteria: [
    RubricCriterion(
      title: 'A1 clarity',
      description: 'Message is understandable with familiar A1 language.',
    ),
    RubricCriterion(
      title: 'Task completion',
      description: 'Student answers the prompt and includes required details.',
    ),
    RubricCriterion(
      title: 'Accuracy',
      description: 'Grammar and vocabulary are controlled enough for A1.',
    ),
  ],
);

const Rubric _checkpointRubric = Rubric(
  criteria: [
    RubricCriterion(
      title: 'Listening',
      description: '25 percent of checkpoint score.',
      maxScore: 25,
    ),
    RubricCriterion(
      title: 'Reading',
      description: '25 percent of checkpoint score.',
      maxScore: 25,
    ),
    RubricCriterion(
      title: 'Use of English',
      description: '25 percent of checkpoint score.',
      maxScore: 25,
    ),
    RubricCriterion(
      title: 'Speaking or Writing',
      description: '25 percent of checkpoint score.',
      maxScore: 25,
    ),
  ],
);

const Rubric _writingPortfolioRubric = Rubric(
  criteria: [
    RubricCriterion(
      title: 'Content',
      description: 'Required A1 life topics are included.',
      maxScore: 30,
    ),
    RubricCriterion(
      title: 'Clarity',
      description: 'The message is understandable at A1.',
      maxScore: 25,
    ),
    RubricCriterion(
      title: 'Vocabulary',
      description: 'Student uses familiar A1 vocabulary.',
      maxScore: 20,
    ),
    RubricCriterion(
      title: 'Grammar',
      description: 'Basic A1 grammar is controlled enough for meaning.',
      maxScore: 15,
    ),
    RubricCriterion(
      title: 'Task completion',
      description: 'Student follows the portfolio instructions.',
      maxScore: 10,
    ),
  ],
);

const Rubric _speakingPortfolioRubric = Rubric(
  criteria: [
    RubricCriterion(
      title: 'Communication',
      description: 'The presentation communicates the required ideas.',
      maxScore: 30,
    ),
    RubricCriterion(
      title: 'Pronunciation',
      description: 'Pronunciation is clear enough for A1 communication.',
      maxScore: 20,
    ),
    RubricCriterion(
      title: 'Fluency',
      description: 'Speech is prepared and understandable.',
      maxScore: 20,
    ),
    RubricCriterion(
      title: 'Vocabulary',
      description: 'Student uses familiar A1 vocabulary.',
      maxScore: 15,
    ),
    RubricCriterion(
      title: 'Task completion',
      description: 'Student includes the requested presentation topics.',
      maxScore: 15,
    ),
  ],
);

const Rubric _finalExamRubric = Rubric(
  criteria: [
    RubricCriterion(
      title: 'Listening',
      description: '20 percent of final exam score.',
      maxScore: 20,
    ),
    RubricCriterion(
      title: 'Reading',
      description: '20 percent of final exam score.',
      maxScore: 20,
    ),
    RubricCriterion(
      title: 'Use of English',
      description: '20 percent of final exam score.',
      maxScore: 20,
    ),
    RubricCriterion(
      title: 'Writing',
      description: '20 percent of final exam score.',
      maxScore: 20,
    ),
    RubricCriterion(
      title: 'Speaking',
      description: '20 percent of final exam score.',
      maxScore: 20,
    ),
  ],
);

const List<String> _reinforcementTopics = [
  'Verb To Be Mastery',
  'Question Builder',
  'Listening Numbers and Information',
  'Pronunciation Practice',
  'Sentence Builder',
  'Personal Information Review',
  'Routine Mastery',
  'Third Person Practice',
  'Reading Real Texts',
  'Short Messages',
  'Functional Conversations',
  'Food and Shopping',
  'Places and Directions',
  'Work Vocabulary',
  'Speaking Fluency Builder',
  'Writing Accuracy',
  'Mixed Grammar Review',
  'A1 Simulation Practice',
];

const List<_CoreExperienceSeed> _coreSeeds = [
  _CoreExperienceSeed(
    title: 'Introducing Yourself',
    shortTopic: 'introductions',
    description:
        'Use simple sentences to say hello, give your name and say your country.',
    canDoStatement: 'I can introduce myself using simple sentences.',
    primarySkill: LearningSkill.speaking,
    secondarySkills: [LearningSkill.listening, LearningSkill.reading],
    difficultyLevel: 1,
    estimatedMinutes: 10,
    words: ['hello', 'hi', 'name', 'my', 'I', 'am', 'from', 'nice to meet you'],
    introduction:
        'Students listen to and read simple introductions, then introduce themselves.',
    grammarTitle: 'Verb to be: first person',
    grammarExplanation:
        'Use I am and My name is to give basic personal information.',
    patterns: ['My name is ...', 'I am from ...', 'Nice to meet you.'],
    examples: ['My name is Anna.', 'I am from Canada.'],
    examplePrompt: 'Introduce yourself.',
    exampleAnswer: 'Hello. My name is Anna. I am from Canada.',
    checkQuestion: 'What is her name?',
    checkOptions: ['Anna', 'Maria', 'Julia'],
    correctOption: 'Anna',
    checkExplanation: 'She says, My name is Anna.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-001_q2',
        type: QuestionType.multipleChoice,
        question: 'Where is Anna from?',
        options: ['Brazil', 'Canada', 'Spain'],
        correctAnswer: 'Canada',
      ),
    ],
    audioPath: 'assets/audio/a1/a1_exp_001_meeting_anna.mp3',
    maxAudioPlays: 3,
    audioScript: '''
Hello! My name is Anna.
I am from Canada.
Nice to meet you.''',
    readingText: '''
Hello.
My name is Lucas.
I am from Brazil.
Nice to meet you.''',
    writingPrompt: 'Introduce yourself. Write your name and country.',
    writingMode: WritingMode.guidedIntroduction,
    minimumRequirements: ['greeting', 'name', 'country'],
    minSentences: 2,
    maxSentences: 4,
    speakingPrompt:
        'Introduce yourself. Say hello, your name and your country.',
    maxRecordingSeconds: 45,
  ),
  _CoreExperienceSeed(
    title: 'Greetings and Goodbyes',
    shortTopic: 'greetings',
    description: 'Understand and use greetings, simple responses and goodbyes.',
    canDoStatement: 'I can greet people and say goodbye in simple situations.',
    primarySkill: LearningSkill.listening,
    secondarySkills: [LearningSkill.speaking, LearningSkill.reading],
    difficultyLevel: 1,
    estimatedMinutes: 10,
    words: [
      'good morning',
      'good afternoon',
      'good evening',
      'hello',
      'hi',
      'goodbye',
      'see you',
      'how are you',
      'fine',
      'thanks',
    ],
    introduction:
        'Students listen to a short greeting conversation and practice polite responses.',
    grammarTitle: 'Basic greetings and simple responses',
    grammarExplanation:
        'Use fixed phrases such as How are you? and I am fine, thank you.',
    patterns: ['Good morning.', 'How are you?', 'I am fine, thanks.'],
    examples: ['Good morning. How are you?', 'Goodbye. See you later.'],
    examplePrompt: 'Create a short greeting exchange.',
    exampleAnswer: 'Hello. How are you? I am fine, thanks.',
    checkQuestion: 'What does Speaker A say first?',
    checkOptions: ['Good morning', 'Good night', 'Goodbye'],
    correctOption: 'Good morning',
    checkExplanation: 'Speaker A begins with Good morning.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-002_q2',
        type: QuestionType.multipleChoice,
        question: 'How is Speaker B?',
        options: ['Fine', 'Angry', 'Tired'],
        correctAnswer: 'Fine',
      ),
    ],
    audioPath: 'assets/audio/a1/a1_exp_002_first_conversation.mp3',
    audioScript: '''
Tom: Good morning! How are you?
Anna: I am fine, thank you. How are you?
Tom: I am good. See you later!
Anna: Goodbye!''',
    numberOfSpeakers: 2,
    writingPrompt:
        'Create a short greeting conversation with hello, how are you, and goodbye.',
    writingMode: WritingMode.freeResponse,
    minimumRequirements: ['hello', 'how are you', 'goodbye'],
    minSentences: 3,
    maxSentences: 5,
    speakingPrompt: 'Record a greeting conversation.',
    maxRecordingSeconds: 45,
  ),
  _CoreExperienceSeed(
    title: 'Countries and Nationalities',
    shortTopic: 'countries',
    description:
        'Say where you are from and understand where another person is from.',
    canDoStatement:
        'I can say where I am from and understand where other people are from.',
    primarySkill: LearningSkill.listening,
    secondarySkills: [LearningSkill.writing, LearningSkill.speaking],
    difficultyLevel: 2,
    estimatedMinutes: 10,
    words: [
      'Brazil',
      'Canada',
      'United States',
      'England',
      'Spain',
      'Italy',
      'Japan',
      'Brazilian',
      'Canadian',
      'American',
      'English',
      'Spanish',
      'Italian',
      'Japanese',
    ],
    introduction: 'Students connect country names with nationality adjectives.',
    grammarTitle: 'Be from and nationality adjectives',
    grammarExplanation: 'Use I am from plus country, or I am plus nationality.',
    patterns: ['I am from Brazil.', 'I am Brazilian.'],
    examples: ['I am from Brazil.', 'Lucas is Brazilian.'],
    examplePrompt: 'Say your country and nationality.',
    exampleAnswer: 'I am from Brazil. I am Brazilian.',
    checkQuestion: 'Lucas is from...',
    checkOptions: ['Brazil', 'Spain', 'Canada'],
    correctOption: 'Brazil',
    checkExplanation: 'Lucas says, I am from Brazil.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-003_q2',
        type: QuestionType.multipleChoice,
        question: 'Lucas is...',
        options: ['Brazilian', 'Canadian', 'Italian'],
        correctAnswer: 'Brazilian',
      ),
    ],
    audioPath: 'assets/audio/a1/a1_exp_003_countries.mp3',
    audioScript: '''
Hi! I am Lucas.
I am from Brazil.
I am Brazilian.''',
    writingPrompt: 'Write your country and nationality.',
    writingMode: WritingMode.guidedProfile,
    minimumRequirements: ['country', 'nationality'],
    minSentences: 2,
    maxSentences: 3,
    speakingPrompt: 'Say your name, country and nationality.',
    maxRecordingSeconds: 45,
  ),
  _CoreExperienceSeed(
    title: 'Numbers and Age',
    shortTopic: 'numbers and age',
    description: 'Give and understand simple information about age.',
    canDoStatement:
        'I can give and understand simple information about age and numbers.',
    primarySkill: LearningSkill.listening,
    secondarySkills: [
      LearningSkill.speaking,
      LearningSkill.vocabularyUseOfEnglish,
    ],
    difficultyLevel: 2,
    estimatedMinutes: 10,
    words: [
      'one',
      'two',
      'three',
      'ten',
      'twenty',
      'thirty',
      'forty',
      'fifty',
      'age',
      'years old',
    ],
    introduction:
        'Students listen for numbers and use the sentence I am ... years old.',
    grammarTitle: 'How old are you?',
    grammarExplanation: 'Use I am plus a number and years old to give age.',
    patterns: ['How old are you?', 'I am 25 years old.'],
    examples: ['Sarah is 25 years old.', 'I am 20 years old.'],
    examplePrompt: 'Say your age.',
    exampleAnswer: 'I am 25 years old.',
    checkQuestion: 'Sarah is...',
    checkOptions: ['15', '25', '50'],
    correctOption: '25',
    checkExplanation: 'Sarah says she is 25 years old.',
    audioPath: 'assets/audio/a1/a1_exp_004_numbers_age.mp3',
    audioScript: '''
Hi! My name is Sarah.
I am twenty-five years old.
My brother is thirty.''',
    writingPrompt: 'Write your age using the sentence I am ___ years old.',
    writingMode: WritingMode.guidedProfile,
    minimumRequirements: ['age sentence'],
    minSentences: 1,
    maxSentences: 2,
    speakingPrompt: 'Say your name and age.',
    maxRecordingSeconds: 45,
  ),
  _CoreExperienceSeed(
    title: 'Personal Information',
    shortTopic: 'personal information',
    description: 'Read a simple student profile and identify key details.',
    canDoStatement: 'I can give and understand basic personal information.',
    primarySkill: LearningSkill.reading,
    secondarySkills: [
      LearningSkill.listening,
      LearningSkill.writing,
      LearningSkill.speaking,
    ],
    difficultyLevel: 2,
    estimatedMinutes: 12,
    words: [
      'first name',
      'last name',
      'age',
      'country',
      'city',
      'phone number',
      'email',
    ],
    introduction:
        'Students read a profile and identify name, age, country and city.',
    grammarTitle: 'Personal questions and answers',
    grammarExplanation:
        'Use simple profile labels and answers for basic information.',
    patterns: ['Name: ...', 'Age: ...', 'Country: ...', 'City: ...'],
    examples: ['Name: Maria Silva', 'City: Sao Paulo'],
    examplePrompt: 'Create a simple profile.',
    exampleAnswer: 'Name: Maria Silva. Age: 22. Country: Brazil.',
    checkQuestion: 'What is her name?',
    checkOptions: ['Ana Silva', 'Maria Silva', 'Julia Santos'],
    correctOption: 'Maria Silva',
    checkExplanation: 'The profile says Name: Maria Silva.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-005_q2',
        type: QuestionType.multipleChoice,
        question: 'How old is Maria?',
        options: ['20', '21', '22'],
        correctAnswer: '22',
      ),
      ActivityQuestion(
        id: 'A1-EXP-005_q3',
        type: QuestionType.multipleChoice,
        question: 'Maria lives in...',
        options: ['Sao Paulo', 'London', 'Toronto'],
        correctAnswer: 'Sao Paulo',
      ),
    ],
    readingText: '''
Name: Maria Silva
Age: 22
Country: Brazil
City: Sao Paulo
Language: English student''',
    readingFormat: ReadingFormat.form,
    writingPrompt:
        'Create your profile with name, age, country, city and language.',
    writingMode: WritingMode.guidedProfile,
    minimumRequirements: ['name', 'age', 'country', 'city', 'language'],
    minSentences: 5,
    maxSentences: 6,
    speakingPrompt: 'Record your personal information.',
    maxRecordingSeconds: 60,
  ),
  _CoreExperienceSeed(
    title: 'Asking Basic Questions',
    shortTopic: 'basic questions',
    description: 'Ask and answer simple personal questions.',
    canDoStatement: 'I can ask and answer simple personal questions.',
    primarySkill: LearningSkill.vocabularyUseOfEnglish,
    secondarySkills: [LearningSkill.speaking],
    difficultyLevel: 2,
    estimatedMinutes: 12,
    words: ['what', 'where', 'how', 'name', 'from', 'age'],
    introduction: 'Students build basic questions with what, where and how.',
    grammarTitle: 'Question words and basic question formation',
    grammarExplanation:
        'Use what, where and how to ask for name, country and age.',
    patterns: ['What is your name?', 'Where are you from?', 'How old are you?'],
    examples: ['My name is Leo.', 'I am from Brazil.'],
    examplePrompt: 'Ask three personal questions.',
    exampleAnswer: 'What is your name? Where are you from? How old are you?',
    checkQuestion:
        'Choose the correct question for the answer My name is Mark.',
    checkOptions: [
      'Where are you from?',
      "What's your name?",
      'How old are you?',
    ],
    correctOption: "What's your name?",
    checkExplanation: 'What is your name? asks for a name.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-006_q2',
        type: QuestionType.multipleChoice,
        question: 'Answer Where are you from?',
        options: ["I'm from Brazil.", "I'm 25.", 'My name is Brazil.'],
        correctAnswer: "I'm from Brazil.",
      ),
    ],
    audioPath: 'assets/audio/a1/a1_exp_006_basic_questions.mp3',
    audioScript: '''
Anna: Hello! What is your name?
Leo: My name is Leo.
Anna: Where are you from?
Leo: I am from Brazil.
Anna: How old are you?
Leo: I am twenty years old.''',
    numberOfSpeakers: 2,
    speakingPrompt:
        "Answer: What's your name? Where are you from? How old are you?",
    maxRecordingSeconds: 60,
  ),
  _CoreExperienceSeed(
    title: 'People Around Me',
    shortTopic: 'people around me',
    description:
        'Describe people around you with simple sentences and possessives.',
    canDoStatement: 'I can describe people around me using simple sentences.',
    primarySkill: LearningSkill.vocabularyUseOfEnglish,
    secondarySkills: [
      LearningSkill.reading,
      LearningSkill.writing,
      LearningSkill.speaking,
    ],
    difficultyLevel: 2,
    estimatedMinutes: 12,
    words: [
      'mother',
      'father',
      'brother',
      'sister',
      'friend',
      'teacher',
      'student',
      'he',
      'she',
      'his',
      'her',
    ],
    introduction:
        'Students read about one person and write or speak about someone they know.',
    grammarTitle: 'Third person basics and possessives',
    grammarExplanation:
        'Use he, she, his and her to talk about another person.',
    patterns: ['This is my friend.', 'His name is ...', 'He is ...'],
    examples: ['His name is Daniel.', 'He is from Brazil.'],
    examplePrompt: 'Describe one person.',
    exampleAnswer: 'This is my friend. His name is Daniel.',
    checkQuestion: 'His name is...',
    checkOptions: ['Daniel', 'Lucas', 'Pedro'],
    correctOption: 'Daniel',
    checkExplanation: 'The text says His name is Daniel.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-007_q2',
        type: QuestionType.multipleChoice,
        question: 'Daniel is...',
        options: ['24', '30', '40'],
        correctAnswer: '24',
      ),
    ],
    readingText: '''
This is my friend.
His name is Daniel.
He is 24 years old.
He is from Brazil.''',
    writingPrompt:
        'Write about one person using This is my..., His/Her name is..., He/She is...',
    writingMode: WritingMode.guidedFamilyDescription,
    minimumRequirements: ['person', 'name', 'age or country'],
    minSentences: 3,
    maxSentences: 5,
    speakingPrompt: 'Talk about one person you know.',
    maxRecordingSeconds: 60,
  ),
  _CoreExperienceSeed(
    title: 'My Basic Profile',
    shortTopic: 'basic profile',
    description: 'Create a simple personal profile with familiar A1 language.',
    canDoStatement: 'I can create a simple personal profile.',
    primarySkill: LearningSkill.writing,
    secondarySkills: [LearningSkill.speaking],
    difficultyLevel: 3,
    estimatedMinutes: 15,
    words: [
      'hello',
      'name',
      'country',
      'age',
      'city',
      'job',
      'student',
      'teacher',
    ],
    introduction: 'Students use a model text to write their own basic profile.',
    grammarTitle: 'Profile sentences and verb to be review',
    grammarExplanation: 'Use short be sentences to create a complete profile.',
    patterns: ['My name is ...', 'I am from ...', 'I am ... years old.'],
    examples: [
      'Hello.',
      'My name is Tom.',
      "I'm from Canada.",
      "I'm 30 years old.",
      "I'm a teacher.",
    ],
    examplePrompt: 'Read the model text and create your own profile.',
    exampleAnswer:
        'Hello. My name is Tom. I am from Canada. I am 30 years old. I am a teacher.',
    checkQuestion: 'What information belongs in a basic profile?',
    checkOptions: ['Name and country', 'Only prices', 'Only directions'],
    correctOption: 'Name and country',
    checkExplanation: 'A basic profile includes personal information.',
    readingText: '''
Hello.
My name is Tom.
I'm from Canada.
I'm 30 years old.
I'm a teacher.''',
    writingPrompt:
        'Create your own profile with greeting, name, country, age and city/job.',
    writingMode: WritingMode.guidedProfile,
    minimumRequirements: ['greeting', 'name', 'country', 'age', 'city or job'],
    minSentences: 5,
    maxSentences: 5,
    speakingPrompt: 'Record your profile.',
    maxRecordingSeconds: 90,
  ),
  _CoreExperienceSeed(
    title: 'Simple Conversation',
    shortTopic: 'simple conversation',
    description: 'Participate in a very simple personal conversation.',
    canDoStatement: 'I can participate in a very simple conversation.',
    primarySkill: LearningSkill.speaking,
    secondarySkills: [LearningSkill.listening],
    difficultyLevel: 3,
    estimatedMinutes: 12,
    words: ['hi', 'name', 'nice to meet you', 'from'],
    introduction:
        'Students listen to a short conversation and answer personal questions.',
    grammarTitle: 'Personal question review',
    grammarExplanation:
        'Use name and country questions in a short conversation.',
    patterns: ["What's your name?", 'Where are you from?', 'Nice to meet you.'],
    examples: ['My name is Sofia.', "I'm from Spain."],
    examplePrompt: 'Answer two personal questions.',
    exampleAnswer: 'My name is Sofia. I am from Spain.',
    checkQuestion: 'Her name is...',
    checkOptions: ['Sofia', 'Anna', 'Maria'],
    correctOption: 'Sofia',
    checkExplanation: 'Speaker B says, My name is Sofia.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-009_q2',
        type: QuestionType.multipleChoice,
        question: 'She is from...',
        options: ['Brazil', 'Spain', 'Canada'],
        correctAnswer: 'Spain',
      ),
    ],
    audioPath: 'assets/audio/a1/a1_exp_009_simple_conversation.mp3',
    audioScript: '''
Tom: Hi! What is your name?
Sarah: My name is Sofia.
Tom: Nice to meet you.
Sarah: Nice to meet you too.
Tom: Where are you from?
Sarah: I am from Spain.''',
    numberOfSpeakers: 2,
    speakingPrompt: "Answer: What's your name? Where are you from?",
    maxRecordingSeconds: 60,
  ),
  _CoreExperienceSeed(
    title: 'Foundation Challenge',
    shortTopic: 'foundation challenge',
    description:
        'Integrated challenge for introductions and basic personal information.',
    canDoStatement:
        'I can introduce myself and exchange basic personal information.',
    primarySkill: LearningSkill.mixed,
    secondarySkills: [
      LearningSkill.listening,
      LearningSkill.reading,
      LearningSkill.writing,
      LearningSkill.speaking,
    ],
    difficultyLevel: 3,
    estimatedMinutes: 15,
    words: ['name', 'age', 'from', 'live', 'country', 'city'],
    introduction:
        'Students complete an integrated foundation challenge across the core skills.',
    grammarTitle: 'Foundation A1 review',
    grammarExplanation:
        'Use be, from, age and live to exchange basic personal information.',
    patterns: ['My name is ...', 'I am ... years old.', 'I live in ...'],
    examples: ['My name is Alex.', 'I live in Toronto.'],
    examplePrompt: 'Introduce yourself in five sentences.',
    exampleAnswer:
        'Hello. My name is Alex. I am 28 years old. I am from Canada. I live in Toronto.',
    checkQuestion: 'What is his name?',
    checkOptions: ['Alex', 'Mark', 'John'],
    correctOption: 'Alex',
    checkExplanation: 'The speaker says, My name is Alex.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-010_q2',
        type: QuestionType.multipleChoice,
        question: 'How old is Alex?',
        options: ['18', '28', '38'],
        correctAnswer: '28',
      ),
      ActivityQuestion(
        id: 'A1-EXP-010_q3',
        type: QuestionType.multipleChoice,
        question: 'Where is Alex from?',
        options: ['Canada', 'Brazil', 'Spain'],
        correctAnswer: 'Canada',
      ),
    ],
    audioPath: 'assets/audio/a1/a1_exp_010_foundation_challenge.mp3',
    audioScript: '''
Hello. My name is Alex.
I am twenty-eight years old.
I am from Canada.
I live in Toronto.
My sister lives in Vancouver.''',
    writingPrompt: 'Introduce yourself in 5 sentences.',
    writingMode: WritingMode.guidedIntroduction,
    minimumRequirements: ['name', 'age', 'country', 'city or place'],
    minSentences: 5,
    maxSentences: 6,
    speakingPrompt: 'Tell us about yourself.',
    maxRecordingSeconds: 90,
  ),
  _CoreExperienceSeed(
    title: 'My Family',
    shortTopic: 'family',
    description: 'Use family words and possessives in a short description.',
    canDoStatement: 'I can describe my family using simple A1 sentences.',
    primarySkill: LearningSkill.vocabularyUseOfEnglish,
    secondarySkills: [
      LearningSkill.listening,
      LearningSkill.reading,
      LearningSkill.writing,
      LearningSkill.speaking,
    ],
    difficultyLevel: 2,
    estimatedMinutes: 12,
    words: [
      'family',
      'mother',
      'father',
      'sister',
      'brother',
      'parents',
      'children',
      'my',
      'his',
      'her',
    ],
    introduction:
        'Students connect family vocabulary to possessives and short family descriptions.',
    grammarTitle: 'Possessives with family words',
    grammarExplanation:
        'Use my, his and her before family words. Use have to talk about family members.',
    patterns: ['This is my mother.', 'Her name is Ana.', 'I have one brother.'],
    examples: ['This is my father.', 'His name is Leo.', 'I have one sister.'],
    examplePrompt: 'Describe one family member.',
    exampleAnswer: 'This is my sister. Her name is Sofia.',
    checkQuestion: 'Who is Ana?',
    checkOptions: ['The mother', 'The brother', 'The teacher'],
    correctOption: 'The mother',
    checkExplanation: 'The speaker says, My mother is Ana.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-011_q2',
        type: QuestionType.multipleChoice,
        question: 'How many brothers does Emma have?',
        options: ['One', 'Two', 'Zero'],
        correctAnswer: 'One',
      ),
      ActivityQuestion(
        id: 'A1-EXP-011_q3',
        type: QuestionType.multipleChoice,
        question: 'Which sentence uses a possessive?',
        options: ['Her name is Ana.', 'Name Ana is.', 'Ana name her.'],
        correctAnswer: 'Her name is Ana.',
      ),
    ],
    audioPath: 'assets/audio/a1/a1_exp_011_my_family.mp3',
    audioScript: '''
Hi, I'm Emma.
This is my family.
My mother is Ana.
My father is Mark.
I have one brother.
His name is Leo. He is twelve.''',
    readingText: '''
My name is Emma.
I live with my parents.
My mother is Ana and my father is Mark.
I have one brother.
His name is Leo.''',
    writingPrompt: 'Write four sentences about your family.',
    writingMode: WritingMode.guidedFamilyDescription,
    minimumRequirements: [
      'one family word',
      'one possessive',
      'one description',
      'one have sentence',
    ],
    minSentences: 4,
    maxSentences: 6,
    speakingPrompt: 'Describe your family in four simple sentences.',
    maxRecordingSeconds: 60,
  ),
  _CoreExperienceSeed(
    title: 'Describing People',
    shortTopic: 'describing people',
    description: 'Use simple adjectives with he is and she is.',
    primarySkill: LearningSkill.speaking,
    secondarySkills: [
      LearningSkill.listening,
      LearningSkill.reading,
      LearningSkill.writing,
    ],
    difficultyLevel: 2,
    estimatedMinutes: 12,
    canDoStatement: 'I can describe people with simple adjectives.',
    words: [
      'tall',
      'short',
      'young',
      'kind',
      'funny',
      'friendly',
      'teacher',
      'student',
    ],
    introduction:
        'Students use he is and she is to describe people in clear short sentences.',
    grammarTitle: 'He is and she is',
    grammarExplanation:
        'Use he is or she is with a role or adjective. Add a or an before jobs and roles.',
    patterns: ['He is tall.', 'She is kind.', 'He is a student.'],
    examples: ['She is friendly.', 'He is a teacher.'],
    examplePrompt: 'Describe one person.',
    exampleAnswer: 'She is my friend. She is kind.',
    checkQuestion: 'Who is Daniel?',
    checkOptions: ['A friend', 'A father', 'A doctor'],
    correctOption: 'A friend',
    checkExplanation: 'The speaker says Daniel is my friend.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-012_q2',
        type: QuestionType.multipleChoice,
        question: 'Which adjective describes Daniel?',
        options: ['Tall', 'Old', 'Angry'],
        correctAnswer: 'Tall',
      ),
      ActivityQuestion(
        id: 'A1-EXP-012_q3',
        type: QuestionType.multipleChoice,
        question: 'Which sentence is correct?',
        options: ['She is funny.', 'She funny is.', 'She are funny.'],
        correctAnswer: 'She is funny.',
      ),
    ],
    audioPath: 'assets/audio/a1/a1_exp_012_describing_people.mp3',
    audioScript: '''
This is Daniel.
He is my friend.
He is tall and kind.
This is Sofia.
She is short and funny.
She is a student.''',
    numberOfSpeakers: 1,
    readingText: '''
Daniel is my friend.
He is tall and kind.
Sofia is my sister.
She is short, funny and friendly.''',
    writingPrompt: 'Write four sentences describing two people you know.',
    writingMode: WritingMode.guidedProfile,
    minimumRequirements: [
      'one he is sentence',
      'one she is sentence',
      'two adjectives',
    ],
    minSentences: 4,
    maxSentences: 6,
    speakingPrompt: 'Describe two people you know using he is and she is.',
    maxRecordingSeconds: 60,
  ),
  _CoreExperienceSeed(
    title: 'Things I Like',
    shortTopic: 'likes and dislikes',
    description: 'Talk about likes, dislikes and favorite things.',
    canDoStatement: 'I can say what I like and do not like.',
    primarySkill: LearningSkill.speaking,
    secondarySkills: [
      LearningSkill.listening,
      LearningSkill.reading,
      LearningSkill.writing,
    ],
    difficultyLevel: 2,
    estimatedMinutes: 12,
    words: [
      'like',
      'love',
      'do not like',
      'favorite',
      'music',
      'movies',
      'sports',
      'books',
      'coffee',
      'food',
    ],
    introduction:
        'Students practice simple preference sentences with familiar nouns.',
    grammarTitle: 'Like and do not like',
    grammarExplanation:
        'Use like or do not like before a noun. Use favorite to name the best choice.',
    patterns: [
      'I like music.',
      'I do not like coffee.',
      'My favorite sport is soccer.',
    ],
    examples: ['I like books.', 'I love movies.', 'I do not like coffee.'],
    examplePrompt: 'Say one thing you like.',
    exampleAnswer: 'I like music.',
    checkQuestion: 'What does Maya like?',
    checkOptions: ['Music', 'Coffee', 'Math'],
    correctOption: 'Music',
    checkExplanation: 'Maya says, I like music.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-013_q2',
        type: QuestionType.multipleChoice,
        question: 'What does Maya not like?',
        options: ['Coffee', 'Books', 'Movies'],
        correctAnswer: 'Coffee',
      ),
      ActivityQuestion(
        id: 'A1-EXP-013_q3',
        type: QuestionType.multipleChoice,
        question: 'Which sentence gives a preference?',
        options: ['I like books.', 'I am from Chile.', 'He is my brother.'],
        correctAnswer: 'I like books.',
      ),
    ],
    audioPath: 'assets/audio/a1/a1_exp_013_things_i_like.mp3',
    audioScript: '''
Hi, I'm Maya.
I like music and books.
I love movies.
I don't like coffee.
My favorite sport is soccer.''',
    readingText: '''
Maya likes music, books and movies.
She does not like coffee.
Her favorite sport is soccer.
Her favorite food is rice.''',
    writingPrompt:
        'Write four sentences about things you like and do not like.',
    writingMode: WritingMode.guidedPreferences,
    minimumRequirements: [
      'two things you like',
      'one thing you do not like',
      'one favorite thing',
    ],
    minSentences: 4,
    maxSentences: 6,
    speakingPrompt: 'Say two things you like and one thing you do not like.',
    maxRecordingSeconds: 60,
  ),
  _CoreExperienceSeed(
    title: 'My Daily Routine',
    shortTopic: 'daily routine',
    description: 'Describe a simple daily routine with present verbs.',
    canDoStatement: 'I can talk about my daily routine.',
    primarySkill: LearningSkill.listening,
    secondarySkills: [
      LearningSkill.vocabularyUseOfEnglish,
      LearningSkill.reading,
      LearningSkill.writing,
      LearningSkill.speaking,
    ],
    difficultyLevel: 2,
    estimatedMinutes: 12,
    words: [
      'wake up',
      'eat breakfast',
      'work',
      'study',
      'go home',
      'sleep',
      'morning',
      'night',
    ],
    introduction:
        'Students listen for daily actions and use simple present verbs for routines.',
    grammarTitle: 'Simple present for routines',
    grammarExplanation:
        'Use the base verb with I to talk about regular actions.',
    patterns: [
      'I wake up at seven.',
      'I work in the morning.',
      'I study English at night.',
    ],
    examples: ['I eat breakfast at seven thirty.', 'I sleep at ten.'],
    examplePrompt: 'Say one routine action.',
    exampleAnswer: 'I wake up at seven.',
    checkQuestion: 'What time does Leo wake up?',
    checkOptions: ['Seven', 'Eight', 'Ten'],
    correctOption: 'Seven',
    checkExplanation: 'Leo says, I wake up at seven.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-014_q2',
        type: QuestionType.multipleChoice,
        question: 'When does Leo study English?',
        options: ['At night', 'In the afternoon', 'In the morning'],
        correctAnswer: 'At night',
      ),
      ActivityQuestion(
        id: 'A1-EXP-014_q3',
        type: QuestionType.multipleChoice,
        question: 'Which phrase is a daily routine action?',
        options: ['Eat breakfast', 'Blue chair', 'How much'],
        correctAnswer: 'Eat breakfast',
      ),
    ],
    audioPath: 'assets/audio/a1/a1_exp_014_daily_routine.mp3',
    audioScript: '''
My name is Leo.
I wake up at seven.
I eat breakfast at seven thirty.
I work in the morning.
I study English at night.
I sleep at ten.''',
    readingText: '''
Leo wakes up at seven.
He eats breakfast at seven thirty.
He works in the morning.
He studies English at night.''',
    writingPrompt: 'Write five sentences about your daily routine.',
    writingMode: WritingMode.guidedRoutine,
    minimumRequirements: [
      'wake up',
      'breakfast or food',
      'work or study',
      'night action',
    ],
    minSentences: 5,
    maxSentences: 7,
    speakingPrompt: 'Describe your daily routine from morning to night.',
    maxRecordingSeconds: 75,
  ),
  _CoreExperienceSeed(
    title: 'Days and Time',
    shortTopic: 'days and time',
    description: 'Use days and simple time expressions with on, at and in.',
    canDoStatement: 'I can talk about days and times for simple activities.',
    primarySkill: LearningSkill.reading,
    secondarySkills: [
      LearningSkill.listening,
      LearningSkill.vocabularyUseOfEnglish,
      LearningSkill.writing,
      LearningSkill.speaking,
    ],
    difficultyLevel: 2,
    estimatedMinutes: 12,
    words: [
      'Monday',
      'Tuesday',
      'Wednesday',
      'weekend',
      'morning',
      'afternoon',
      'evening',
      'at',
      'on',
      'in',
    ],
    introduction:
        'Students read and hear a simple weekly schedule with days and parts of the day.',
    grammarTitle: 'On, at and in for time',
    grammarExplanation:
        'Use on with days, at with clock times and in with parts of the day.',
    patterns: [
      'on Monday',
      "at seven o'clock",
      'in the morning',
      'in the evening',
    ],
    examples: ['I study on Monday.', 'I work in the morning.'],
    examplePrompt: 'Say one activity with a day.',
    exampleAnswer: 'I study on Tuesday.',
    checkQuestion: 'When is the English class?',
    checkOptions: ['On Monday', 'On Sunday', 'On Friday'],
    correctOption: 'On Monday',
    checkExplanation: 'The schedule says English class: Monday at 7:00.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-015_q2',
        type: QuestionType.multipleChoice,
        question: 'Which phrase is correct?',
        options: ['in the morning', 'on the morning', 'at the morning'],
        correctAnswer: 'in the morning',
      ),
      ActivityQuestion(
        id: 'A1-EXP-015_q3',
        type: QuestionType.multipleChoice,
        question: 'What time is soccer?',
        options: ['At 6:00', 'At 9:00', 'At 12:00'],
        correctAnswer: 'At 6:00',
      ),
    ],
    audioScript: '''
Hi, I'm Paulo.
On Monday, I have English class at seven.
On Wednesday, I work in the morning.
On Saturday, I play soccer at six.
On Sunday, I relax in the evening.''',
    readingText: '''
Weekly plan
Monday 7:00 - English class
Wednesday morning - work
Saturday 6:00 - soccer
Sunday evening - relax at home''',
    readingFormat: ReadingFormat.form,
    writingPrompt: 'Write four sentences about your week with days and times.',
    writingMode: WritingMode.guidedSchedule,
    minimumRequirements: ['one on phrase', 'one at phrase', 'one in phrase'],
    minSentences: 4,
    maxSentences: 6,
    speakingPrompt: 'Say three activities from your week with days or times.',
    maxRecordingSeconds: 60,
  ),
  _CoreExperienceSeed(
    title: 'My Activities',
    shortTopic: 'weekly activities',
    description: 'Talk about weekly activities and frequency.',
    primarySkill: LearningSkill.writing,
    secondarySkills: [
      LearningSkill.listening,
      LearningSkill.reading,
      LearningSkill.vocabularyUseOfEnglish,
      LearningSkill.speaking,
    ],
    difficultyLevel: 2,
    estimatedMinutes: 12,
    canDoStatement: 'I can describe my weekly activities.',
    words: [
      'play',
      'watch',
      'read',
      'study',
      'go',
      'every day',
      'sometimes',
      'on weekends',
      'usually',
    ],
    introduction:
        'Students combine weekly activities with simple frequency expressions.',
    grammarTitle: 'Frequency with simple present',
    grammarExplanation:
        'Use frequency words before or after the verb phrase to say how often something happens.',
    patterns: [
      'I study every day.',
      'I sometimes watch movies.',
      'I play soccer on weekends.',
    ],
    examples: ['I usually read at night.', 'I go to the gym on Saturday.'],
    examplePrompt: 'Write one weekly activity.',
    exampleAnswer: 'I study English every day.',
    checkQuestion: 'What does Bruno do every day?',
    checkOptions: ['Study English', 'Play soccer', 'Watch movies'],
    correctOption: 'Study English',
    checkExplanation: 'Bruno says, I study English every day.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-016_q2',
        type: QuestionType.multipleChoice,
        question: 'When does Bruno play soccer?',
        options: ['On weekends', 'Every morning', 'On Monday'],
        correctAnswer: 'On weekends',
      ),
      ActivityQuestion(
        id: 'A1-EXP-016_q3',
        type: QuestionType.multipleChoice,
        question: 'Which sentence uses frequency?',
        options: [
          'I sometimes watch movies.',
          'I am from Peru.',
          'This is my sister.',
        ],
        correctAnswer: 'I sometimes watch movies.',
      ),
    ],
    audioPath: 'assets/audio/a1/a1_exp_016_my_activities.mp3',
    audioScript: '''
I'm Bruno.
I study English every day.
I read at night.
I sometimes watch movies.
I play soccer on weekends.''',
    readingText: '''
Bruno studies English every day.
He reads at night.
He sometimes watches movies.
He plays soccer on weekends.''',
    writingPrompt: 'Write five sentences about your weekly activities.',
    writingMode: WritingMode.guidedRoutine,
    minimumRequirements: [
      'one every day sentence',
      'one sometimes sentence',
      'one weekend activity',
    ],
    minSentences: 5,
    maxSentences: 7,
    speakingPrompt: 'Talk about three activities you do every week.',
    maxRecordingSeconds: 75,
  ),
  _CoreExperienceSeed(
    title: 'Simple Present Questions',
    shortTopic: 'simple present questions',
    description: 'Ask and answer simple present questions with do.',
    canDoStatement: 'I can ask and answer Do you questions.',
    primarySkill: LearningSkill.vocabularyUseOfEnglish,
    secondarySkills: [
      LearningSkill.listening,
      LearningSkill.reading,
      LearningSkill.writing,
      LearningSkill.speaking,
    ],
    difficultyLevel: 2,
    estimatedMinutes: 12,
    words: ['do', 'you', 'yes', 'no', 'study', 'work', 'like', 'play'],
    introduction: 'Students build simple present questions and short answers.',
    grammarTitle: 'Do you...? Yes, I do. No, I do not.',
    grammarExplanation:
        'Start yes/no questions with Do you. Answer with Yes, I do or No, I do not.',
    patterns: ['Do you study English?', 'Yes, I do.', 'No, I do not.'],
    examples: ['Do you like music?', 'Do you work on Monday?'],
    examplePrompt: 'Ask one Do you question.',
    exampleAnswer: 'Do you study English?',
    checkQuestion: 'Which answer is correct for Do you study English?',
    checkOptions: ['Yes, I do.', 'Yes, I am.', 'Yes, I have.'],
    correctOption: 'Yes, I do.',
    checkExplanation: 'A Do you question can be answered with Yes, I do.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-017_q2',
        type: QuestionType.multipleChoice,
        question: 'Which question is correct?',
        options: [
          'Do you like music?',
          'You do like music?',
          'Are you like music?',
        ],
        correctAnswer: 'Do you like music?',
      ),
      ActivityQuestion(
        id: 'A1-EXP-017_q3',
        type: QuestionType.multipleChoice,
        question: 'What does Sam not do?',
        options: ['Play soccer', 'Study English', 'Like music'],
        correctAnswer: 'Play soccer',
      ),
    ],
    audioPath: 'assets/audio/a1/a1_exp_017_present_questions.mp3',
    audioScript: '''
Anna: Do you study English?
Leo: Yes, I do.
Anna: Do you like music?
Leo: Yes, I do.
Anna: Do you play soccer?
Leo: No, I don't.''',
    numberOfSpeakers: 2,
    readingText: '''
A: Do you study English?
B: Yes, I do.
A: Do you play soccer?
B: No, I do not.''',
    readingFormat: ReadingFormat.dialogue,
    writingPrompt: 'Write four Do you questions and short answers.',
    writingMode: WritingMode.freeResponse,
    minimumRequirements: [
      'two Do you questions',
      'one yes answer',
      'one no answer',
    ],
    minSentences: 4,
    maxSentences: 8,
    speakingPrompt: 'Ask and answer three Do you questions.',
    maxRecordingSeconds: 75,
  ),
  _CoreExperienceSeed(
    title: 'My Life Story',
    shortTopic: 'personal life story',
    description: 'Connect personal details, family, likes and routine.',
    canDoStatement: 'I can read, write and say a short personal life story.',
    primarySkill: LearningSkill.mixed,
    secondarySkills: [
      LearningSkill.reading,
      LearningSkill.writing,
      LearningSkill.speaking,
      LearningSkill.listening,
    ],
    difficultyLevel: 3,
    estimatedMinutes: 15,
    words: [
      'life',
      'family',
      'live',
      'study',
      'work',
      'like',
      'every day',
      'weekend',
    ],
    introduction:
        'Students integrate personal information into one simple A1 life story.',
    grammarTitle: 'A1 sentence connection',
    grammarExplanation:
        'Use short simple present sentences to connect name, home, family, likes and routine.',
    patterns: [
      'My name is ...',
      'I live in ...',
      'I have ...',
      'I study ...',
      'I like ...',
    ],
    examples: [
      'My name is Carla.',
      'I live in Lima.',
      'I study English every day.',
    ],
    examplePrompt: 'Write the start of a life story.',
    exampleAnswer: 'My name is Carla. I live in Lima.',
    checkQuestion: 'Where does Carla live?',
    checkOptions: ['Lima', 'Toronto', 'Madrid'],
    correctOption: 'Lima',
    checkExplanation: 'The text says, I live in Lima.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-018_q2',
        type: QuestionType.multipleChoice,
        question: 'What does Carla study every day?',
        options: ['English', 'Music', 'Soccer'],
        correctAnswer: 'English',
      ),
      ActivityQuestion(
        id: 'A1-EXP-018_q3',
        type: QuestionType.multipleChoice,
        question: 'What does Carla like?',
        options: ['Books and music', 'Coffee and buses', 'Prices and shops'],
        correctAnswer: 'Books and music',
      ),
    ],
    audioScript: '''
My name is Carla.
I'm twenty-three years old.
I live in Lima.
I have one sister.
I study English every day.
I like books and music.''',
    readingText: '''
My name is Carla.
I am 23 years old and I live in Lima.
I have one sister.
I study English every day.
On weekends, I read books and listen to music.''',
    writingPrompt: 'Write a short life story about yourself.',
    writingMode: WritingMode.freeResponse,
    minimumRequirements: [
      'name',
      'city or country',
      'family detail',
      'routine or activity',
      'like or favorite thing',
    ],
    minSentences: 6,
    maxSentences: 8,
    speakingPrompt:
        'Tell your short life story with your name, home, family, routine and likes.',
    maxRecordingSeconds: 90,
  ),
  _CoreExperienceSeed(
    title: 'Talking About Someone',
    shortTopic: 'third person routines',
    description: 'Talk about another person using third person verbs.',
    canDoStatement: 'I can describe another person with he or she.',
    primarySkill: LearningSkill.listening,
    secondarySkills: [
      LearningSkill.vocabularyUseOfEnglish,
      LearningSkill.reading,
      LearningSkill.writing,
      LearningSkill.speaking,
    ],
    difficultyLevel: 3,
    estimatedMinutes: 12,
    words: ['he', 'she', 'lives', 'works', 'studies', 'likes', 'has', 'goes'],
    introduction:
        'Students notice third person -s in simple present sentences about another person.',
    grammarTitle: 'Third person simple present',
    grammarExplanation:
        'Use lives, works, studies, likes, has and goes with he or she.',
    patterns: [
      'He lives in Quito.',
      'She works in a school.',
      'He likes music.',
    ],
    examples: ['She studies English.', 'He has one brother.'],
    examplePrompt: 'Talk about one person.',
    exampleAnswer: 'She lives in Quito. She studies English.',
    checkQuestion: 'Where does Nina live?',
    checkOptions: ['Quito', 'Lima', 'Toronto'],
    correctOption: 'Quito',
    checkExplanation: 'The speaker says, Nina lives in Quito.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-019_q2',
        type: QuestionType.multipleChoice,
        question: 'What does Nina do?',
        options: [
          'She works in a school.',
          'She plays soccer.',
          'She sells coffee.',
        ],
        correctAnswer: 'She works in a school.',
      ),
      ActivityQuestion(
        id: 'A1-EXP-019_q3',
        type: QuestionType.multipleChoice,
        question: 'Which sentence is correct?',
        options: ['She likes music.', 'She like music.', 'She liking music.'],
        correctAnswer: 'She likes music.',
      ),
    ],
    audioPath: 'assets/audio/a1/a1_exp_019_talking_about_someone.mp3',
    audioScript: '''
This is Nina.
She lives in Quito.
She works in a school.
She studies English at night.
She likes music.
She has one brother.''',
    readingText: '''
Nina lives in Quito.
She works in a school and studies English at night.
She likes music.
She has one brother.''',
    writingPrompt: 'Write five sentences about a friend or family member.',
    writingMode: WritingMode.guidedProfile,
    minimumRequirements: [
      'one he or she sentence',
      'one lives or works sentence',
      'one likes sentence',
    ],
    minSentences: 5,
    maxSentences: 7,
    speakingPrompt: 'Talk about one person you know using he or she.',
    maxRecordingSeconds: 75,
  ),
  _CoreExperienceSeed(
    title: 'Personal Life Challenge',
    shortTopic: 'personal life challenge',
    description:
        'Integrated challenge for family, descriptions, likes, routines and simple present.',
    canDoStatement:
        'I can understand and share basic personal life information.',
    primarySkill: LearningSkill.mixed,
    secondarySkills: [
      LearningSkill.listening,
      LearningSkill.reading,
      LearningSkill.vocabularyUseOfEnglish,
      LearningSkill.writing,
      LearningSkill.speaking,
    ],
    difficultyLevel: 3,
    estimatedMinutes: 18,
    words: [
      'family',
      'friend',
      'routine',
      'like',
      'study',
      'work',
      'every day',
      'on weekends',
      'he',
      'she',
    ],
    introduction:
        'Students complete an integrated Personal Life block challenge with listening, reading, writing and speaking.',
    grammarTitle: 'Personal life review',
    grammarExplanation:
        'Review possessives, adjectives, likes, routines, Do you questions and third person verbs.',
    patterns: [
      'I have one brother.',
      'She is kind.',
      'I like books.',
      'Do you study English?',
      'He works in a store.',
    ],
    examples: [
      'My name is Rafael.',
      'I study English every day.',
      'My sister likes music.',
    ],
    examplePrompt: 'Answer a personal life question.',
    exampleAnswer: 'I study English at night.',
    checkQuestion: 'What does Rafael study every day?',
    checkOptions: ['English', 'Music', 'Math'],
    correctOption: 'English',
    checkExplanation: 'Rafael says, I study English every day.',
    extraQuestions: [
      ActivityQuestion(
        id: 'A1-EXP-020_q2',
        type: QuestionType.multipleChoice,
        question: 'Who is Clara?',
        options: ['His sister', 'His teacher', 'His mother'],
        correctAnswer: 'His sister',
      ),
      ActivityQuestion(
        id: 'A1-EXP-020_q3',
        type: QuestionType.multipleChoice,
        question: 'What does Clara like?',
        options: ['Music', 'Coffee', 'Shopping'],
        correctAnswer: 'Music',
      ),
      ActivityQuestion(
        id: 'A1-EXP-020_q4',
        type: QuestionType.multipleChoice,
        question: 'Which question fits the challenge grammar?',
        options: [
          'Do you work on Monday?',
          'You work Monday?',
          'Are work Monday?',
        ],
        correctAnswer: 'Do you work on Monday?',
      ),
    ],
    audioPath: 'assets/audio/a1/a1_exp_020_personal_life_challenge.mp3',
    audioScript: '''
My name is Rafael.
I live in Bogota.
I work in the morning and study English every day.
I have one sister.
Her name is Clara.
She is friendly and she likes music.
On weekends, we play soccer.''',
    readingText: '''
Rafael is from Colombia.
He lives in Bogota.
He works in the morning and studies English every day.
His sister Clara is friendly.
She likes music.
On weekends, they play soccer together.''',
    writingPrompt:
        'Write a personal life profile. Include family, likes, routine and one sentence about another person.',
    writingMode: WritingMode.freeResponse,
    minimumRequirements: [
      'family detail',
      'like or favorite thing',
      'routine sentence',
      'one he or she sentence',
    ],
    minSentences: 6,
    maxSentences: 9,
    speakingPrompt:
        'Give a short personal life presentation about yourself and one person you know.',
    maxRecordingSeconds: 120,
  ),
  _CoreExperienceSeed(
    title: 'Order a Drink',
    shortTopic: 'ordering',
    description: 'Ask for a drink politely in a cafe.',
    canDoStatement: 'Order food or drink using simple polite language.',
    primarySkill: LearningSkill.speaking,
    words: ['coffee', 'water', 'please', 'thank you'],
    introduction: 'Students practice a guided cafe order.',
    grammarTitle: 'I would like',
    grammarExplanation: 'Use I would like for polite ordering.',
    patterns: ['I would like water, please.', 'Can I have coffee?'],
    examples: ['Coffee, please.', 'Thank you.'],
    examplePrompt: 'Order one drink.',
    exampleAnswer: 'I would like water, please.',
    checkQuestion: 'Which sentence is a polite order?',
    checkOptions: ['Water, please.', 'Where are you from?', 'She is tall.'],
    correctOption: 'Water, please.',
    checkExplanation: 'Please makes the order polite.',
    speakingPrompt: 'Order one drink and say thank you.',
  ),
  _CoreExperienceSeed(
    title: 'Cafe Vocabulary',
    shortTopic: 'food and drink',
    description: 'Use common cafe words in simple sentences.',
    canDoStatement: 'Recognize common food and drink words.',
    primarySkill: LearningSkill.vocabularyUseOfEnglish,
    words: ['menu', 'tea', 'sandwich', 'juice'],
    introduction: 'Students match cafe words to simple orders.',
    grammarTitle: 'A and an',
    grammarExplanation: 'Use a or an before singular countable nouns.',
    patterns: ['a sandwich', 'an apple', 'a tea'],
    examples: ['I want a sandwich.', 'I would like an apple.'],
    examplePrompt: 'Choose a cafe item.',
    exampleAnswer: 'I want a sandwich.',
    checkQuestion: 'Which word is a cafe item?',
    checkOptions: ['Sandwich', 'Brother', 'Left'],
    correctOption: 'Sandwich',
    checkExplanation: 'A sandwich is a food item.',
  ),
  _CoreExperienceSeed(
    title: 'Prices and Numbers',
    shortTopic: 'prices',
    description: 'Understand simple prices in everyday situations.',
    canDoStatement: 'Understand and say simple prices.',
    primarySkill: LearningSkill.listening,
    words: ['price', 'dollar', 'real', 'how much'],
    introduction: 'Students listen for prices and choose correct numbers.',
    grammarTitle: 'How much is it?',
    grammarExplanation: 'Use how much to ask about price.',
    patterns: ['How much is it?', 'It is ten dollars.'],
    examples: ['It is five dollars.', 'How much is the coffee?'],
    examplePrompt: 'Ask about a price.',
    exampleAnswer: 'How much is it?',
    checkQuestion: 'Which question asks for price?',
    checkOptions: [
      'How much is it?',
      'Where are you from?',
      'What is your name?',
    ],
    correctOption: 'How much is it?',
    checkExplanation: 'How much asks about price.',
    audioScript: '''
Tom: Good morning. How much is the coffee?
Anna: It's five dollars.
Tom: And the sandwich?
Anna: It's eight dollars.
Tom: One coffee, please.
Anna: Here you are. Thank you!''',
    numberOfSpeakers: 2,
  ),
  _CoreExperienceSeed(
    title: 'Read a Menu',
    shortTopic: 'menus',
    description: 'Read a simple menu and find prices.',
    canDoStatement: 'Understand simple menu items and prices.',
    primarySkill: LearningSkill.reading,
    words: ['menu', 'price', 'total', 'item'],
    introduction: 'Students read a short cafe menu.',
    grammarTitle: 'Prices on menus',
    grammarExplanation: 'Menus often list item plus price.',
    patterns: ['Coffee - 5', 'Sandwich - 12'],
    examples: ['Tea is 4 dollars.', 'Juice is 6 dollars.'],
    examplePrompt: 'Find the price of tea.',
    exampleAnswer: 'Tea is 4 dollars.',
    checkQuestion: 'What can you find on a menu?',
    checkOptions: ['Food prices', 'Family members', 'Classroom instructions'],
    correctOption: 'Food prices',
    checkExplanation: 'Menus show items and prices.',
    readingText: 'Menu: Coffee 5. Tea 4. Sandwich 12. Juice 6.',
    readingFormat: ReadingFormat.notice,
  ),
  _CoreExperienceSeed(
    title: 'Short Order Message',
    shortTopic: 'order messages',
    description: 'Write a simple message ordering food or drink.',
    canDoStatement: 'Write a short polite order message.',
    primarySkill: LearningSkill.writing,
    words: ['want', 'please', 'order', 'thanks'],
    introduction: 'Students write a controlled order message.',
    grammarTitle: 'Want and would like',
    grammarExplanation: 'Use want or would like for simple requests.',
    patterns: ['I want ...', 'I would like ...', 'Thank you.'],
    examples: ['I would like a coffee, please.', 'Thanks.'],
    examplePrompt: 'Write one order message.',
    exampleAnswer: 'I would like a sandwich, please.',
    checkQuestion: 'Which sentence is an order message?',
    checkOptions: [
      'I would like tea, please.',
      'My father is kind.',
      'I wake up at seven.',
    ],
    correctOption: 'I would like tea, please.',
    checkExplanation: 'The sentence asks for tea politely.',
    writingPrompt: 'Write a short order message for two cafe items.',
    writingMode: WritingMode.guidedOrder,
    minimumRequirements: ['two items', 'please or thank you'],
    minSentences: 2,
    maxSentences: 4,
  ),
  _CoreExperienceSeed(
    title: 'Ask for Directions',
    shortTopic: 'directions',
    description: 'Ask and answer simple direction questions.',
    canDoStatement: 'Ask where a place is and understand a short answer.',
    primarySkill: LearningSkill.speaking,
    words: ['left', 'right', 'near', 'straight'],
    introduction: 'Students practice a guided directions exchange.',
    grammarTitle: 'Where is ...?',
    grammarExplanation: 'Use where is to ask about places.',
    patterns: ['Where is the bank?', 'Go straight.', 'Turn left.'],
    examples: ['The cafe is near the school.', 'Turn right.'],
    examplePrompt: 'Ask for the bank.',
    exampleAnswer: 'Where is the bank?',
    checkQuestion: 'Which phrase gives directions?',
    checkOptions: ['Turn left.', 'I like music.', 'My name is Ana.'],
    correctOption: 'Turn left.',
    checkExplanation: 'Turn left is direction language.',
    speakingPrompt: 'Ask where a place is and give one simple direction.',
  ),
  _CoreExperienceSeed(
    title: 'Places in Town',
    shortTopic: 'town places',
    description: 'Name common places in town.',
    canDoStatement: 'Identify places in town and say where they are.',
    primarySkill: LearningSkill.vocabularyUseOfEnglish,
    words: ['bank', 'market', 'school', 'station'],
    introduction: 'Students match places to simple location sentences.',
    grammarTitle: 'Near and next to',
    grammarExplanation: 'Use near and next to for simple location.',
    patterns: ['near the school', 'next to the bank'],
    examples: [
      'The market is near the station.',
      'The bank is next to the school.',
    ],
    examplePrompt: 'Say where one place is.',
    exampleAnswer: 'The bank is near the school.',
    checkQuestion: 'Which word is a place in town?',
    checkOptions: ['Bank', 'Sister', 'Favorite'],
    correctOption: 'Bank',
    checkExplanation: 'A bank is a town place.',
  ),
  _CoreExperienceSeed(
    title: 'Travel Information',
    shortTopic: 'travel basics',
    description: 'Understand short travel and city information.',
    canDoStatement: 'Understand simple travel information.',
    primarySkill: LearningSkill.listening,
    words: ['bus', 'station', 'ticket', 'time'],
    introduction: 'Students listen for travel place and time details.',
    grammarTitle: 'Where and when',
    grammarExplanation: 'Use where for place and when for time.',
    patterns: ['Where is the bus?', 'When is the train?'],
    examples: ['The bus is at nine.', 'The station is near.'],
    examplePrompt: 'Identify the time.',
    exampleAnswer: 'The bus is at nine.',
    checkQuestion: 'Which word is travel vocabulary?',
    checkOptions: ['Ticket', 'Mother', 'Coffee'],
    correctOption: 'Ticket',
    checkExplanation: 'Ticket is used for travel.',
    audioScript:
        'The bus to the city is at nine. The station is near the bank.',
  ),
  _CoreExperienceSeed(
    title: 'Signs and Notices',
    shortTopic: 'notices',
    description: 'Read simple public signs and short notices.',
    canDoStatement: 'Understand simple public notices.',
    primarySkill: LearningSkill.reading,
    words: ['open', 'closed', 'exit', 'entrance'],
    introduction: 'Students read short notices for basic meaning.',
    grammarTitle: 'Notice language',
    grammarExplanation: 'Notices use short words and simple instructions.',
    patterns: ['Open 9-5', 'Exit', 'No food'],
    examples: ['The bank is closed.', 'Use the entrance.'],
    examplePrompt: 'Read one notice.',
    exampleAnswer: 'The shop is open.',
    checkQuestion: 'Which word appears on a public sign?',
    checkOptions: ['Exit', 'Brother', 'Favorite'],
    correctOption: 'Exit',
    checkExplanation: 'Exit is a common sign word.',
    readingText: 'Library open 9-5. Please use the main entrance.',
    readingFormat: ReadingFormat.notice,
  ),
  _CoreExperienceSeed(
    title: 'Write Simple Directions',
    shortTopic: 'direction writing',
    description: 'Write short directions to a familiar place.',
    canDoStatement: 'Write simple directions using common place words.',
    primarySkill: LearningSkill.writing,
    words: ['go', 'turn', 'left', 'right'],
    introduction: 'Students write controlled directions.',
    grammarTitle: 'Direction imperatives',
    grammarExplanation: 'Use base verbs to give simple directions.',
    patterns: ['Go straight.', 'Turn right.', 'It is near ...'],
    examples: ['Turn left at the bank.', 'The school is near the market.'],
    examplePrompt: 'Write one direction.',
    exampleAnswer: 'Go straight and turn right.',
    checkQuestion: 'Which sentence gives directions?',
    checkOptions: ['Go straight.', 'I am from Chile.', 'I like tea.'],
    correctOption: 'Go straight.',
    checkExplanation: 'Go straight tells someone where to go.',
    writingPrompt: 'Write three simple directions to a place in town.',
    writingMode: WritingMode.guidedPlaces,
    minimumRequirements: ['one place', 'one direction verb', 'left or right'],
    minSentences: 3,
    maxSentences: 5,
  ),
  _CoreExperienceSeed(
    title: 'Work and Study',
    shortTopic: 'work and study',
    description: 'Talk simply about work or study.',
    canDoStatement: 'Say basic information about work or study.',
    primarySkill: LearningSkill.speaking,
    words: ['work', 'job', 'student', 'teacher'],
    introduction: 'Students answer guided work and study questions.',
    grammarTitle: 'Work as a verb',
    grammarExplanation: 'Use work and study in simple present sentences.',
    patterns: ['I work in ...', 'I study English.', 'I am a student.'],
    examples: ['I work in a store.', 'I study at night.'],
    examplePrompt: 'Say what you do.',
    exampleAnswer: 'I am a student. I study English.',
    checkQuestion: 'Which sentence is about study?',
    checkOptions: ['I study English.', 'Turn left.', 'Coffee, please.'],
    correctOption: 'I study English.',
    checkExplanation: 'Study is about learning.',
    speakingPrompt: 'Say two sentences about your work or study.',
  ),
  _CoreExperienceSeed(
    title: 'Jobs and Study Words',
    shortTopic: 'jobs',
    description: 'Use common job and study words.',
    canDoStatement: 'Identify simple job and study vocabulary.',
    primarySkill: LearningSkill.vocabularyUseOfEnglish,
    words: ['doctor', 'driver', 'student', 'office'],
    introduction: 'Students connect jobs with simple descriptions.',
    grammarTitle: 'A and an for jobs',
    grammarExplanation: 'Use a or an before jobs.',
    patterns: ['a teacher', 'an engineer', 'a student'],
    examples: ['She is a doctor.', 'He is an engineer.'],
    examplePrompt: 'Write one job sentence.',
    exampleAnswer: 'She is a teacher.',
    checkQuestion: 'Which word is a job?',
    checkOptions: ['Doctor', 'Left', 'Breakfast'],
    correctOption: 'Doctor',
    checkExplanation: 'Doctor is a job.',
  ),
  _CoreExperienceSeed(
    title: 'Work and Study Conversations',
    shortTopic: 'short conversations',
    description: 'Understand a short conversation about work or study.',
    canDoStatement: 'Understand basic details in a short conversation.',
    primarySkill: LearningSkill.listening,
    words: ['office', 'school', 'morning', 'evening'],
    introduction: 'Students listen for role, place and time.',
    grammarTitle: 'Do you ...?',
    grammarExplanation: 'Use do you for simple present questions.',
    patterns: ['Do you work?', 'Do you study English?'],
    examples: ['Do you work in an office?', 'Yes, I do.'],
    examplePrompt: 'Identify one work detail.',
    exampleAnswer: 'She works in an office.',
    checkQuestion: 'Which question asks about work?',
    checkOptions: ['Do you work?', 'How much is it?', 'Where is the bank?'],
    correctOption: 'Do you work?',
    checkExplanation: 'Do you work asks about work.',
    audioScript: '''
Anna: Do you work?
Leo: Yes, I work in an office.
Anna: When do you work?
Leo: In the morning. I study English at night.''',
    numberOfSpeakers: 2,
  ),
  _CoreExperienceSeed(
    title: 'Short Messages',
    shortTopic: 'messages',
    description: 'Read short messages about everyday plans.',
    canDoStatement: 'Understand a short everyday message.',
    primarySkill: LearningSkill.reading,
    words: ['message', 'today', 'tomorrow', 'meet'],
    introduction: 'Students read for time, place and purpose.',
    grammarTitle: 'Short message format',
    grammarExplanation: 'Messages are brief and usually include one action.',
    patterns: ['See you at ...', 'Meet me at ...', 'I am at ...'],
    examples: ['Meet me at the station.', 'See you tomorrow.'],
    examplePrompt: 'Find the meeting place.',
    exampleAnswer: 'They meet at the station.',
    checkQuestion: 'Which sentence is a short message?',
    checkOptions: ['See you at five.', 'My sister is tall.', 'This is a menu.'],
    correctOption: 'See you at five.',
    checkExplanation: 'It is a brief everyday message.',
    readingText: 'Hi Leo. Meet me at the station at five. See you soon.',
    readingFormat: ReadingFormat.message,
  ),
  _CoreExperienceSeed(
    title: 'Write a Short Message',
    shortTopic: 'message writing',
    description: 'Write a short message for an everyday situation.',
    canDoStatement: 'Write a simple message with place and time.',
    primarySkill: LearningSkill.writing,
    words: ['meet', 'at', 'today', 'thanks'],
    introduction: 'Students write a short controlled message.',
    grammarTitle: 'Message essentials',
    grammarExplanation:
        'A simple message can include greeting, place and time.',
    patterns: ['Hi ...', 'Meet me at ...', 'Thanks.'],
    examples: ['Hi Ana. Meet me at school at six.', 'Thanks.'],
    examplePrompt: 'Write one short message.',
    exampleAnswer: 'Hi Ben. Meet me at the cafe at five.',
    checkQuestion: 'Which message includes time?',
    checkOptions: ['Meet me at five.', 'I have one sister.', 'She is kind.'],
    correctOption: 'Meet me at five.',
    checkExplanation: 'At five gives the time.',
    writingPrompt: 'Write a short message to meet a friend.',
    writingMode: WritingMode.shortMessage,
    minimumRequirements: ['greeting', 'place', 'time'],
    minSentences: 2,
    maxSentences: 4,
  ),
  _CoreExperienceSeed(
    title: 'Make Simple Arrangements',
    shortTopic: 'arrangements',
    description: 'Make a simple plan with place and time.',
    canDoStatement: 'Arrange a short meeting in simple English.',
    primarySkill: LearningSkill.speaking,
    words: ['meet', 'today', 'tomorrow', 'time'],
    introduction: 'Students practice a short arrangement dialogue.',
    grammarTitle: 'Can for arrangements',
    grammarExplanation: 'Use can to ask about possibility.',
    patterns: ['Can we meet?', 'At five?', 'See you there.'],
    examples: ['Can we meet tomorrow?', 'See you at five.'],
    examplePrompt: 'Make one arrangement.',
    exampleAnswer: 'Can we meet at the cafe at five?',
    checkQuestion: 'Which sentence makes an arrangement?',
    checkOptions: [
      'Can we meet at five?',
      'I like apples.',
      'The bank is closed.',
    ],
    correctOption: 'Can we meet at five?',
    checkExplanation: 'The sentence asks to arrange a meeting.',
    speakingPrompt: 'Make a simple plan with a place and time.',
    maxRecordingSeconds: 75,
  ),
  _CoreExperienceSeed(
    title: 'A1 Grammar Patterns',
    shortTopic: 'grammar review',
    description: 'Review key A1 grammar patterns before certification tasks.',
    canDoStatement: 'Use key A1 patterns in controlled sentences.',
    primarySkill: LearningSkill.vocabularyUseOfEnglish,
    words: ['be', 'have', 'like', 'work'],
    introduction: 'Students consolidate core grammar for production.',
    grammarTitle: 'A1 control',
    grammarExplanation:
        'Core A1 uses be, have, simple present and fixed phrases.',
    patterns: ['I am ...', 'I have ...', 'I like ...', 'I work ...'],
    examples: ['I have one sister.', 'I work in a store.'],
    examplePrompt: 'Write one sentence with have.',
    exampleAnswer: 'I have one brother.',
    checkQuestion: 'Which sentence uses have correctly?',
    checkOptions: [
      'I have one brother.',
      'I has one brother.',
      'I having one brother.',
    ],
    correctOption: 'I have one brother.',
    checkExplanation: 'Use have with I.',
  ),
  _CoreExperienceSeed(
    title: 'A1 Conversation Listening',
    shortTopic: 'A1 conversations',
    description:
        'Understand a short conversation using integrated A1 language.',
    canDoStatement: 'Understand the main idea in a short A1 conversation.',
    primarySkill: LearningSkill.listening,
    words: ['conversation', 'question', 'answer', 'detail'],
    introduction: 'Students listen for main idea and key details.',
    grammarTitle: 'Integrated A1 review',
    grammarExplanation:
        'A1 conversations combine familiar questions and answers.',
    patterns: ['Where are you from?', 'What do you do?', 'What do you like?'],
    examples: ['I am from Lima.', 'I study English.'],
    examplePrompt: 'Identify the main idea.',
    exampleAnswer: 'The speakers introduce themselves.',
    checkQuestion: 'What should students listen for first?',
    checkOptions: ['The main idea', 'Every unknown word', 'Only spelling'],
    correctOption: 'The main idea',
    checkExplanation: 'Main idea comes before small details.',
    audioScript:
        'A: Hi, I am Sofia. I study English. B: Nice to meet you. I am Marco. I work in a store.',
    numberOfSpeakers: 2,
  ),
  _CoreExperienceSeed(
    title: 'Mini Profile Reading',
    shortTopic: 'mini profiles',
    description: 'Read and respond to a short A1 profile.',
    canDoStatement: 'Understand a short profile and answer simple questions.',
    primarySkill: LearningSkill.reading,
    words: ['profile', 'routine', 'preference', 'city'],
    introduction: 'Students read a profile that combines personal A1 topics.',
    grammarTitle: 'Profile review',
    grammarExplanation:
        'A profile can include identity, routine and preferences.',
    patterns: ['I live in ...', 'I work ...', 'I like ...'],
    examples: ['I live in Quito.', 'I like music.'],
    examplePrompt: 'Find one preference.',
    exampleAnswer: 'She likes music.',
    checkQuestion: 'What information can a mini profile include?',
    checkOptions: ['Name, routine and likes', 'Only prices', 'Only directions'],
    correctOption: 'Name, routine and likes',
    checkExplanation: 'Mini profiles combine familiar personal details.',
    readingText:
        'My name is Carla. I live in Quito. I work in a school. I like music and coffee.',
  ),
  _CoreExperienceSeed(
    title: 'A1 Presentation Preparation',
    shortTopic: 'presentations',
    description: 'Prepare a short spoken A1 presentation.',
    canDoStatement:
        'Give a short prepared A1 presentation about familiar topics.',
    primarySkill: LearningSkill.speaking,
    words: ['presentation', 'first', 'then', 'finally'],
    introduction: 'Students organize personal information into a short talk.',
    grammarTitle: 'Simple sequence',
    grammarExplanation: 'Use first, then and finally to organize ideas.',
    patterns: ['First, ...', 'Then, ...', 'Finally, ...'],
    examples: ['First, my name is Carla.', 'Then, I talk about my routine.'],
    examplePrompt: 'Start a short presentation.',
    exampleAnswer: 'First, my name is Carla and I am from Brazil.',
    checkQuestion: 'Which word helps organize a presentation?',
    checkOptions: ['First', 'Ticket', 'Closed'],
    correctOption: 'First',
    checkExplanation: 'First helps sequence ideas.',
    speakingPrompt:
        'Give a short presentation about yourself, your routine and one preference.',
    maxRecordingSeconds: 90,
  ),
];

class _CoreExperienceSeed {
  final String title;
  final String shortTopic;
  final String description;
  final String canDoStatement;
  final LearningSkill primarySkill;
  final List<LearningSkill> secondarySkills;
  final int? difficultyLevel;
  final int? estimatedMinutes;
  final List<String> words;
  final String introduction;
  final String grammarTitle;
  final String grammarExplanation;
  final List<String> patterns;
  final List<String> examples;
  final String examplePrompt;
  final String exampleAnswer;
  final String checkQuestion;
  final List<String> checkOptions;
  final String correctOption;
  final String checkExplanation;
  final List<ActivityQuestion> extraQuestions;
  final String audioPath;
  final String audioScript;
  final int maxAudioPlays;
  final int numberOfSpeakers;
  final String readingText;
  final ReadingFormat readingFormat;
  final String writingPrompt;
  final WritingMode writingMode;
  final List<String> minimumRequirements;
  final int minSentences;
  final int maxSentences;
  final String speakingPrompt;
  final int maxRecordingSeconds;

  const _CoreExperienceSeed({
    required this.title,
    required this.shortTopic,
    required this.description,
    required this.canDoStatement,
    required this.primarySkill,
    this.secondarySkills = const [],
    this.difficultyLevel,
    this.estimatedMinutes,
    required this.words,
    required this.introduction,
    required this.grammarTitle,
    required this.grammarExplanation,
    required this.patterns,
    required this.examples,
    required this.examplePrompt,
    required this.exampleAnswer,
    required this.checkQuestion,
    required this.checkOptions,
    required this.correctOption,
    required this.checkExplanation,
    this.extraQuestions = const [],
    this.audioPath = '',
    this.audioScript = '',
    this.maxAudioPlays = 2,
    this.numberOfSpeakers = 1,
    this.readingText = '',
    this.readingFormat = ReadingFormat.paragraph,
    this.writingPrompt = '',
    this.writingMode = WritingMode.freeResponse,
    this.minimumRequirements = const [],
    this.minSentences = 1,
    this.maxSentences = 4,
    this.speakingPrompt = '',
    this.maxRecordingSeconds = 60,
  });
}

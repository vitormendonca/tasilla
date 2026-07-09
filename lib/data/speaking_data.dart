import '../models/speaking_activity.dart';

const List<SpeakingActivity> speakingActivities = [
  SpeakingActivity(
    id: 'speaking_001',
    title: 'Personal Introduction Practice',
    description: 'Record or rehearse a short self-introduction.',
    level: 'A1',
    prompt:
        'Introduce yourself in English. Say your name, where you are from, and one thing you like.',
    targetLanguage: 'Hello, my name is Maria. I am from Brazil. I like music.',
    preparationTip:
        'Practice the sentence twice before submitting. Speak slowly and clearly.',
    checklist: [
      'I said my name.',
      'I said where I am from.',
      'I said one thing I like.',
      'I practiced aloud before submitting.',
    ],
  ),
];

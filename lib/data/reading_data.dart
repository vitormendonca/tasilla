import '../models/activity_question.dart';
import '../models/reading_activity.dart';

const List<ReadingActivity> readingActivities = [
  ReadingActivity(
    id: 'reading_001',
    title: 'A Busy Morning',
    description: 'Read a short text about a morning routine.',
    level: 'A1',
    text:
        'Anna wakes up at 7 o’clock every morning. She takes a shower, has breakfast, and drinks a cup of coffee. After breakfast, she goes to work by bus. She starts work at 9 o’clock.',
    questions: [
      ActivityQuestion(
        id: 'reading_001_q1',
        type: QuestionType.multipleChoice,
        question: 'What time does Anna wake up?',
        options: ['At 6 o’clock', 'At 7 o’clock', 'At 9 o’clock'],
        correctAnswer: 'At 7 o’clock',
      ),
      ActivityQuestion(
        id: 'reading_001_q2',
        type: QuestionType.multipleChoice,
        question: 'What does Anna drink in the morning?',
        options: ['Tea', 'Coffee', 'Juice'],
        correctAnswer: 'Coffee',
      ),
      ActivityQuestion(
        id: 'reading_001_q3',
        type: QuestionType.textInput,
        question: 'How does Anna go to work?',
        options: [],
        correctAnswer: 'By bus',
      ),
    ],
  ),
  ReadingActivity(
    id: 'reading_002',
    title: 'At the Restaurant',
    description: 'Read a simple text about ordering food.',
    level: 'A2',
    text:
        'Mark goes to a restaurant with his friend Julia. The waiter gives them the menu. Mark orders chicken with rice, and Julia orders pasta. They also ask for two glasses of orange juice.',
    questions: [
      ActivityQuestion(
        id: 'reading_002_q1',
        type: QuestionType.multipleChoice,
        question: 'Where does Mark go?',
        options: ['To a school', 'To a restaurant', 'To a bank'],
        correctAnswer: 'To a restaurant',
      ),
      ActivityQuestion(
        id: 'reading_002_q2',
        type: QuestionType.trueFalse,
        question: 'Julia orders pasta.',
        options: ['True', 'False'],
        correctAnswer: 'True',
      ),
      ActivityQuestion(
        id: 'reading_002_q3',
        type: QuestionType.textInput,
        question: 'What does Mark order?',
        options: [],
        correctAnswer: 'Chicken with rice',
      ),
    ],
  ),
];

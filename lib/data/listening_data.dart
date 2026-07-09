import '../models/activity_question.dart';
import '../models/listening_exercise.dart';

const List<ListeningExercise> listeningExercises = [
  ListeningExercise(
    id: 'listening_a1_morning_routine',
    title: 'Morning Routine',
    description: 'Listen to a short audio about a daily routine.',
    level: 'A1',
    audioPath: 'audio/airport_conversation.mp3',
    transcript:
        'Anna wakes up at seven o’clock every morning. She has breakfast and goes to work by bus.',
    questions: [
      ActivityQuestion(
        id: 'listening_a1_morning_routine_q1',
        type: QuestionType.multipleChoice,
        question: 'What time does Anna wake up?',
        options: ['At six o’clock', 'At seven o’clock', 'At nine o’clock'],
        correctAnswer: 'At seven o’clock',
      ),
      ActivityQuestion(
        id: 'listening_a1_morning_routine_q2',
        type: QuestionType.multipleChoice,
        question: 'How does Anna go to work?',
        options: ['By car', 'By bus', 'By bike'],
        correctAnswer: 'By bus',
      ),
      ActivityQuestion(
        id: 'listening_a1_morning_routine_q3',
        type: QuestionType.dictation,
        question:
            'Listen and type this sentence: Anna wakes up at seven o’clock.',
        options: [],
        correctAnswer: 'Anna wakes up at seven o’clock',
      ),
    ],
  ),

  ListeningExercise(
    id: 'listening_a1_at_the_cafe',
    title: 'At the Café',
    description: 'Listen to a simple conversation at a café.',
    level: 'A1',
    audioPath: 'audio/airport_conversation.mp3',
    transcript:
        'Tom is at a café. He orders a coffee and a cheese sandwich. The waiter says the total is eight dollars.',
    questions: [
      ActivityQuestion(
        id: 'listening_a1_at_the_cafe_q1',
        type: QuestionType.multipleChoice,
        question: 'Where is Tom?',
        options: ['At a café', 'At school', 'At the airport'],
        correctAnswer: 'At a café',
      ),
      ActivityQuestion(
        id: 'listening_a1_at_the_cafe_q2',
        type: QuestionType.multipleChoice,
        question: 'What does Tom order?',
        options: [
          'A coffee and a cheese sandwich',
          'A tea and a cake',
          'A juice and a salad',
        ],
        correctAnswer: 'A coffee and a cheese sandwich',
      ),
      ActivityQuestion(
        id: 'listening_a1_at_the_cafe_q3',
        type: QuestionType.dictation,
        question: 'Listen and type this sentence: He orders a coffee.',
        options: [],
        correctAnswer: 'He orders a coffee',
      ),
    ],
  ),

  ListeningExercise(
    id: 'listening_a1_family_intro',
    title: 'My Family',
    description: 'Listen to someone introducing their family.',
    level: 'A1',
    audioPath: 'audio/airport_conversation.mp3',
    transcript:
        'My name is Laura. I live with my mother, my father, and my brother. My brother is twelve years old.',
    questions: [
      ActivityQuestion(
        id: 'listening_a1_family_intro_q1',
        type: QuestionType.multipleChoice,
        question: 'What is her name?',
        options: ['Laura', 'Anna', 'Julia'],
        correctAnswer: 'Laura',
      ),
      ActivityQuestion(
        id: 'listening_a1_family_intro_q2',
        type: QuestionType.multipleChoice,
        question: 'Who does Laura live with?',
        options: [
          'Her friends',
          'Her mother, father, and brother',
          'Her teacher',
        ],
        correctAnswer: 'Her mother, father, and brother',
      ),
      ActivityQuestion(
        id: 'listening_a1_family_intro_q3',
        type: QuestionType.dictation,
        question:
            'Listen and type this sentence: My brother is twelve years old.',
        options: [],
        correctAnswer: 'My brother is twelve years old',
      ),
    ],
  ),

  ListeningExercise(
    id: 'listening_a1_at_school',
    title: 'At School',
    description: 'Listen to a short audio about school objects.',
    level: 'A1',
    audioPath: 'audio/airport_conversation.mp3',
    transcript:
        'Ben is in the classroom. He has a book, a pencil, and a notebook on his desk.',
    questions: [
      ActivityQuestion(
        id: 'listening_a1_at_school_q1',
        type: QuestionType.multipleChoice,
        question: 'Where is Ben?',
        options: ['In the classroom', 'In the kitchen', 'In the park'],
        correctAnswer: 'In the classroom',
      ),
      ActivityQuestion(
        id: 'listening_a1_at_school_q2',
        type: QuestionType.multipleChoice,
        question: 'What does Ben have on his desk?',
        options: [
          'A phone and a bag',
          'A book, a pencil, and a notebook',
          'A sandwich and a coffee',
        ],
        correctAnswer: 'A book, a pencil, and a notebook',
      ),
      ActivityQuestion(
        id: 'listening_a1_at_school_q3',
        type: QuestionType.dictation,
        question: 'Listen and type this sentence: Ben is in the classroom.',
        options: [],
        correctAnswer: 'Ben is in the classroom',
      ),
    ],
  ),

  ListeningExercise(
    id: 'listening_a1_weekend_plans',
    title: 'Weekend Plans',
    description: 'Listen to a simple conversation about the weekend.',
    level: 'A1',
    audioPath: 'audio/airport_conversation.mp3',
    transcript:
        'Sarah wants to go to the park on Saturday. She wants to walk, read a book, and drink orange juice.',
    questions: [
      ActivityQuestion(
        id: 'listening_a1_weekend_plans_q1',
        type: QuestionType.multipleChoice,
        question: 'Where does Sarah want to go?',
        options: ['To the park', 'To the bank', 'To the airport'],
        correctAnswer: 'To the park',
      ),
      ActivityQuestion(
        id: 'listening_a1_weekend_plans_q2',
        type: QuestionType.multipleChoice,
        question: 'When does Sarah want to go?',
        options: ['On Monday', 'On Saturday', 'On Friday'],
        correctAnswer: 'On Saturday',
      ),
      ActivityQuestion(
        id: 'listening_a1_weekend_plans_q3',
        type: QuestionType.dictation,
        question:
            'Listen and type this sentence: Sarah wants to go to the park.',
        options: [],
        correctAnswer: 'Sarah wants to go to the park',
      ),
    ],
  ),

  ListeningExercise(
    id: 'listening_a1_review_1',
    title: 'A1 Listening Review 1',
    description:
        'Review daily routine, café, family, school, and weekend plans.',
    level: 'A1 Review',
    audioPath: 'audio/airport_conversation.mp3',
    transcript:
        'Anna wakes up early. Tom orders coffee at a café. Laura talks about her family. Ben is in the classroom. Sarah wants to go to the park on Saturday.',
    questions: [
      ActivityQuestion(
        id: 'listening_a1_review_1_q1',
        type: QuestionType.multipleChoice,
        question: 'Who wakes up early?',
        options: ['Anna', 'Tom', 'Ben'],
        correctAnswer: 'Anna',
      ),
      ActivityQuestion(
        id: 'listening_a1_review_1_q2',
        type: QuestionType.multipleChoice,
        question: 'Where does Tom order coffee?',
        options: ['At a café', 'At school', 'At the park'],
        correctAnswer: 'At a café',
      ),
      ActivityQuestion(
        id: 'listening_a1_review_1_q3',
        type: QuestionType.multipleChoice,
        question: 'Who talks about her family?',
        options: ['Laura', 'Sarah', 'Anna'],
        correctAnswer: 'Laura',
      ),
      ActivityQuestion(
        id: 'listening_a1_review_1_q4',
        type: QuestionType.multipleChoice,
        question: 'Where is Ben?',
        options: ['In the classroom', 'At the restaurant', 'At the airport'],
        correctAnswer: 'In the classroom',
      ),
      ActivityQuestion(
        id: 'listening_a1_review_1_q5',
        type: QuestionType.multipleChoice,
        question: 'Where does Sarah want to go?',
        options: ['To the park', 'To the café', 'To school'],
        correctAnswer: 'To the park',
      ),
      ActivityQuestion(
        id: 'listening_a1_review_1_q6',
        type: QuestionType.dictation,
        question: 'Listen and type this sentence: Tom orders coffee at a café.',
        options: [],
        correctAnswer: 'Tom orders coffee at a café',
      ),
    ],
  ),
];

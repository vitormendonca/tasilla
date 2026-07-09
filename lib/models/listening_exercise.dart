import 'activity_question.dart';
import 'learning_enums.dart';

class ListeningExercise {
  final String id;
  final String title;
  final String description;
  final String level;
  final String levelId;
  final String cycleId;
  final LearningSkill skill;
  final ActivityKind activityKind;
  final String cefrLevel;
  final String canDoStatement;
  final double passingScore;

  // Path used by AssetSource.
  // Example: audio/airport_conversation.mp3
  final String audioPath;

  // Text version of the audio.
  final String transcript;

  // Questions connected to this listening exercise.
  final List<ActivityQuestion> questions;

  const ListeningExercise({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    this.levelId = 'a1',
    this.cycleId = '',
    this.skill = LearningSkill.listening,
    this.activityKind = ActivityKind.coreActivity,
    this.cefrLevel = 'A1',
    this.canDoStatement = '',
    this.passingScore = 0.75,
    required this.audioPath,
    required this.transcript,
    required this.questions,
  });
}

enum QuestionType {
  multipleChoice,
  textInput,
  trueFalse,
  dictation,
  fillBlank,
  reorderSentence,
}

class ActivityQuestion {
  final String id;
  final QuestionType type;
  final String question;

  // Used for multiple choice and true/false questions.
  final List<String> options;

  // Main correct answer used to check the student response.
  final String correctAnswer;

  // Optional audio path for questions that need a specific audio file.
  final String? audioPath;

  // Used for reorder sentence activities in the future.
  final List<String> words;

  const ActivityQuestion({
    required this.id,
    required this.type,
    required this.question,
    this.options = const [],
    required this.correctAnswer,
    this.audioPath,
    this.words = const [],
  });
}

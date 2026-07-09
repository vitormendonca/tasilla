class PlacementQuestion {
  final String id;
  final String skill;
  final String question;
  final List<String> options;
  final String correctAnswer;

  const PlacementQuestion({
    required this.id,
    required this.skill,
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}

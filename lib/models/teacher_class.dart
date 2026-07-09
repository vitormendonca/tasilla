class TeacherClass {
  final String id;
  final String className;
  final String description;

  final String classType; // Individual or Group
  final String classCode;
  final String classDay;
  final String classTime;
  final String frequency;
  final String format; // Online or Presential

  final int students;
  final int completed;
  final int reviewNeeded;
  final int average;

  const TeacherClass({
    required this.id,
    required this.className,
    required this.description,
    required this.classType,
    required this.classCode,
    required this.classDay,
    required this.classTime,
    required this.frequency,
    required this.format,
    required this.students,
    required this.completed,
    required this.reviewNeeded,
    required this.average,
  });
}

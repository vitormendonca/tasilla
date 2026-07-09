class StudentData {
  final String id;
  final String name;
  final String level;
  final String accessCode;

  const StudentData({
    required this.id,
    required this.name,
    required this.level,
    required this.accessCode,
  });
}

const List<StudentData> studentsData = [
  StudentData(
    id: 'student_001',
    name: 'Joao Silva',
    level: 'A1',
    accessCode: 'joao123',
  ),
  StudentData(
    id: 'student_002',
    name: 'Maria Santos',
    level: 'A2',
    accessCode: 'maria123',
  ),
  StudentData(
    id: 'student_003',
    name: 'Ana Costa',
    level: 'B1',
    accessCode: 'ana123',
  ),
];

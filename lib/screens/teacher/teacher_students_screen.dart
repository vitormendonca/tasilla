import 'package:flutter/material.dart';

import '../../services/teacher_students_service.dart';
import 'teacher_student_detail_screen.dart';

class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  List<TeacherStudentSummary> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final loadedStudents = await TeacherStudentsService.getStudentsForCurrentTeacher();

    if (!mounted) return;

    setState(() {
      students = loadedStudents;
      isLoading = false;
    });
  }

  Future<void> _openStudent(TeacherStudentSummary student) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherStudentDetailScreen(
          studentId: student.id,
          studentName: student.name,
          studentLevel: student.level,
          accessCode: student.accessCode,
        ),
      ),
    );

    if (!mounted) return;

    await _loadStudents();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas      = isDark ? const Color(0xFF161618) : const Color(0xFFFAFAF8);
    final textPrimary = isDark ? const Color(0xFFF5F5F0) : const Color(0xFF1A1A1A);
    final textMuted   = isDark ? const Color(0xFF48484A) : const Color(0xFFAEAAA2);
    final surface     = isDark ? const Color(0xFF242426) : const Color(0xFFF0EEE8);
    final border      = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC);

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textMuted),
        title: Text('Students', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
        actions: [
          IconButton(
            tooltip: 'Refresh students',
            onPressed: _loadStudents,
            icon: Icon(Icons.refresh, color: textMuted, size: 20),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStudents,
        color: textPrimary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('YOUR STUDENTS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
            const SizedBox(height: 4),
            Text('Select a student to assign activities or view progress.', style: TextStyle(fontSize: 12, color: textMuted)),
            const SizedBox(height: 20),
            if (isLoading)
              Center(child: Padding(padding: const EdgeInsets.only(top: 40), child: CircularProgressIndicator(color: textPrimary, strokeWidth: 1.5)))
            else if (students.isEmpty)
              _emptyState(textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border)
            else
              ...students.map((s) => _studentCard(s, textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border)),
          ],
        ),
      ),
    );
  }

  Widget _studentCard(
    TeacherStudentSummary student, {
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final initial = student.name.isEmpty ? '?' : student.name[0].toUpperCase();

    return GestureDetector(
      onTap: () => _openStudent(student),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: textPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(initial, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _chip('Level ${student.level}', textMuted, border),
                      if (student.accessCode.isNotEmpty)
                        _chip(student.accessCode, textMuted, border),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(Icons.person_add_alt_1_outlined, color: textMuted, size: 40),
          const SizedBox(height: 14),
          Text('No linked students yet', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Link a student to this teacher in Supabase to manage real assignments.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

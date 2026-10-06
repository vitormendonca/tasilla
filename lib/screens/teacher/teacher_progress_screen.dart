import 'package:flutter/material.dart';

import '../../services/organization_service.dart';
import '../../services/teacher_students_service.dart';
import 'teacher_student_progress_screen.dart';

class TeacherProgressScreen extends StatefulWidget {
  const TeacherProgressScreen({super.key});

  @override
  State<TeacherProgressScreen> createState() => _TeacherProgressScreenState();
}

class _TeacherProgressScreenState extends State<TeacherProgressScreen> {
  List<OrganizationSummary> _organizations = const [];
  List<TeacherStudentSummary> _students = const [];
  String? _organizationId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final organizations = await OrganizationService.getOrganizationsForCurrentUser();
      final students = await TeacherStudentsService.getStudentsForCurrentTeacher(
        organizationId: _organizationId,
      );
      if (!mounted) return;
      setState(() {
        _organizations = organizations;
        _students = students;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load student progress.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas = isDark ? const Color(0xFF161618) : const Color(0xFFFAFAF8);
    final textPrimary = isDark ? const Color(0xFFF5F5F0) : const Color(0xFF1A1A1A);
    final textMuted = isDark ? const Color(0xFF8E8E93) : const Color(0xFF77736B);
    final surface = isDark ? const Color(0xFF242426) : const Color(0xFFF0EEE8);
    final border = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC);

    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        backgroundColor: canvas,
        elevation: 0,
        title: Text('Progress', style: TextStyle(fontSize: 14, color: textPrimary)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
            icon: Icon(Icons.refresh, color: textMuted),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('STUDENT PROGRESS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
          const SizedBox(height: 6),
          Text('Choose a student to inspect learning progress in the selected teaching context.', style: TextStyle(fontSize: 13, color: textMuted)),
          const SizedBox(height: 18),
          if (_organizations.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: _organizationId ?? '__independent__',
              decoration: const InputDecoration(labelText: 'Teaching context'),
              items: [
                const DropdownMenuItem(value: '__independent__', child: Text('Independent Teacher')),
                for (final organization in _organizations)
                  DropdownMenuItem(value: organization.id, child: Text(organization.name)),
              ],
              onChanged: (value) async {
                setState(() {
                  _organizationId = value == '__independent__' ? null : value;
                  _loading = true;
                });
                await _load();
              },
            ),
            const SizedBox(height: 18),
          ],
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (_error != null)
            Center(child: Column(children: [
              Text(_error!, style: TextStyle(color: textMuted)),
              TextButton(onPressed: () { setState(() => _loading = true); _load(); }, child: const Text('Retry')),
            ]))
          else if (_students.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
              child: Text('No active students in this teaching context.', style: TextStyle(color: textMuted)),
            )
          else
            for (final student in _students)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                child: ListTile(
                  leading: CircleAvatar(child: Text(student.name.isEmpty ? '?' : student.name[0].toUpperCase())),
                  title: Text(student.name, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500)),
                  subtitle: Text('Level ${student.level}', style: TextStyle(color: textMuted)),
                  trailing: Icon(Icons.chevron_right, color: textMuted),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TeacherStudentProgressScreen(
                        studentId: student.id,
                        studentName: student.name,
                        studentLevel: student.level,
                        organizationId: _organizationId,
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

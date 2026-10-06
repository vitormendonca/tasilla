import 'package:flutter/material.dart';

import '../../services/organization_service.dart';
import '../../services/teacher_students_service.dart';
import 'teacher_student_detail_screen.dart';

class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen> {
  List<TeacherStudentSummary> students = [];
  List<OrganizationSummary> organizations = [];
  String? selectedOrganizationId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  Future<void> _loadOrganizations() async {
    final loadedOrganizations =
        await OrganizationService.getOrganizationsForCurrentUser();

    if (!mounted) return;

    final nextOrganizationId =
        selectedOrganizationId != null &&
                loadedOrganizations.any((item) => item.id == selectedOrganizationId)
            ? selectedOrganizationId
            : loadedOrganizations.isNotEmpty
                ? loadedOrganizations.first.id
                : null;

    setState(() {
      organizations = loadedOrganizations;
      selectedOrganizationId = nextOrganizationId;
    });

    await _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      isLoading = true;
    });

    final loadedStudents = await TeacherStudentsService.getStudentsForCurrentTeacher(
      organizationId: selectedOrganizationId,
    );

    if (!mounted) return;

    setState(() {
      students = loadedStudents;
      isLoading = false;
    });
  }

  Future<void> _linkStudent() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Link student'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Student access code',
            hintText: 'Enter the code shared by the student',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Link')),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || code == null || code.isEmpty) return;

    setState(() => isLoading = true);
    final error = await TeacherStudentsService.linkStudentByAccessCode(
      accessCode: code,
      organizationId: selectedOrganizationId,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await _loadStudents();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student linked.')));
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
          organizationId: selectedOrganizationId,
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
            tooltip: 'Link student',
            onPressed: isLoading ? null : _linkStudent,
            icon: Icon(Icons.person_add_alt_1_outlined, color: textMuted, size: 20),
          ),
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
            if (organizations.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                value: selectedOrganizationId,
                decoration: InputDecoration(
                  labelText: 'Organization',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: organizations
                    .map((organization) => DropdownMenuItem<String>(
                          value: organization.id,
                          child: Text(organization.name),
                        ))
                    .toList(),
                onChanged: isLoading
                    ? null
                    : (value) async {
                        setState(() => selectedOrganizationId = value);
                        await _loadStudents();
                      },
              ),
              const SizedBox(height: 20),
            ] else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: border),
                ),
                child: Text(
                  'Independent Teacher mode — these students belong directly to your Teacher account and are limited by your plan.',
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
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
            'Use the student access code to link a student. Your plan limit is enforced automatically.',
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

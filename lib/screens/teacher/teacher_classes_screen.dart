import 'package:flutter/material.dart';

import '../../services/class_service.dart';
import '../../services/organization_service.dart';

class TeacherClassesScreen extends StatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen> {
  List<OrganizationSummary> organizations = [];
  List<ClassSummary> classes = [];
  OrganizationSummary? selectedOrganization;
  bool isLoading = true;
  bool isSaving = false;
  List<OrganizationStudentSummary> organizationStudents = [];
  List<ClassStudentSummary> enrolledStudents = [];
  ClassSummary? selectedClass;
  bool isRosterLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLiveClasses();
  }

  Future<void> _loadLiveClasses() async {
    setState(() => isLoading = true);
    final loaded = await OrganizationService.getOrganizationsForCurrentUser();
    if (!mounted) return;

    if (loaded.isEmpty) {
      setState(() {
        organizations = [];
        classes = [];
        selectedOrganization = null;
        isLoading = false;
      });
      return;
    }

    final selected = loaded.firstWhere(
      (item) => item.id == selectedOrganization?.id,
      orElse: () => loaded.first,
    );
    final loadedClasses = await ClassService.listForOrganization(selected.id);
    if (!mounted) return;

    setState(() {
      organizations = loaded;
      selectedOrganization = selected;
      classes = loadedClasses;
      selectedClass = null;
      enrolledStudents = [];
      organizationStudents = [];
      isLoading = false;
    });
  }


  Future<void> _loadRoster(ClassSummary classItem) async {
    setState(() => isRosterLoading = true);
    final roster = await ClassService.listStudents(classItem.id);
    final students = await OrganizationService.getStudentMembers(classItem.organizationId);
    if (!mounted) return;
    setState(() {
      selectedClass = classItem;
      enrolledStudents = roster;
      organizationStudents = students;
      isRosterLoading = false;
    });
  }

  Future<void> _showAddStudentDialog() async {
    final classItem = selectedClass;
    if (classItem == null) return;
    final enrolledIds = enrolledStudents.map((item) => item.studentId).toSet();
    final available = organizationStudents.where((student) => !enrolledIds.contains(student.userId)).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todos os alunos da organização já estão nesta turma.')));
      return;
    }
    final student = await showDialog<OrganizationStudentSummary>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Adicionar aluno'),
        children: available.map((item) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, item),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(item.fullName),
            subtitle: Text('Nível ${item.level}'),
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          ),
        )).toList(),
      ),
    );
    if (student == null) return;
    setState(() => isSaving = true);
    final ok = await ClassService.enrollStudent(classId: classItem.id, studentId: student.userId);
    if (!mounted) return;
    setState(() => isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? student.fullName + ' adicionado à turma.' : 'Não foi possível adicionar o aluno.')));
    if (ok) await _loadRoster(classItem);
  }

  Future<void> _createOrganization() async {
    final nameController = TextEditingController();
    final slugController = TextEditingController();
    final values = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create organization'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, autofocus: true, decoration: const InputDecoration(labelText: 'School name')),
            TextField(controller: slugController, decoration: const InputDecoration(labelText: 'Slug')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, [
              nameController.text.trim(),
              slugController.text.trim().toLowerCase(),
            ]),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameController.dispose();
    slugController.dispose();

    if (values == null || values[0].length < 2 || values[1].length < 2) return;
    setState(() => isSaving = true);
    final created = await OrganizationService.createOrganization(name: values[0], slug: values[1]);
    if (!mounted) return;
    setState(() => isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(created == null ? 'Could not create organization.' : 'Organization created.')),
    );
    if (created != null) await _loadLiveClasses();
  }

  Future<void> _createClass() async {
    final organization = selectedOrganization;
    if (organization == null) return;
    final controller = TextEditingController();
    String level = 'A1';
    final values = await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create class'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Class name')),
              DropdownButtonFormField<String>(
                value: level,
                decoration: const InputDecoration(labelText: 'Level'),
                items: const [
                  DropdownMenuItem(value: 'A1', child: Text('A1')),
                  DropdownMenuItem(value: 'A2', child: Text('A2')),
                  DropdownMenuItem(value: 'B1', child: Text('B1')),
                ],
                onChanged: (value) => setDialogState(() => level = value ?? 'A1'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, [controller.text.trim(), level]),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (values == null || values[0].length < 2) return;
    setState(() => isSaving = true);
    final created = await ClassService.create(
      organizationId: organization.id,
      name: values[0],
      level: values[1],
    );
    if (!mounted) return;
    setState(() => isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(created == null ? 'Could not create class.' : 'Class created.')),
    );
    if (created != null) await _loadLiveClasses();
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
        title: Text('My Classes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLiveClasses,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('ORGANIZATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
            const SizedBox(height: 8),
            if (isLoading)
              Center(child: CircularProgressIndicator(color: textPrimary, strokeWidth: 1.5))
            else if (organizations.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                child: Column(
                  children: [
                    Text('No organization yet.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary)),
                    const SizedBox(height: 8),
                    Text('Create your school organization before creating classes.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: textMuted)),
                    const SizedBox(height: 14),
                    FilledButton.icon(onPressed: isSaving ? null : _createOrganization, icon: const Icon(Icons.add_business_outlined), label: const Text('Create organization')),
                  ],
                ),
              )
            else ...[
              DropdownButtonFormField<String>(
                value: selectedOrganization?.id,
                decoration: InputDecoration(filled: true, fillColor: surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                items: organizations.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name))).toList(),
                onChanged: isSaving ? null : (id) async {
                  final organization = organizations.firstWhere((item) => item.id == id);
                  setState(() { selectedOrganization = organization; selectedClass = null; enrolledStudents = []; organizationStudents = []; isLoading = true; });
                  final loaded = await ClassService.listForOrganization(organization.id);
                  if (!mounted) return;
                  setState(() { classes = loaded; isLoading = false; });
                },
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: Text('CLASSES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted))),
                FilledButton.icon(onPressed: isSaving ? null : _createClass, icon: const Icon(Icons.add, size: 16), label: const Text('New class')),
              ]),
              const SizedBox(height: 10),
              if (classes.isEmpty)
                Text('No classes created yet.', style: TextStyle(fontSize: 13, color: textMuted))
              else
                ...classes.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                  child: InkWell(
                    onTap: () => _loadRoster(item),
                    child: Row(children: [
                    Icon(Icons.groups_outlined, color: textMuted),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                      const SizedBox(height: 4),
                      Text('Level ${item.level} · ${item.status}', style: TextStyle(fontSize: 11, color: textMuted)),
                    ])),
                    ]),
                  ),
                )),
              if (selectedClass != null) ...[
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: Text('ALUNOS DA TURMA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted))),
                  FilledButton.icon(onPressed: isSaving ? null : _showAddStudentDialog, icon: const Icon(Icons.person_add_alt_1, size: 16), label: const Text('Adicionar aluno')),
                ]),
                const SizedBox(height: 10),
                if (isRosterLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                else if (enrolledStudents.isEmpty)
                  Text('Nenhum aluno matriculado nesta turma.', style: TextStyle(fontSize: 13, color: textMuted))
                else
                  ...enrolledStudents.map((student) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
                    child: Row(children: [
                      const CircleAvatar(radius: 17, child: Icon(Icons.person_outline, size: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(student.studentName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary)),
                        Text('Nível ${student.level} · ${student.status}', style: TextStyle(fontSize: 11, color: textMuted)),
                      ])),
                    ]),
                  )),
              ],
            ],
          ],
        ),
      ),
    );
  }

}

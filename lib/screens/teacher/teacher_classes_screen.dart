import 'package:flutter/material.dart';

import '../../services/class_service.dart';
import '../../services/organization_service.dart';
import '../../theme/app_theme.dart';

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
      isLoading = false;
    });
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
                  setState(() { selectedOrganization = organization; isLoading = true; });
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
                  child: Row(children: [
                    Icon(Icons.groups_outlined, color: textMuted),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                      const SizedBox(height: 4),
                      Text('Level ${item.level} · ${item.status}', style: TextStyle(fontSize: 11, color: textMuted)),
                    ])),
                  ]),
                )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _classCard({
    required TeacherClass teacherClass,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final bool needsReview = teacherClass.reviewNeeded > 0;
    final statusColor = needsReview ? AppTheme.semanticYellow : AppTheme.semanticGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teacherClass.className, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                    const SizedBox(height: 2),
                    Text('${teacherClass.students} students · ${teacherClass.classType}', style: TextStyle(fontSize: 12, color: textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  needsReview ? 'REVIEW' : 'ON TRACK',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: statusColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(teacherClass.description, style: TextStyle(fontSize: 13, color: textMuted, height: 1.4)),
          const SizedBox(height: 12),
          _infoRow(icon: Icons.key_outlined, title: 'Class Code', value: teacherClass.classCode, textPrimary: textPrimary, textMuted: textMuted),
          _infoRow(icon: Icons.calendar_today_outlined, title: 'Class Time', value: '${teacherClass.classDay} at ${teacherClass.classTime}', textPrimary: textPrimary, textMuted: textMuted),
          _infoRow(icon: Icons.repeat_outlined, title: 'Frequency', value: teacherClass.frequency, textPrimary: textPrimary, textMuted: textMuted),
          _infoRow(icon: Icons.computer_outlined, title: 'Format', value: teacherClass.format, textPrimary: textPrimary, textMuted: textMuted),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat(label: 'COMPLETED', value: '${teacherClass.completed}', color: AppTheme.semanticGreen, textMuted: textMuted, border: border),
              const SizedBox(width: 8),
              _miniStat(label: 'REVIEW', value: '${teacherClass.reviewNeeded}', color: AppTheme.semanticYellow, textMuted: textMuted, border: border),
              const SizedBox(width: 8),
              _miniStat(label: 'AVERAGE', value: '${teacherClass.average}%', color: textPrimary, textMuted: textMuted, border: border),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, color: textMuted, size: 15),
          const SizedBox(width: 8),
          Text('$title: ', style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: textPrimary))),
        ],
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required Color color,
    required Color textMuted,
    required Color border,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: color)),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMING SOON', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
          const SizedBox(height: 8),
          Text(
            'Soon teachers will be able to create real classes, edit class codes, approve student requests, and add students by Student ID.',
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

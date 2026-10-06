import 'package:flutter/material.dart';

import '../../services/app_auth_service.dart';
import '../../services/organization_service.dart';

class SchoolHomeScreen extends StatefulWidget {
  const SchoolHomeScreen({super.key});

  @override
  State<SchoolHomeScreen> createState() => _SchoolHomeScreenState();
}

class _SchoolHomeScreenState extends State<SchoolHomeScreen> {
  final _name = TextEditingController();
  final _slug = TextEditingController();
  final _teacherEmail = TextEditingController();
  OrganizationSummary? _organization;
  AccountEntitlement? _entitlement;
  SchoolDashboardStats _stats = const SchoolDashboardStats(activeTeachers: 0, pendingTeacherInvites: 0, students: 0, classes: 0);
  List<SchoolMemberDisplay> _members = [];
  List<TeacherInvitationSummary> _pendingInvites = [];
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _teacherEmail.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final entitlement = await OrganizationService.ensureEntitlement();
    final organizations = await OrganizationService.getOrganizationsForCurrentUser();
    final organization = organizations.isEmpty ? null : organizations.first;
    final stats = organization == null
        ? const SchoolDashboardStats(activeTeachers: 0, pendingTeacherInvites: 0, students: 0, classes: 0)
        : await OrganizationService.getSchoolDashboardStats(organization.id);
    final members = organization == null ? <SchoolMemberDisplay>[] : await OrganizationService.getSchoolMembers(organization.id);
    final invites = organization == null ? <TeacherInvitationSummary>[] : await OrganizationService.getSchoolPendingInvitations(organization.id);
    if (!mounted) return;
    setState(() {
      _entitlement = entitlement;
      _organization = organization;
      _stats = stats;
      _members = members;
      _pendingInvites = invites;
      _loading = false;
    });
  }

  Future<void> _createSchool() async {
    final name = _name.text.trim();
    final slug = _slug.text.trim().toLowerCase();
    if (name.length < 2 || slug.isEmpty) {
      setState(() => _message = 'Enter a school name and slug.');
      return;
    }
    setState(() => _loading = true);
    final organization = await OrganizationService.createOrganization(name: name, slug: slug);
    if (!mounted) return;
    setState(() {
      _organization = organization;
      _message = organization == null ? 'Could not create the school.' : 'School created.';
      _loading = false;
    });
  }

  Future<void> _inviteTeacher() async {
    final email = _teacherEmail.text.trim();
    if (_organization == null || !email.contains('@')) {
      setState(() => _message = 'Enter a valid teacher email.');
      return;
    }
    setState(() => _loading = true);
    final ok = await OrganizationService.inviteTeacher(
      organizationId: _organization!.id,
      email: email,
    );
    await _load();
    if (!mounted) return;
    setState(() {
      _message = ok ? 'Teacher invitation registered.' : 'Could not invite teacher. Check the plan limit or email.';
      _loading = false;
    });
  }

  Future<void> _createClass() async {
    final organization = _organization;
    final teachers = _members.where((member) => member.role == 'teacher').toList();
    if (organization == null || teachers.isEmpty) {
      setState(() => _message = 'Invite a teacher and wait for acceptance before creating a class.');
      return;
    }
    final name = TextEditingController();
    String teacherId = teachers.first.userId;
    String level = 'A1';
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('Create class'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'Class name')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: teacherId,
            decoration: const InputDecoration(labelText: 'Teacher'),
            items: teachers.map((teacher) => DropdownMenuItem(value: teacher.userId, child: Text(teacher.fullName))).toList(),
            onChanged: (value) => setDialogState(() => teacherId = value ?? teacherId),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: level,
            decoration: const InputDecoration(labelText: 'Level'),
            items: const ['A1','A2','B1'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: (value) => setDialogState(() => level = value ?? level),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      )),
    );
    final className = name.text.trim();
    name.dispose();
    if (submit != true) return;
    if (className.length < 2) { setState(() => _message = 'Class name must contain at least 2 characters.'); return; }
    setState(() => _loading = true);
    final error = await OrganizationService.createSchoolClass(organizationId: organization.id, teacherId: teacherId, name: className, level: level);
    await _load();
    if (!mounted) return;
    setState(() { _message = error ?? 'Class created and assigned to the selected teacher.'; _loading = false; });
  }

  Widget _metricCard(BuildContext context, String label, String value, String detail) {
    return SizedBox(
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(detail, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AppAuthService.currentSession.value;
    final teacherLimit = _entitlement?.maxTeachers;
    final studentLimit = _entitlement?.maxStudents;
    return Scaffold(
      appBar: AppBar(
        title: const Text('TASILLA School'),
        actions: [
          TextButton(onPressed: AppAuthService.signOut, child: const Text('Sign out')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, ${session?.name ?? 'School'}',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 24),
                      if (_organization == null) ...[
                        Text('Create your school', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        TextField(controller: _name, decoration: const InputDecoration(labelText: 'School name')),
                        const SizedBox(height: 12),
                        TextField(controller: _slug, decoration: const InputDecoration(labelText: 'School slug')),
                        const SizedBox(height: 16),
                        FilledButton(onPressed: _createSchool, child: const Text('Create school')),
                      ] else ...[
                        Text(_organization!.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text('Plan: ${_entitlement?.planCode ?? 'unavailable'} · ${_entitlement?.status ?? 'unavailable'}'),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _metricCard(context, 'Teachers', '${_stats.activeTeachers}', 'Active members'),
                            _metricCard(context, 'Invites', '${_stats.pendingTeacherInvites}', 'Pending'),
                            _metricCard(context, 'Students', '${_stats.students} / ${studentLimit?.toString() ?? '—'}', 'Plan usage'),
                            _metricCard(context, 'Classes', '${_stats.classes}', 'Active'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Teacher seats: ${_stats.teacherSeatsUsed} / ${teacherLimit?.toString() ?? '—'}'),
                        const SizedBox(height: 24),
                        Text('Invite a teacher', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _teacherEmail,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Teacher email'),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: teacherLimit != null && _stats.teacherSeatsUsed >= teacherLimit ? null : _inviteTeacher,
                          child: const Text('Invite teacher'),
                        ),
                        const SizedBox(height: 28),
                        Row(children: [
                          Expanded(child: Text('Teachers', style: Theme.of(context).textTheme.titleMedium)),
                          OutlinedButton.icon(onPressed: _createClass, icon: const Icon(Icons.add), label: const Text('New class')),
                        ]),
                        const SizedBox(height: 8),
                        ..._members.where((member) => member.role == 'teacher').map((member) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(child: Icon(Icons.school_outlined)),
                          title: Text(member.fullName),
                          subtitle: const Text('Active teacher'),
                        )),
                        if (_members.where((member) => member.role == 'teacher').isEmpty) const Text('No active teachers yet.'),
                        if (_pendingInvites.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text('Pending invitations', style: Theme.of(context).textTheme.titleSmall),
                          ..._pendingInvites.map((invite) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.mark_email_unread_outlined),
                            title: Text(invite.email),
                            subtitle: const Text('Waiting for teacher acceptance'),
                          )),
                        ],
                        const SizedBox(height: 28),
                        Text('Students', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ..._members.where((member) => member.role == 'student').map((member) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                          title: Text(member.fullName),
                          subtitle: Text('Level ${member.level}'),
                        )),
                        if (_members.where((member) => member.role == 'student').isEmpty) const Text('No students enrolled in this school yet.'),
                      ],
                      if (_message != null) ...[
                        const SizedBox(height: 16),
                        Text(_message!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../services/organization_service.dart';

class TeacherInvitationsScreen extends StatefulWidget {
  const TeacherInvitationsScreen({super.key});

  @override
  State<TeacherInvitationsScreen> createState() => _TeacherInvitationsScreenState();
}

class _TeacherInvitationsScreenState extends State<TeacherInvitationsScreen> {
  List<TeacherInvitationSummary> _items = [];
  bool _loading = true;
  String? _message;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final items = await OrganizationService.getMyTeacherInvitations();
    if (!mounted) return;
    setState(() { _items = items; _loading = false; });
  }

  Future<void> _accept(TeacherInvitationSummary item) async {
    setState(() => _loading = true);
    final ok = await OrganizationService.acceptTeacherInvitation(item.id);
    if (!mounted) return;
    setState(() => _message = ok ? 'School invitation accepted.' : 'Could not accept invitation.');
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('School invitations')),
    body: _loading
      ? const Center(child: CircularProgressIndicator())
      : RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_message != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_message!)),
              if (_items.isEmpty)
                const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: Text('No pending school invitations.')))
              else
                ..._items.map((item) => Card(
                  child: ListTile(
                    title: const Text('Teacher invitation'),
                    subtitle: Text(item.email),
                    trailing: FilledButton(onPressed: () => _accept(item), child: const Text('Accept')),
                  ),
                )),
            ],
          ),
        ),
  );
}

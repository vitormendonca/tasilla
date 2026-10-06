import 'package:flutter/material.dart';

import '../../services/app_auth_service.dart';

class SchoolHomeScreen extends StatelessWidget {
  const SchoolHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppAuthService.currentSession.value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('TASILLA School'),
        actions: [
          TextButton(
            onPressed: AppAuthService.signOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, ${session?.name ?? 'School'}',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                const Text(
                  'School workspace foundation is active. Teacher management, plan limits, classes and reporting will be added here without changing independent Teacher accounts.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

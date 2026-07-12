import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_session.dart';
import '../screens/login_screen.dart';
import '../screens/student/student_home_screen.dart';
import '../screens/teacher/teacher_home_screen.dart';
import '../services/app_auth_service.dart';
import '../services/supabase_bootstrap.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _restoring = true;

  @override
  void initState() {
    super.initState();
    AppAuthService.currentSession.addListener(_onSessionChanged);
    final client = SupabaseBootstrap.client;
    if (client != null) {
      _authSubscription = client.auth.onAuthStateChange.listen((state) async {
        if (state.event == AuthChangeEvent.signedOut) {
          AppAuthService.currentSession.value = null;
        } else if (state.session != null &&
            AppAuthService.currentSession.value == null) {
          await AppAuthService.restoreSession();
        }
      });
    }
    _restore();
  }

  Future<void> _restore() async {
    await AppAuthService.restoreSession();
    if (mounted) setState(() => _restoring = false);
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppAuthService.currentSession.removeListener(_onSessionChanged);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final AppSession? session = AppAuthService.currentSession.value;
    if (session == null) return const LoginScreen();
    return session.isTeacher
        ? const TeacherHomeScreen()
        : const StudentHomeScreen();
  }
}

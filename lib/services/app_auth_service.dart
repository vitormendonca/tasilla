import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/students_data.dart';
import '../models/app_session.dart';
import 'supabase_bootstrap.dart';

class AppAuthService {
  static const String teacherCode = 'teacher123';
  static final ValueNotifier<AppSession?> currentSession =
      ValueNotifier<AppSession?>(null);

  static Future<AppSession?> restoreSession() async {
    final client = SupabaseBootstrap.client;
    final user = client?.auth.currentUser;

    if (client != null && user != null) {
      try {
        final profile = await client
            .from('profiles')
            .select('id, role, full_name, current_level')
            .eq('id', user.id)
            .maybeSingle();

        if (profile == null) {
          await signOut();
          return null;
        }

        final session = _sessionFromProfile(profile, fallbackEmail: user.email);
        await _saveSession(session);
        currentSession.value = session;
        return session;
      } catch (_) {
        // Never grant access from stale local preferences when a remote session
        // cannot be validated against its protected profile.
        currentSession.value = null;
        return null;
      }
    }

    // Local sessions exist only for the repository's explicit demo mode.
    if (SupabaseBootstrap.isConfigured) {
      currentSession.value = null;
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('currentUserRole');
    if (role == null) return null;

    final isTeacher = role == 'teacher' || role == 'admin';
    final session = AppSession(
      userId:
          prefs.getString(
            isTeacher ? 'currentTeacherId' : 'currentStudentId',
          ) ??
          '',
      role: role,
      name:
          prefs.getString(
            isTeacher ? 'currentTeacherName' : 'currentStudentName',
          ) ??
          (isTeacher ? 'Teacher' : 'Student'),
      level: prefs.getString('currentStudentLevel') ?? 'A1',
      isRemote: false,
    );
    currentSession.value = session;
    return session;
  }

  static Future<AppLoginResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = SupabaseBootstrap.client;

    if (client == null) {
      return AppLoginResult.failure(
        'Supabase is not configured. Use a demo access code for now.',
      );
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user == null) {
        return AppLoginResult.failure('Login failed. Please try again.');
      }

      final profile = await client
          .from('profiles')
          .select('id, role, full_name, current_level, access_code')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        await client.auth.signOut();
        return AppLoginResult.failure(
          'Account found, but no app profile exists yet.',
        );
      }

      final session = _sessionFromProfile(profile, fallbackEmail: user.email);

      await _saveSession(session);
      currentSession.value = session;

      return AppLoginResult.success(session);
    } catch (error) {
      return AppLoginResult.failure(_friendlyError(error));
    }
  }

  static Future<AppLoginResult> signInWithDemoCode(String code) async {
    final normalizedCode = code.trim().toLowerCase();

    if (normalizedCode == teacherCode) {
      final session = const AppSession(
        userId: 'teacher_001',
        role: 'teacher',
        name: 'Teacher',
        level: 'A1',
        isRemote: false,
      );

      await _saveSession(session);
      currentSession.value = session;

      return AppLoginResult.success(session);
    }

    // Preferred path: if Supabase is configured, treat the access code as a real
    // credential. The student's Auth email/password are derived deterministically
    // from the code, so no password is ever shown to or typed by the student.
    final client = SupabaseBootstrap.client;
    if (client != null) {
      final remoteResult = await _signInStudentByAccessCode(normalizedCode);
      if (remoteResult != null) {
        return remoteResult;
      }
      // Fall through to local demo list only if the remote lookup found nothing,
      // so existing demo codes keep working during migration.
    }

    for (final student in studentsData) {
      if (student.accessCode.toLowerCase() == normalizedCode) {
        final session = AppSession(
          userId: student.id,
          role: 'student',
          name: student.name,
          level: student.level,
          isRemote: false,
        );

        await _saveSession(session, studentAccessCode: student.accessCode);
        currentSession.value = session;

        return AppLoginResult.success(session);
      }
    }

    return AppLoginResult.failure(
      'Invalid access code. Please check and try again.',
    );
  }

  /// Signs a student into Supabase Auth using credentials derived from their
  /// access code. Returns null (not a failure) if the code has no remote match,
  /// so the caller can fall back to the local demo list.
  static Future<AppLoginResult?> _signInStudentByAccessCode(
    String normalizedCode,
  ) async {
    final client = SupabaseBootstrap.client;
    if (client == null) return null;

    final email = studentEmailForCode(normalizedCode);
    final password = studentPasswordForCode(normalizedCode);

    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) return null;

      final profile = await client
          .from('profiles')
          .select('id, role, full_name, current_level, access_code')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        await client.auth.signOut();
        return null;
      }

      final session = AppSession(
        userId: profile['id']?.toString() ?? user.id,
        role: profile['role']?.toString() ?? 'student',
        name: profile['full_name']?.toString() ?? 'Student',
        level: profile['current_level']?.toString() ?? 'A1',
        isRemote: true,
      );

      await _saveSession(session, studentAccessCode: normalizedCode);
      currentSession.value = session;
      return AppLoginResult.success(session);
    } catch (error) {
      // Invalid-credentials here means "no such student remotely" — return null
      // so the local demo fallback can run. Only surface other errors.
      final message = error.toString().toLowerCase();
      if (message.contains('invalid login credentials')) {
        return null;
      }
      return AppLoginResult.failure(_friendlyError(error));
    }
  }

  /// Deterministic Auth email for a student access code.
  /// Example: 'test-student-1' -> 'test-student-1@students.tasilla.app'
  static String studentEmailForCode(String code) {
    final normalized = code.trim().toLowerCase();
    return '$normalized@students.tasilla.app';
  }

  /// Deterministic Auth password for a student access code, combining the code
  /// with an app-wide salt passed at build time (never committed to the repo).
  /// The same code + salt always produces the same password, so the app can
  /// authenticate without storing per-student passwords anywhere.
  static String studentPasswordForCode(String code) {
    final normalized = code.trim().toLowerCase();
    final salt = const String.fromEnvironment('STUDENT_CODE_SALT');
    final bytes = utf8.encode('$normalized::$salt');
    return sha256.convert(bytes).toString();
  }

  static Future<void> signOut() async {
    final client = SupabaseBootstrap.client;

    if (client != null) {
      await client.auth.signOut();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserRole');
    await prefs.remove('currentStudentId');
    await prefs.remove('currentStudentName');
    await prefs.remove('currentStudentLevel');
    await prefs.remove('currentStudentAccessCode');
    await prefs.remove('currentTeacherId');
    await prefs.remove('currentTeacherName');
    currentSession.value = null;
  }

  static AppSession _sessionFromProfile(
    Map<String, dynamic> profile, {
    String? fallbackEmail,
  }) {
    return AppSession(
      userId: profile['id']?.toString() ?? '',
      role: profile['role']?.toString() ?? 'student',
      name: profile['full_name']?.toString() ?? fallbackEmail ?? 'User',
      level: profile['current_level']?.toString() ?? 'A1',
      isRemote: true,
    );
  }

  static Future<void> _saveSession(
    AppSession session, {
    String? studentAccessCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('currentUserRole', session.role);

    if (session.isTeacher) {
      await prefs.setString('currentTeacherId', session.userId);
      await prefs.setString('currentTeacherName', session.name);

      await prefs.remove('currentStudentId');
      await prefs.remove('currentStudentName');
      await prefs.remove('currentStudentLevel');
      await prefs.remove('currentStudentAccessCode');
      return;
    }

    await prefs.setString('currentStudentId', session.userId);
    await prefs.setString('currentStudentName', session.name);
    await prefs.setString('currentStudentLevel', session.level);

    if (studentAccessCode != null) {
      await prefs.setString('currentStudentAccessCode', studentAccessCode);
    }

    await prefs.remove('currentTeacherId');
    await prefs.remove('currentTeacherName');
  }

  static String _friendlyError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }

    if (message.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }

    return 'Could not sign in. Please check your credentials and try again.';
  }
}

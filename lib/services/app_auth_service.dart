import 'package:shared_preferences/shared_preferences.dart';

import '../data/students_data.dart';
import '../models/app_session.dart';
import 'supabase_bootstrap.dart';

class AppAuthService {
  static const String teacherCode = 'teacher123';

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

      final session = AppSession(
        userId: profile['id']?.toString() ?? user.id,
        role: profile['role']?.toString() ?? 'student',
        name: profile['full_name']?.toString() ?? user.email ?? 'User',
        level: profile['current_level']?.toString() ?? 'A1',
        isRemote: true,
      );

      await _saveSession(session);

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

      return AppLoginResult.success(session);
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

        return AppLoginResult.success(session);
      }
    }

    return AppLoginResult.failure(
      'Invalid access code. Please check and try again.',
    );
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

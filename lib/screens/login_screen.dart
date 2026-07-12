import 'package:flutter/material.dart';

import '../models/app_session.dart';
import '../services/app_auth_service.dart';
import '../services/supabase_bootstrap.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _accessCodeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;
  bool _isTeacherMode = false;

  @override
  void dispose() {
    _accessCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLoginResult(AppLoginResult result) async {
    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage;
      });
      return;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Enter your email and password.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await AppAuthService.signInWithEmail(
      email: email,
      password: password,
    );
    await _handleLoginResult(result);
  }

  Future<void> _loginWithCode() async {
    final code = _accessCodeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Enter your access code.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final result = await AppAuthService.signInWithDemoCode(code);
    await _handleLoginResult(result);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvas = isDark ? const Color(0xFF161618) : const Color(0xFFFAFAF8);
    final textPrimary = isDark
        ? const Color(0xFFF5F5F0)
        : const Color(0xFF1A1A1A);
    final textMuted = isDark
        ? const Color(0xFF48484A)
        : const Color(0xFFAEAAA2);
    final surface = isDark ? const Color(0xFF242426) : const Color(0xFFF0EEE8);
    final border = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE4E2DC);
    final isSupabaseConfigured = SupabaseBootstrap.isConfigured;

    return Scaffold(
      backgroundColor: canvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme toggle
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => ThemeController.toggle(context),
                    child: Icon(
                      ThemeController.iconFor(context),
                      color: textMuted,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // TASILLA wordmark
                Text(
                  'TASILLA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.22 * 11,
                    color: textMuted,
                  ),
                ),

                const SizedBox(height: 16),

                // Headline
                Text(
                  _isTeacherMode
                      ? 'Teacher\nsign in.'
                      : 'Learn English\nwith your\nteacher.',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    color: textPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                // Divider line
                Container(
                  width: 28,
                  height: 1,
                  color: border,
                  margin: const EdgeInsets.symmetric(vertical: 20),
                ),

                // STUDENT: access code field
                if (!_isTeacherMode) ...[
                  _UnderlineField(
                    controller: _accessCodeController,
                    label: 'ACCESS CODE',
                    hint: 'your code',
                    obscureText: false,
                    textMuted: textMuted,
                    textPrimary: textPrimary,
                    border: border,
                    onChanged: (_) => setState(() => _errorMessage = null),
                    onSubmitted: (_) => _loginWithCode(),
                  ),
                ],

                // TEACHER: email + password fields
                if (_isTeacherMode && isSupabaseConfigured) ...[
                  _UnderlineField(
                    controller: _emailController,
                    label: 'EMAIL',
                    hint: 'you@email.com',
                    textMuted: textMuted,
                    textPrimary: textPrimary,
                    border: border,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 20),
                  _UnderlineField(
                    controller: _passwordController,
                    label: 'PASSWORD',
                    hint: '••••••',
                    obscureText: true,
                    textMuted: textMuted,
                    textPrimary: textPrimary,
                    border: border,
                    onChanged: (_) => setState(() => _errorMessage = null),
                    onSubmitted: (_) => _loginWithEmail(),
                  ),
                ],

                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppTheme.semanticRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Primary action button
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : (_isTeacherMode ? _loginWithEmail : _loginWithCode),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: _isLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? const Color(0xFF161618)
                                    : const Color(0xFFFAFAF8),
                              ),
                            )
                          : Text(
                              'ENTER →',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF161618)
                                    : const Color(0xFFFAFAF8),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.10 * 12,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Toggle teacher / student
                GestureDetector(
                  onTap: () => setState(() {
                    _isTeacherMode = !_isTeacherMode;
                    _errorMessage = null;
                  }),
                  child: Text(
                    _isTeacherMode ? 'I am a student' : 'I am a teacher',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ),

                // Demo codes hint (subtle, only in student mode)
                if (!_isTeacherMode) ...[
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEMO CODES',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.16 * 9,
                            color: textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _DemoChip(
                              label: 'joao123',
                              textMuted: textMuted,
                              border: border,
                              surface: surface,
                              onTap: () {
                                _accessCodeController.text = 'joao123';
                                setState(() => _errorMessage = null);
                              },
                            ),
                            _DemoChip(
                              label: 'maria123',
                              textMuted: textMuted,
                              border: border,
                              surface: surface,
                              onTap: () {
                                _accessCodeController.text = 'maria123';
                                setState(() => _errorMessage = null);
                              },
                            ),
                            _DemoChip(
                              label: 'ana123',
                              textMuted: textMuted,
                              border: border,
                              surface: surface,
                              onTap: () {
                                _accessCodeController.text = 'ana123';
                                setState(() => _errorMessage = null);
                              },
                            ),
                            _DemoChip(
                              label: 'teacher123',
                              textMuted: textMuted,
                              border: border,
                              surface: surface,
                              onTap: () {
                                _accessCodeController.text =
                                    AppAuthService.teacherCode;
                                setState(() => _errorMessage = null);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Status
                Center(
                  child: Text(
                    isSupabaseConfigured ? 'Connected' : 'Demo mode',
                    style: TextStyle(
                      fontSize: 10,
                      color: textMuted,
                      letterSpacing: 0.08 * 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final Color textMuted;
  final Color textPrimary;
  final Color border;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;

  const _UnderlineField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.textMuted,
    required this.textPrimary,
    required this.border,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.18 * 9,
            color: textMuted,
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: TextCapitalization.none,
          style: TextStyle(color: textPrimary, fontSize: 15),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: textMuted, fontSize: 14),
            filled: true,
            fillColor: Colors.transparent,
            border: UnderlineInputBorder(borderSide: BorderSide(color: border)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: textPrimary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _DemoChip extends StatelessWidget {
  final String label;
  final Color textMuted;
  final Color border;
  final Color surface;
  final VoidCallback onTap;

  const _DemoChip({
    required this.label,
    required this.textMuted,
    required this.border,
    required this.surface,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

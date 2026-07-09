import 'package:flutter/material.dart';

import '../../services/learning_path_progress_service.dart';
import '../../theme/app_theme.dart';
import 'student_placement_test_screen.dart';

class StudentLevelTestsScreen extends StatefulWidget {
  const StudentLevelTestsScreen({super.key});

  @override
  State<StudentLevelTestsScreen> createState() => _StudentLevelTestsScreenState();
}

class _StudentLevelTestsScreenState extends State<StudentLevelTestsScreen> {
  Set<String> validatedLevels = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadValidatedLevels();
  }

  Future<void> _loadValidatedLevels() async {
    final levels = await LearningPathProgressService.getValidatedLevels();
    if (!mounted) return;
    setState(() {
      validatedLevels = levels;
      isLoading = false;
    });
  }

  Future<void> _validateA1() async {
    if (validatedLevels.contains('A1')) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentPlacementTestScreen(level: 'A1')));
    await _loadValidatedLevels();
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
        title: Text('Placement Test', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadValidatedLevels,
        color: textPrimary,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PLACEMENT TEST', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.6, color: textMuted)),
                  const SizedBox(height: 8),
                  Text('Find your starting level', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: textPrimary, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text('Students who already know English can validate a level with a stronger test instead of repeating every lesson.', style: TextStyle(fontSize: 13, color: textMuted, height: 1.45)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (isLoading)
              Center(child: Padding(padding: const EdgeInsets.all(28), child: CircularProgressIndicator(color: textPrimary, strokeWidth: 1.5)))
            else ...[
              _levelCard(
                level: 'A1', title: 'A1 Placement Test',
                description: 'Sample test with integrated A1 questions. Score 85% or higher to validate this level and continue from the next path.',
                isValidated: validatedLevels.contains('A1'), onTap: _validateA1,
                textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
              ),
              _levelCard(
                level: 'A2', title: 'A2 Placement Test',
                description: 'Planned for the next level path. This will allow students to start at A2 when they already know A1.',
                isLocked: true,
                textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
              ),
              _levelCard(
                level: 'B1', title: 'B1 Placement Test',
                description: 'Planned for intermediate students who should not start from beginner content.',
                isLocked: true,
                textPrimary: textPrimary, textMuted: textMuted, surface: surface, border: border,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _levelCard({
    required String level,
    required String title,
    required String description,
    bool isValidated = false,
    bool isLocked = false,
    VoidCallback? onTap,
    required Color textPrimary,
    required Color textMuted,
    required Color surface,
    required Color border,
  }) {
    final statusColor = isValidated ? AppTheme.semanticGreen : isLocked ? textMuted : textPrimary;

    return GestureDetector(
      onTap: isLocked || isValidated ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Center(child: Text(level, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: statusColor))),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary)),
                  const SizedBox(height: 3),
                  Text(description, style: TextStyle(fontSize: 11, color: textMuted, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isValidated ? Icons.check_circle_outline : isLocked ? Icons.lock_outline : Icons.arrow_forward_ios_rounded,
              color: statusColor,
              size: isLocked ? 18 : 14,
            ),
          ],
        ),
      ),
    );
  }
}

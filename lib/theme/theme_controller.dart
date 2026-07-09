import 'package:flutter/material.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  static void toggle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    mode.value = isDark ? ThemeMode.light : ThemeMode.dark;
  }

  static IconData iconFor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined;
  }
}

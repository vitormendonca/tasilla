import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/supabase_bootstrap.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();

  runApp(const TasillaApp());
}

class TasillaApp extends StatelessWidget {
  const TasillaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'TASILLA',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const LoginScreen(),
        );
      },
    );
  }
}

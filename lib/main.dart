import 'package:flutter/material.dart';
import 'data/a1_content_loader.dart';
import 'screens/verify_certificate_screen.dart';
import 'services/supabase_bootstrap.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  // TASILLA A1 content: JSON assets must be in memory before any screen
  // reads the roadmap or a lesson (sync getters after this await).
  await loadA1Content();

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
          // Route-based so the public verification page is reachable by URL.
          // Flutter web's default hash strategy means the link format is:
          //     https://app.tasilla.com/#/verify/TSL-A1-XXXXX
          // Hash URLs need NO server rewrites, so they work on GitHub Pages
          // (a path like /verify/... would 404 on refresh there).
          initialRoute: '/',
          onGenerateRoute: _generateRoute,
        );
      },
    );
  }

  Route<dynamic> _generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final segments = uri.pathSegments;

    // /verify or /verify/{certificate_code} — public, no login required.
    if (segments.isNotEmpty && segments.first == 'verify') {
      final code = segments.length > 1 ? segments[1] : '';

      return MaterialPageRoute(
        settings: settings,
        builder: (_) => VerifyCertificateScreen(initialCode: code),
      );
    }

    // Everything else goes through the normal auth flow.
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const AuthGate(),
    );
  }
}

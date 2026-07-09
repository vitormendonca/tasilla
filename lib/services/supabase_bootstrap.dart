import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class SupabaseBootstrap {
  static bool _initialized = false;

  static bool get isConfigured => SupabaseConfig.isConfigured;

  static bool get isInitialized => _initialized;

  static SupabaseClient? get client {
    if (!_initialized) {
      return null;
    }

    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (!SupabaseConfig.isConfigured) {
      debugPrint('Supabase is not configured. Using local MVP data.');
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );

      _initialized = true;
    } catch (error, stackTrace) {
      debugPrint('Supabase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

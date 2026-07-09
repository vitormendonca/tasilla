class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured {
    return url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
  }
}

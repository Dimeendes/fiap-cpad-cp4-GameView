class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publicKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured => url.isNotEmpty && publicKey.isNotEmpty;
}

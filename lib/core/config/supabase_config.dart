/// Configuration Supabase
///
/// IMPORTANT: Remplacez ces valeurs par vos propres clés Supabase
/// Vous pouvez les trouver dans votre dashboard Supabase:
/// Settings > API > Project URL et anon key
class SupabaseConfig {
  SupabaseConfig._();

  /// URL du projet Supabase
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://jatdlrqkwxcqykedgmbv.supabase.co',
  );

  /// Clé anonyme Supabase (Publishable key)
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_Eej4vFT33gwbXC-Q9MuO1Q_D_yxtn0l',
  );

  /// Vérifie si la configuration est valide
  static bool get isConfigured =>
      url.contains('supabase.co') && anonKey.isNotEmpty;
}

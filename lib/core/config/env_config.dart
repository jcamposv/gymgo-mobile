/// Environment configuration for GymGo Mobile
/// Uses Dart defines for compile-time environment switching
///
/// Usage:
///   flutter run                          # Dev (default)
///   flutter run --dart-define=ENV=prod   # Production
///   flutter build apk --dart-define=ENV=prod
///   flutter build ios --dart-define=ENV=prod
class EnvConfig {
  EnvConfig._();

  // Environment from dart-define (defaults to 'dev')
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  /// Check if running in development
  static bool get isDev => environment == 'dev';

  /// Check if running in production
  static bool get isProd => environment == 'prod';

  // ===========================================================================
  // SUPABASE CONFIGURATION
  // ===========================================================================

  static String get supabaseUrl => isDev
      ? 'https://kvgeuntjhprvannjphmo.supabase.co'
      : 'https://adwwvdpysxnubdfngqku.supabase.co';

  static String get supabaseAnonKey => isDev
      ? 'sb_publishable_q7ech8Q13uL7fz8w82_uyg_AFZvegPo'
      : 'sb_publishable_58TcJMzYkzKB9ejc966Y_w_rO3Nbnb-';

  // ===========================================================================
  // WEB API CONFIGURATION
  // ===========================================================================

  static String get webApiUrl => isDev
      ? 'http://192.168.68.109:3000/api/v1'
      : 'https://api.gymgo.com/api/v1';

  static String get webApiKey => isDev
      ? 'dev_test_key_32_chars_minimum!!'
      : const String.fromEnvironment('WEB_API_KEY', defaultValue: '');

  // ===========================================================================
  // DEEP LINK CONFIGURATION
  // ===========================================================================

  static const String appScheme = 'gymgo';
  static const String appHost = 'auth';
  static const String resetPasswordPath = '/reset-password';

  /// Full deep link URL for password reset
  static String get resetPasswordDeepLink => '$appScheme://$appHost$resetPasswordPath';

  /// Supabase redirect URL for password reset
  static String get supabaseRedirectUrl => resetPasswordDeepLink;

  // ===========================================================================
  // DEBUG HELPERS
  // ===========================================================================

  /// Get environment label for display
  static String get environmentLabel => isDev ? 'DEV' : 'PROD';

  /// Print current configuration (for debugging)
  static void printConfig() {
    assert(() {
      print('┌─────────────────────────────────────');
      print('│ GymGo Environment: $environmentLabel');
      print('├─────────────────────────────────────');
      print('│ Supabase URL: $supabaseUrl');
      print('│ Web API URL: $webApiUrl');
      print('└─────────────────────────────────────');
      return true;
    }());
  }
}

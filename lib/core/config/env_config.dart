/// Environment configuration for GymGo Mobile
/// Contains Supabase credentials and API endpoints
class EnvConfig {
  EnvConfig._();

  // Supabase Configuration
  static const String supabaseUrl = 'https://adwwvdpysxnubdfngqku.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_58TcJMzYkzKB9ejc966Y_w_rO3Nbnb-';

  // Web API Configuration (for future API calls)
  static const String webApiUrl = 'http://localhost:3000/api/v1';

  // Deep Link Configuration
  static const String appScheme = 'gymgo';
  static const String appHost = 'auth';
  static const String resetPasswordPath = '/reset-password';

  // Get the full deep link URL for password reset
  static String get resetPasswordDeepLink => '$appScheme://$appHost$resetPasswordPath';

  // Supabase redirect URL for password reset
  static String get supabaseRedirectUrl => resetPasswordDeepLink;
}

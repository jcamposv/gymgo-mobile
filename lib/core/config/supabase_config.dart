import 'package:supabase_flutter/supabase_flutter.dart';
import 'env_config.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  SupabaseConfig._();

  static SupabaseClient? _client;

  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  /// Get the Supabase client
  static SupabaseClient get client {
    _client ??= Supabase.instance.client;
    return _client!;
  }

  /// Get the auth client
  static GoTrueClient get auth => client.auth;

  /// Get current user
  static User? get currentUser => auth.currentUser;

  /// Get current session
  static Session? get currentSession => auth.currentSession;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentSession != null;
}

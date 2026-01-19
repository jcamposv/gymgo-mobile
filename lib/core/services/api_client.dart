import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../config/supabase_config.dart';

/// Custom exceptions for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class RateLimitException extends ApiException {
  RateLimitException() : super('Has alcanzado el limite de solicitudes este mes', 429);
}

class AiDisabledException extends ApiException {
  AiDisabledException() : super('Las funciones de IA estan deshabilitadas', 403);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException() : super('Sesion expirada, inicia sesion de nuevo', 401);
}

/// HTTP Client for Web API calls
/// Handles authentication with X-API-Key and Bearer token
class ApiClient {
  final http.Client _client;
  final String _baseUrl;
  final String _apiKey;

  ApiClient({
    http.Client? client,
    String? baseUrl,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? EnvConfig.webApiUrl,
        _apiKey = apiKey ?? EnvConfig.webApiKey;

  /// Get headers with authentication
  Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-API-Key': _apiKey,
    };

    // Add Bearer token if user is authenticated
    final session = SupabaseConfig.currentSession;
    if (session != null) {
      headers['Authorization'] = 'Bearer ${session.accessToken}';
    }

    return headers;
  }

  /// Make a POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('$_baseUrl$endpoint');

    final response = await _client.post(
      url,
      headers: _getHeaders(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  /// Handle API response and map errors
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Extract error message
    final errorMsg = (body['error']?['message'] as String?) ?? 'Error desconocido';

    // Map specific error codes
    switch (response.statusCode) {
      case 401:
        throw UnauthorizedException();
      case 403:
        if (errorMsg.contains('AI') || errorMsg.contains('disabled')) {
          throw AiDisabledException();
        }
        throw ApiException(errorMsg, 403);
      case 429:
        throw RateLimitException();
      default:
        throw ApiException(errorMsg, response.statusCode);
    }
  }

  /// Close the client
  void dispose() {
    _client.close();
  }
}

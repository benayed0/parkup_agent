import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';

/// Auth repository
/// Handles authentication operations with the API
class AuthRepository {
  final Dio _dio = ApiClient.instance.dio;

  // Current logged-in agent (cached)
  Agent? _currentAgent;

  /// Get the current logged-in agent
  Agent? get currentAgent => _currentAgent;

  /// Check if user is logged in
  bool get isLoggedIn => _currentAgent != null;

  /// Initialize - check for saved session
  Future<void> init() async {
    final savedAgent = await authStorageService.getAgent();
    if (savedAgent != null) {
      _currentAgent = savedAgent;
    }
  }

  /// Login with username and password
  /// Returns the Agent on success, throws on failure
  Future<Agent> loginWithUsername(String username, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.agentsLogin,
        data: {
          'username': username,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;

      // API returns { success: true, data: { agent: {...} } }
      if (data['success'] == true && data['data'] != null) {
        final responseData = data['data'] as Map<String, dynamic>;

        if (responseData['agent'] != null) {
          final agent = Agent.fromJson(responseData['agent'] as Map<String, dynamic>);
          _currentAgent = agent;

          // Save to local storage
          await authStorageService.saveAgent(agent);

          // If token is returned, save and set it
          final token = responseData['token'] as String? ?? data['token'] as String?;
          if (token != null) {
            await authStorageService.saveToken(token);
            ApiClient.instance.setAuthToken(token);
          }

          return agent;
        }
      }

      throw const ApiException(
        message: 'Login failed',
        statusCode: 401,
      );
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw ApiException(
        message: message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Logout current user
  Future<void> logout() async {
    _currentAgent = null;
    ApiClient.instance.clearAuthToken();
    await authStorageService.clear();
  }

  /// Get current agent from storage (for app startup)
  Future<Agent?> getCurrentAgent() async {
    if (_currentAgent != null) return _currentAgent;

    final savedAgent = await authStorageService.getAgent();
    if (savedAgent != null) {
      _currentAgent = savedAgent;

      // Restore token if available
      final token = await authStorageService.getToken();
      if (token != null) {
        ApiClient.instance.setAuthToken(token);
      }
    }

    return _currentAgent;
  }

  /// Extract error message from Dio exception
  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? 'Login failed';
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your network.';
      case DioExceptionType.connectionError:
        return 'Cannot connect to server. Please check your network.';
      default:
        return 'Login failed. Please try again.';
    }
  }
}

/// Singleton instance for shared access
final authRepository = AuthRepository();

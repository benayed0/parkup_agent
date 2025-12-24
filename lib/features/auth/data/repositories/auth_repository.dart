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

  /// Initialize - check for saved token and fetch agent
  Future<void> init() async {
    final token = await authStorageService.getToken();
    if (token != null && token.isNotEmpty) {
      ApiClient.instance.setAuthToken(token);
      try {
        await _fetchCurrentAgent();
      } catch (_) {
        // Token is invalid, clear it
        await authStorageService.clear();
        ApiClient.instance.clearAuthToken();
      }
    }
  }

  /// Fetch current agent from API using token
  Future<Agent> _fetchCurrentAgent() async {
    final response = await _dio.get(ApiConfig.agentsMe);
    final data = response.data as Map<String, dynamic>;

    if (data['success'] == true && data['data'] != null) {
      final responseData = data['data'] as Map<String, dynamic>;
      if (responseData['agent'] != null) {
        final agent = Agent.fromJson(responseData['agent'] as Map<String, dynamic>);
        _currentAgent = agent;
        return agent;
      }
    }

    throw const ApiException(
      message: 'Failed to fetch agent',
      statusCode: 401,
    );
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

      // API returns { success: true, data: { agent: {...}, token: '...' } }
      if (data['success'] == true && data['data'] != null) {
        final responseData = data['data'] as Map<String, dynamic>;

        if (responseData['agent'] != null && responseData['token'] != null) {
          final agent = Agent.fromJson(responseData['agent'] as Map<String, dynamic>);
          final token = responseData['token'] as String;

          _currentAgent = agent;

          // Save token to local storage and set in API client
          await authStorageService.saveToken(token);
          ApiClient.instance.setAuthToken(token);

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

  /// Get current agent (for app startup)
  Future<Agent?> getCurrentAgent() async {
    if (_currentAgent != null) return _currentAgent;

    // Try to restore from token
    final token = await authStorageService.getToken();
    if (token != null && token.isNotEmpty) {
      ApiClient.instance.setAuthToken(token);
      try {
        return await _fetchCurrentAgent();
      } catch (_) {
        // Token is invalid, clear it
        await authStorageService.clear();
        ApiClient.instance.clearAuthToken();
      }
    }

    return null;
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

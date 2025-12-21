import 'package:dio/dio.dart';
import 'api_config.dart';

/// API Client
/// Singleton Dio instance for all API calls
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add logging interceptor for debug
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  /// Get singleton instance
  static ApiClient get instance {
    _instance ??= ApiClient._();
    return _instance!;
  }

  /// Get Dio instance
  Dio get dio => _dio;

  /// Set auth token for authenticated requests
  void setAuthToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  /// Clear auth token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}

import 'package:dio/dio.dart';
import '../services/connectivity_service.dart';

/// Dio interceptor that fails fast when offline
/// Rejects requests immediately instead of waiting for timeout
class ConnectivityInterceptor extends QueuedInterceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!connectivityService.isConnected) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'No internet connection',
        ),
      );
      return;
    }
    handler.next(options);
  }
}

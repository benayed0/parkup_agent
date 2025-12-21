/// Generic API Response wrapper
/// Matches the backend response format
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? count;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.count,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      message: json['message'] as String?,
      count: json['count'] as int?,
    );
  }
}

/// API Exception for error handling
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

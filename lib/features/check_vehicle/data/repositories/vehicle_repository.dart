import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';

/// Vehicle repository
/// Handles vehicle check operations with the API
class VehicleRepository {
  final Dio _dio = ApiClient.instance.dio;

  /// Check a vehicle by structured license plate
  /// Calls the API to check for active parking sessions
  Future<VehicleCheckResult> checkVehicle(LicensePlate plate) async {
    try {
      // Check for active parking sessions with structured plate data
      final response = await _dio.post(
        ApiConfig.checkVehicle,
        data: {
          'plate': plate.toJson(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      final sessions = (data['data'] as List?)
              ?.map((s) => ParkingSession.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [];

      if (sessions.isEmpty) {
        // No active session found
        return VehicleCheckResult(
          licensePlate: plate.formatted,
          status: VehicleStatus.notFound,
          message: 'No active parking session found for this vehicle',
          checkedAt: DateTime.now(),
        );
      }

      // Sort sessions by endTime descending to get the one with latest end time
      sessions.sort((a, b) => b.endTime.compareTo(a.endTime));

      // Get the session with the latest end time
      final session = sessions.first;

      // Check if session is expired (time-based check)
      if (session.isExpired) {
        final expiredMinutesAgo = DateTime.now().difference(session.endTime).inMinutes;
        return VehicleCheckResult(
          licensePlate: plate.formatted,
          status: VehicleStatus.expired,
          message: 'Parking session expired ${_formatExpiredTime(expiredMinutesAgo)}',
          activeSession: session,
          checkedAt: DateTime.now(),
        );
      }

      // Valid active session
      return VehicleCheckResult(
        licensePlate: plate.formatted,
        status: VehicleStatus.valid,
        message: 'Parking is valid until ${_formatTime(session.endTime)}',
        activeSession: session,
        checkedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      // Handle 404 - no session found
      if (e.response?.statusCode == 404) {
        return VehicleCheckResult(
          licensePlate: plate.formatted,
          status: VehicleStatus.notFound,
          message: 'No parking session found for this vehicle',
          checkedAt: DateTime.now(),
        );
      }

      // Re-throw other errors
      final message = _extractErrorMessage(e);
      throw ApiException(
        message: message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Format expired time ago
  String _formatExpiredTime(int minutesAgo) {
    if (minutesAgo < 1) return 'just now';
    if (minutesAgo < 60) return '$minutesAgo minutes ago';
    final hours = minutesAgo ~/ 60;
    if (hours < 24) return '$hours hour${hours > 1 ? 's' : ''} ago';
    final days = hours ~/ 24;
    return '$days day${days > 1 ? 's' : ''} ago';
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    final hour = time.toLocal().hour.toString().padLeft(2, '0');
    final minute = time.toLocal().minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Extract error message from Dio exception
  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? 'Failed to check vehicle';
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
        return 'Failed to check vehicle. Please try again.';
    }
  }
}

/// Singleton instance
final vehicleRepository = VehicleRepository();

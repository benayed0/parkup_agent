import 'package:dio/dio.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';

/// Vehicle repository
/// Handles vehicle check and badge operations with the API
class VehicleRepository {
  final Dio _dio = ApiClient.instance.dio;

  /// Check a vehicle by structured license plate
  /// Calls POST /vehicles/check — returns active session + current-year badge
  Future<VehicleCheckResult> checkVehicle(LicensePlate plate, {String? zoneId}) async {
    try {
      final response = await _dio.post(
        ApiConfig.vehiclesCheck,
        data: {
          'plate': plate.toJson(),
          if (zoneId != null) 'zoneId': zoneId,
        },
      );

      final data = response.data['data'] as Map<String, dynamic>;

      // Parse badge (may be null)
      final badgeJson = data['badge'] as Map<String, dynamic>?;
      final badge = badgeJson != null ? LicensePlateBadge.fromJson(badgeJson) : null;

      // Parse active session (may be null)
      final sessionJson = data['activeParkingSession'] as Map<String, dynamic>?;

      if (sessionJson == null) {
        return VehicleCheckResult(
          licensePlate: plate.formatted,
          status: VehicleStatus.notFound,
          message: 'No active parking session found for this vehicle',
          badge: badge,
          checkedAt: DateTime.now(),
        );
      }

      final session = ParkingSession.fromJson(sessionJson);

      if (session.isExpired) {
        final expiredMinutesAgo =
            DateTime.now().difference(session.endTime).inMinutes;
        return VehicleCheckResult(
          licensePlate: plate.formatted,
          status: VehicleStatus.expired,
          message: 'Parking session expired ${_formatExpiredTime(expiredMinutesAgo)}',
          activeSession: session,
          badge: badge,
          checkedAt: DateTime.now(),
        );
      }

      return VehicleCheckResult(
        licensePlate: plate.formatted,
        status: VehicleStatus.valid,
        message: 'Parking is valid until ${_formatTime(session.endTime)}',
        activeSession: session,
        badge: badge,
        checkedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return VehicleCheckResult(
          licensePlate: plate.formatted,
          status: VehicleStatus.notFound,
          message: 'No parking session found for this vehicle',
          checkedAt: DateTime.now(),
        );
      }
      final message = _extractErrorMessage(e);
      throw ApiException(
        message: message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Add a badge to a license plate for the current year
  /// Calls POST /license-plate-badges — agent JWT required
  Future<LicensePlateBadge> addBadge(
    LicensePlate plate, {
    required String zoneId,
    required String zoneName,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.licensePlateBadges,
        data: {
          'plate': plate.toJson(),
          'zoneId': zoneId,
          'zoneName': zoneName,
        },
      );
      return LicensePlateBadge.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw ApiException(
        message: message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Invalidate (soft-delete) a badge
  /// Calls PATCH /license-plate-badges/:id/invalidate — agent JWT required
  Future<void> invalidateBadge(String badgeId) async {
    try {
      await _dio.patch(ApiConfig.licensePlateBadgeInvalidate(badgeId));
    } on DioException catch (e) {
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
        return data['message'] as String? ?? 'Request failed';
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
        return 'Request failed. Please try again.';
    }
  }
}

/// Singleton instance
final vehicleRepository = VehicleRepository();

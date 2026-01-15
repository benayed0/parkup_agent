import '../../../../core/network/api_client.dart';
import '../../../../shared/models/parking_session.dart';

/// Repository for fetching active parking sessions
class ActiveSessionsRepository {
  final _apiClient = ApiClient.instance;

  /// Fetch active sessions for a specific zone
  Future<List<ParkingSession>> getActiveSessionsByZone(String zoneId) async {
    final response = await _apiClient.dio.get(
      '/parking-sessions/zone/$zoneId/active',
    );

    final data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => ParkingSession.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch active sessions for multiple zones
  Future<List<ParkingSession>> getActiveSessionsForZones(
    List<String> zoneIds,
  ) async {
    final allSessions = <ParkingSession>[];

    for (final zoneId in zoneIds) {
      try {
        final sessions = await getActiveSessionsByZone(zoneId);
        allSessions.addAll(sessions);
      } catch (_) {
        // Continue with other zones if one fails
      }
    }

    return allSessions;
  }
}

/// Global singleton instance
final activeSessionsRepository = ActiveSessionsRepository();

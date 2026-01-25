import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../shared/models/models.dart';

/// Repository for fetching enforcement data (expired and expiring sessions)
class ActiveSessionsRepository {
  final _apiClient = ApiClient.instance;

  /// Fetch enforcement data for agents
  /// Returns expired sessions and soon-to-expire sessions
  /// Set includeTicketed=true to also show sessions that already have tickets
  Future<EnforcementData> getEnforcementData({
    String? zoneId,
    int expiringThresholdMinutes = 15,
    int limit = 50,
    bool includeTicketed = false,
  }) async {
    final queryParams = <String, dynamic>{
      'expiringThresholdMinutes': expiringThresholdMinutes.toString(),
      'limit': limit.toString(),
    };
    if (zoneId != null) {
      queryParams['zoneId'] = zoneId;
    }
    if (includeTicketed) {
      queryParams['includeTicketed'] = 'true';
    }

    final response = await _apiClient.dio.get(
      ApiConfig.agentEnforcement,
      queryParameters: queryParams,
    );

    return EnforcementData.fromJson(response.data as Map<String, dynamic>);
  }

  /// Fetch active sessions for a specific zone (legacy method)
  Future<List<ParkingSession>> getActiveSessionsByZone(String zoneId) async {
    final response = await _apiClient.dio.get(
      '/parking-sessions/zone/$zoneId/active',
    );

    final data = response.data['data'] as List<dynamic>;
    return data
        .map((json) => ParkingSession.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch active sessions for multiple zones (legacy method)
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

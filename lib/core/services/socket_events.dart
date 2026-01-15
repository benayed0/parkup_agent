import '../../shared/models/parking_session.dart';

/// Connection status for socket service
enum ConnectionStatus {
  connected,
  disconnected,
  reconnecting,
  reconnected,
  error,
}

/// Event emitted when a session is about to expire
class ExpiringSessionEvent {
  final ParkingSession session;
  final int minutesRemaining;
  final String warningLevel; // 'warning' or 'critical'

  const ExpiringSessionEvent({
    required this.session,
    required this.minutesRemaining,
    required this.warningLevel,
  });

  factory ExpiringSessionEvent.fromJson(Map<String, dynamic> json) {
    return ExpiringSessionEvent(
      session: ParkingSession.fromJson(json['session'] as Map<String, dynamic>),
      minutesRemaining: json['minutesRemaining'] as int,
      warningLevel: json['warningLevel'] as String,
    );
  }

  bool get isCritical => warningLevel == 'critical';
}

/// Event emitted when a session ends
class SessionEndedEvent {
  final String sessionId;
  final String zoneId;
  final String reason; // 'completed', 'cancelled', 'expired'

  const SessionEndedEvent({
    required this.sessionId,
    required this.zoneId,
    required this.reason,
  });

  factory SessionEndedEvent.fromJson(Map<String, dynamic> json) {
    return SessionEndedEvent(
      sessionId: json['sessionId'] as String,
      zoneId: json['zoneId'] as String,
      reason: json['reason'] as String,
    );
  }
}

/// Socket event names matching backend
class SocketEvents {
  // Client to Server
  static const String zoneJoin = 'zone:join';
  static const String zoneLeave = 'zone:leave';
  static const String zoneSwitch = 'zone:switch';

  // Server to Client
  static const String sessionCreated = 'session:created';
  static const String sessionUpdated = 'session:updated';
  static const String sessionExpiring = 'session:expiring';
  static const String sessionEnded = 'session:ended';
  static const String zoneSnapshot = 'zone:snapshot';
  static const String connectionStatus = 'connection:status';
  static const String error = 'error';
}

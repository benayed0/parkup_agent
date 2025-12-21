/// Parking session status enum
enum SessionStatus {
  active('active'),
  completed('completed'),
  expired('expired'),
  cancelled('cancelled');

  final String value;

  const SessionStatus(this.value);

  static SessionStatus fromValue(String value) {
    return SessionStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => SessionStatus.active,
    );
  }
}

/// Parking session model
/// Represents an active or past parking session
class ParkingSession {
  final String id;
  final String? userId;
  final String zoneId;
  final String zoneName;
  final String licensePlate;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final double amount;
  final SessionStatus status;
  final double? latitude;
  final double? longitude;

  const ParkingSession({
    required this.id,
    this.userId,
    required this.zoneId,
    required this.zoneName,
    required this.licensePlate,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.amount,
    required this.status,
    this.latitude,
    this.longitude,
  });

  /// Create from JSON (API response)
  factory ParkingSession.fromJson(Map<String, dynamic> json) {
    // Extract coordinates from location GeoJSON
    double? lat;
    double? lng;
    if (json['location'] != null) {
      final coords = json['location']['coordinates'] as List?;
      if (coords != null && coords.length >= 2) {
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    }

    return ParkingSession(
      id: json['_id'] as String? ?? json['id'] as String,
      userId: json['userId'] is String
          ? json['userId'] as String
          : (json['userId']?['_id'] as String?),
      zoneId: json['zoneId'] is String
          ? json['zoneId'] as String
          : (json['zoneId']?['_id'] as String? ?? ''),
      zoneName: json['zoneName'] as String? ?? '',
      licensePlate: json['licensePlate'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      durationMinutes: json['durationMinutes'] as int,
      amount: (json['amount'] as num).toDouble(),
      status: SessionStatus.fromValue(json['status'] as String),
      latitude: lat,
      longitude: lng,
    );
  }

  /// Check if session is currently active
  bool get isActive => status == SessionStatus.active;

  /// Check if session has expired
  bool get isExpired {
    if (status == SessionStatus.expired) return true;
    if (status == SessionStatus.active && DateTime.now().isAfter(endTime)) {
      return true;
    }
    return false;
  }

  /// Get remaining time in minutes (negative if expired)
  int get remainingMinutes {
    final diff = endTime.difference(DateTime.now()).inMinutes;
    return diff;
  }
}

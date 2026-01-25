/// Enforcement session category
enum EnforcementCategory {
  expired('expired'),
  expiringSoon('expiring_soon');

  final String value;

  const EnforcementCategory(this.value);

  static EnforcementCategory fromValue(String value) {
    return EnforcementCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EnforcementCategory.expired,
    );
  }
}

/// Location source enum for location confidence
enum LocationSource {
  gpsAuto('gps_auto'),
  userPin('user_pin'),
  zoneCentroid('zone_centroid'),
  unknown('unknown');

  final String value;

  const LocationSource(this.value);

  static LocationSource fromValue(String? value) {
    if (value == null) return LocationSource.unknown;
    return LocationSource.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LocationSource.unknown,
    );
  }
}

/// Enforcement session model
/// Represents a session that is either expired or expiring soon
class EnforcementSession {
  final String id;
  final String licensePlate;
  final Map<String, dynamic>? plate;
  final String zoneName;
  final String zoneId;
  final DateTime endTime;
  final EnforcementCategory category;
  final double? latitude;
  final double? longitude;

  // For expired sessions
  final int? minutesOverdue;
  final bool? hasTicket;

  // For expiring_soon sessions
  final int? minutesRemaining;

  // Location confidence fields
  final LocationSource locationSource;
  final bool locationWithinZone;
  final List<List<double>>? zoneBoundaries;
  final double? zoneLatitude; // Zone centroid for fallback
  final double? zoneLongitude;

  const EnforcementSession({
    required this.id,
    required this.licensePlate,
    this.plate,
    required this.zoneName,
    required this.zoneId,
    required this.endTime,
    required this.category,
    this.latitude,
    this.longitude,
    this.minutesOverdue,
    this.hasTicket,
    this.minutesRemaining,
    this.locationSource = LocationSource.unknown,
    this.locationWithinZone = false,
    this.zoneBoundaries,
    this.zoneLatitude,
    this.zoneLongitude,
  });

  factory EnforcementSession.fromJson(Map<String, dynamic> json) {
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

    // Extract zone centroid from zoneLocation GeoJSON
    double? zoneLat;
    double? zoneLng;
    if (json['zoneLocation'] != null) {
      final coords = json['zoneLocation']['coordinates'] as List?;
      if (coords != null && coords.length >= 2) {
        zoneLng = (coords[0] as num).toDouble();
        zoneLat = (coords[1] as num).toDouble();
      }
    }

    // Parse zone boundaries
    List<List<double>>? zoneBoundaries;
    if (json['zoneBoundaries'] != null) {
      final boundaries = json['zoneBoundaries'] as List;
      zoneBoundaries = boundaries.map<List<double>>((point) {
        final coords = point as List;
        return [
          (coords[0] as num).toDouble(),
          (coords[1] as num).toDouble(),
        ];
      }).toList();
    }

    return EnforcementSession(
      id: json['id'] as String,
      licensePlate: json['licensePlate'] as String,
      plate: json['plate'] as Map<String, dynamic>?,
      zoneName: json['zoneName'] as String? ?? '',
      zoneId: json['zoneId'] as String,
      endTime: DateTime.parse(json['endTime'] as String),
      category: EnforcementCategory.fromValue(json['category'] as String),
      latitude: lat,
      longitude: lng,
      minutesOverdue: json['minutesOverdue'] as int?,
      hasTicket: json['hasTicket'] as bool?,
      minutesRemaining: json['minutesRemaining'] as int?,
      locationSource: LocationSource.fromValue(json['locationSource'] as String?),
      locationWithinZone: json['locationWithinZone'] as bool? ?? false,
      zoneBoundaries: zoneBoundaries,
      zoneLatitude: zoneLat,
      zoneLongitude: zoneLng,
    );
  }

  /// Check if this is an expired session
  bool get isExpired => category == EnforcementCategory.expired;

  /// Check if this session already has a ticket
  bool get alreadyTicketed => hasTicket == true;

  /// Get display text for time status
  String get timeStatusText {
    if (isExpired) {
      return '${minutesOverdue ?? 0} min overdue';
    } else {
      return '${minutesRemaining ?? 0} min left';
    }
  }

  /// Check if this session has high confidence location (GPS + within zone)
  bool get hasHighConfidenceLocation =>
      locationSource == LocationSource.gpsAuto && locationWithinZone;

  /// Check if this session has medium confidence location (user placed pin)
  bool get hasMediumConfidenceLocation =>
      locationSource == LocationSource.userPin;

  /// Check if this session has low confidence location (zone centroid or unknown)
  bool get hasLowConfidenceLocation =>
      locationSource == LocationSource.zoneCentroid ||
      locationSource == LocationSource.unknown;

  /// Check if GPS location is outside the zone (warning state)
  bool get isLocationOutsideZone =>
      locationSource == LocationSource.gpsAuto && !locationWithinZone;

  /// Get display coordinates (use zone centroid as fallback for low confidence)
  double? get displayLatitude {
    if (hasLowConfidenceLocation && latitude == null) {
      return zoneLatitude;
    }
    return latitude;
  }

  double? get displayLongitude {
    if (hasLowConfidenceLocation && longitude == null) {
      return zoneLongitude;
    }
    return longitude;
  }

  /// Get location confidence text for UI display
  String get locationConfidenceText {
    switch (locationSource) {
      case LocationSource.gpsAuto:
        return locationWithinZone ? 'GPS location' : 'GPS (outside zone)';
      case LocationSource.userPin:
        return 'User-placed location';
      case LocationSource.zoneCentroid:
        return 'Zone only (no precise location)';
      case LocationSource.unknown:
        return 'Location unknown';
    }
  }
}

/// Enforcement data response
/// Contains expired and expiring soon sessions with summary
class EnforcementData {
  final List<EnforcementSession> expired;
  final List<EnforcementSession> expiringSoon;
  final int totalExpired;
  final int totalExpiringSoon;
  final int expiredWithoutTicket;

  const EnforcementData({
    required this.expired,
    required this.expiringSoon,
    required this.totalExpired,
    required this.totalExpiringSoon,
    required this.expiredWithoutTicket,
  });

  factory EnforcementData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final summary = data['summary'] as Map<String, dynamic>;

    return EnforcementData(
      expired: (data['expired'] as List)
          .map((e) => EnforcementSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      expiringSoon: (data['expiringSoon'] as List)
          .map((e) => EnforcementSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalExpired: summary['totalExpired'] as int,
      totalExpiringSoon: summary['totalExpiringSoon'] as int,
      expiredWithoutTicket: summary['expiredWithoutTicket'] as int,
    );
  }

  /// Get all sessions combined (expired first, then expiring soon)
  List<EnforcementSession> get allSessions => [...expired, ...expiringSoon];

  /// Total count of all sessions
  int get totalCount => totalExpired + totalExpiringSoon;
}

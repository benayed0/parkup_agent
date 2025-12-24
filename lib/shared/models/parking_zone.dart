import 'ticket.dart';

/// Parking zone model
/// Represents a parking zone with pricing information
class ParkingZone {
  final String id;
  final String code;
  final String name;
  final double hourlyRate;
  final ZonePrices prices;
  final Position? location;
  final String? description;
  final bool isActive;

  const ParkingZone({
    required this.id,
    required this.code,
    required this.name,
    required this.hourlyRate,
    required this.prices,
    this.location,
    this.description,
    this.isActive = true,
  });

  /// Create from JSON (API response)
  factory ParkingZone.fromJson(Map<String, dynamic> json) {
    Position? location;
    if (json['location'] != null) {
      final loc = json['location'] as Map<String, dynamic>;
      final coords = loc['coordinates'] as List<dynamic>?;
      if (coords != null && coords.length >= 2) {
        location = Position(
          longitude: (coords[0] as num).toDouble(),
          latitude: (coords[1] as num).toDouble(),
        );
      }
    }

    return ParkingZone(
      id: json['_id'] as String? ?? json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      prices: ZonePrices.fromJson(json['prices'] as Map<String, dynamic>),
      location: location,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'hourlyRate': hourlyRate,
      'prices': prices.toJson(),
      'location': location?.toJson(),
      'description': description,
      'isActive': isActive,
    };
  }
}

/// Zone prices for different ticket reasons
class ZonePrices {
  final double carSabot;
  final double pound;

  const ZonePrices({
    required this.carSabot,
    required this.pound,
  });

  factory ZonePrices.fromJson(Map<String, dynamic> json) {
    return ZonePrices(
      carSabot: (json['car_sabot'] as num).toDouble(),
      pound: (json['pound'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'car_sabot': carSabot,
      'pound': pound,
    };
  }
}

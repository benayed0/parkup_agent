import 'parking_zone.dart';

/// Agent model
/// Represents a parking agent user
class Agent {
  final String id;
  final String name;
  final String username;
  final String? phone;
  final bool isActive;
  final List<ParkingZone>? assignedZones;

  const Agent({
    required this.id,
    required this.name,
    required this.username,
    this.phone,
    this.isActive = true,
    this.assignedZones,
  });

  /// Get assigned zone IDs
  List<String>? get assignedZoneIds => assignedZones?.map((z) => z.id).toList();

  /// Create from JSON (API response)
  factory Agent.fromJson(Map<String, dynamic> json) {
    // Parse assignedZones - can be list of IDs or populated objects
    final zonesRaw = json['assignedZones'] as List<dynamic>?;
    List<ParkingZone>? zones;
    if (zonesRaw != null) {
      zones = zonesRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => ParkingZone.fromJson(e))
          .toList();
    }

    return Agent(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      assignedZones: zones,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'phone': phone,
      'isActive': isActive,
      'assignedZones': assignedZones?.map((z) => z.toJson()).toList(),
    };
  }

  /// Create a copy with modified fields
  Agent copyWith({
    String? id,
    String? name,
    String? username,
    String? phone,
    bool? isActive,
    List<ParkingZone>? assignedZones,
  }) {
    return Agent(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      assignedZones: assignedZones ?? this.assignedZones,
    );
  }
}

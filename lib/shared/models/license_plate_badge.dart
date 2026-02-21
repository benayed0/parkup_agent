/// Badge status enum
enum BadgeStatus {
  active,
  invalidated,
}

/// LicensePlateBadge model
/// Represents a yearly zone-specific parking permit issued by an agent
class LicensePlateBadge {
  final String id;
  final String licensePlate;
  final String zoneId;
  final String zoneName;
  final int year;
  final String agentId;
  final BadgeStatus status;
  final DateTime createdAt;
  final DateTime? invalidatedAt;

  const LicensePlateBadge({
    required this.id,
    required this.licensePlate,
    required this.zoneId,
    required this.zoneName,
    required this.year,
    required this.agentId,
    required this.status,
    required this.createdAt,
    this.invalidatedAt,
  });

  bool get isActive => status == BadgeStatus.active;

  factory LicensePlateBadge.fromJson(Map<String, dynamic> json) {
    return LicensePlateBadge(
      id: json['_id'] as String? ?? json['id'] as String,
      licensePlate: json['licensePlate'] as String,
      zoneId: (json['zoneId'] is Map)
          ? (json['zoneId'] as Map<String, dynamic>)['_id'] as String
          : json['zoneId'] as String,
      zoneName: json['zoneName'] as String,
      year: (json['year'] as num).toInt(),
      agentId: (json['agentId'] is Map)
          ? (json['agentId'] as Map<String, dynamic>)['_id'] as String
          : json['agentId'] as String,
      status: json['status'] == 'active'
          ? BadgeStatus.active
          : BadgeStatus.invalidated,
      createdAt: DateTime.parse(json['createdAt'] as String),
      invalidatedAt: json['invalidatedAt'] != null
          ? DateTime.parse(json['invalidatedAt'] as String)
          : null,
    );
  }
}

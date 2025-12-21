/// Agent model
/// Represents a parking agent user
class Agent {
  final String id;
  final String agentCode;
  final String name;
  final String username;
  final String? phone;
  final bool isActive;
  final List<String>? assignedZoneIds;

  const Agent({
    required this.id,
    required this.agentCode,
    required this.name,
    required this.username,
    this.phone,
    this.isActive = true,
    this.assignedZoneIds,
  });

  /// Create from JSON (API response)
  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['_id'] as String? ?? json['id'] as String,
      agentCode: json['agentCode'] as String,
      name: json['name'] as String,
      username: json['username'] as String,
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      assignedZoneIds: (json['assignedZones'] as List<dynamic>?)
          ?.map((e) => e is String ? e : (e['_id'] as String))
          .toList(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agentCode': agentCode,
      'name': name,
      'username': username,
      'phone': phone,
      'isActive': isActive,
      'assignedZones': assignedZoneIds,
    };
  }

  /// Create a copy with modified fields
  Agent copyWith({
    String? id,
    String? agentCode,
    String? name,
    String? username,
    String? phone,
    bool? isActive,
    List<String>? assignedZoneIds,
  }) {
    return Agent(
      id: id ?? this.id,
      agentCode: agentCode ?? this.agentCode,
      name: name ?? this.name,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      assignedZoneIds: assignedZoneIds ?? this.assignedZoneIds,
    );
  }
}

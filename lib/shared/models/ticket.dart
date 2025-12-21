/// Ticket reason enum matching backend
enum TicketReason {
  noSession('no_session', 'No Session'),
  expiredSession('expired_session', 'Expired Session'),
  overstayed('overstayed', 'Overstayed'),
  wrongZone('wrong_zone', 'Wrong Zone');

  final String value;
  final String label;

  const TicketReason(this.value, this.label);

  static TicketReason fromValue(String value) {
    return TicketReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TicketReason.noSession,
    );
  }
}

/// Ticket status enum matching backend
enum TicketStatus {
  pending('pending', 'Pending'),
  paid('paid', 'Paid'),
  appealed('appealed', 'Appealed'),
  dismissed('dismissed', 'Dismissed'),
  overdue('overdue', 'Overdue');

  final String value;
  final String label;

  const TicketStatus(this.value, this.label);

  static TicketStatus fromValue(String value) {
    return TicketStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TicketStatus.pending,
    );
  }
}

/// Position model for GeoJSON Point
class Position {
  final double longitude;
  final double latitude;

  const Position({
    required this.longitude,
    required this.latitude,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as List<dynamic>;
    return Position(
      longitude: (coords[0] as num).toDouble(),
      latitude: (coords[1] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'Point',
      'coordinates': [longitude, latitude],
    };
  }
}

/// Ticket model
/// Represents a parking ticket issued by an agent
class Ticket {
  final String id;
  final String ticketNumber;
  final String licensePlate;
  final Position position;
  final String? address;
  final TicketReason reason;
  final TicketStatus status;
  final double fineAmount;
  final DateTime issuedAt;
  final DateTime dueDate;
  final String agentId;
  final String? notes;
  final List<String>? evidencePhotos;
  final DateTime? paidAt;
  final String? appealReason;

  const Ticket({
    required this.id,
    required this.ticketNumber,
    required this.licensePlate,
    required this.position,
    this.address,
    required this.reason,
    required this.status,
    required this.fineAmount,
    required this.issuedAt,
    required this.dueDate,
    required this.agentId,
    this.notes,
    this.evidencePhotos,
    this.paidAt,
    this.appealReason,
  });

  /// Create from JSON (API response)
  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['_id'] as String? ?? json['id'] as String,
      ticketNumber: json['ticketNumber'] as String,
      licensePlate: json['licensePlate'] as String,
      position: Position.fromJson(json['position'] as Map<String, dynamic>),
      address: json['address'] as String?,
      reason: TicketReason.fromValue(json['reason'] as String),
      status: TicketStatus.fromValue(json['status'] as String),
      fineAmount: (json['fineAmount'] as num).toDouble(),
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      agentId: json['agentId'] is String
          ? json['agentId'] as String
          : (json['agentId']['_id'] as String),
      notes: json['notes'] as String?,
      evidencePhotos: (json['evidencePhotos'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      appealReason: json['appealReason'] as String?,
    );
  }

  /// Convert to JSON for creating a ticket
  Map<String, dynamic> toCreateJson() {
    return {
      'position': position.toJson(),
      'address': address,
      'licensePlate': licensePlate,
      'reason': reason.value,
      'fineAmount': fineAmount,
      'issuedAt': issuedAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'agentId': agentId,
      'notes': notes,
      'evidencePhotos': evidencePhotos,
    };
  }

  /// Get human-readable reason
  String get reasonLabel => reason.label;

  /// Get human-readable status
  String get statusLabel => status.label;

  /// Check if ticket is unpaid
  bool get isUnpaid =>
      status == TicketStatus.pending || status == TicketStatus.overdue;
}

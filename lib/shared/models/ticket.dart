import '../../core/widgets/license_plate_input.dart';
import 'printable_ticket.dart';

/// Ticket reason enum matching backend
enum TicketReason {
  carSabot('car_sabot', 'Car Sabot'),
  pound('pound', 'Pound');

  final String value;
  final String label;

  const TicketReason(this.value, this.label);

  /// Fine amounts for each reason
  double get fineAmount {
    switch (this) {
      case TicketReason.carSabot:
        return 50.0;
      case TicketReason.pound:
        return 100.0;
    }
  }

  static TicketReason fromValue(String value) {
    return TicketReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TicketReason.carSabot,
    );
  }
}

/// Ticket status enum matching backend
enum TicketStatus {
  pending('pending', 'Pending'),
  paid('paid', 'Paid'),
  removed('removed', 'Removed'),
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

/// Parking zone info (populated from ticket response)
class ParkingZoneInfo {
  final String id;
  final String name;
  final String? address;
  final String? phoneNumber;

  const ParkingZoneInfo({
    required this.id,
    required this.name,
    this.address,
    this.phoneNumber,
  });

  factory ParkingZoneInfo.fromJson(Map<String, dynamic> json) {
    return ParkingZoneInfo(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
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
  final LicensePlate plate;
  final Position position;
  final String? address;
  final TicketReason reason;
  final TicketStatus status;
  final double fineAmount;
  final DateTime issuedAt;
  final DateTime dueDate;
  final String agentId;
  final String? parkingZoneId;
  final ParkingZoneInfo? parkingZone; // Populated zone data
  final String? notes;
  final List<String>? evidencePhotos;
  final DateTime? paidAt;
  final String? appealReason;
  final QrCodeData? qrCode;

  const Ticket({
    required this.id,
    required this.ticketNumber,
    required this.licensePlate,
    required this.plate,
    required this.position,
    this.address,
    required this.reason,
    required this.status,
    required this.fineAmount,
    required this.issuedAt,
    required this.dueDate,
    required this.agentId,
    this.parkingZoneId,
    this.parkingZone,
    this.notes,
    this.evidencePhotos,
    this.paidAt,
    this.appealReason,
    this.qrCode,
  });

  /// Create from JSON (API response)
  factory Ticket.fromJson(Map<String, dynamic> json) {
    // Parse parking zone - can be string ID or populated object
    String? parkingZoneId;
    ParkingZoneInfo? parkingZone;
    if (json['parkingZoneId'] != null) {
      if (json['parkingZoneId'] is String) {
        parkingZoneId = json['parkingZoneId'] as String;
      } else {
        final zoneJson = json['parkingZoneId'] as Map<String, dynamic>;
        parkingZoneId = zoneJson['_id'] as String;
        parkingZone = ParkingZoneInfo.fromJson(zoneJson);
      }
    }

    // Parse structured plate data, fallback to licensePlate string
    final plateJson = json['plate'] as Map<String, dynamic>?;
    final licensePlateStr = json['licensePlate'] as String;
    final plate = plateJson != null
        ? LicensePlate.fromJson(plateJson)
        : LicensePlate(type: PlateType.tunis, left: licensePlateStr);

    return Ticket(
      id: json['_id'] as String? ?? json['id'] as String,
      ticketNumber: json['ticketNumber'] as String,
      licensePlate: licensePlateStr,
      plate: plate,
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
      parkingZoneId: parkingZoneId,
      parkingZone: parkingZone,
      notes: json['notes'] as String?,
      evidencePhotos: (json['evidencePhotos'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      appealReason: json['appealReason'] as String?,
      qrCode: json['qrCode'] != null
          ? QrCodeData.fromJson(json['qrCode'] as Map<String, dynamic>)
          : null,
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
      'parkingZoneId': parkingZoneId,
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

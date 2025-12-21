import 'parking_session.dart';
import 'ticket.dart';

/// Vehicle check result status
enum VehicleStatus {
  valid,      // Has active, non-expired session
  expired,    // Has expired session
  notFound,   // No session found
  hasTickets, // Has unpaid tickets
}

/// VehicleCheckResult model
/// Represents the result of checking a vehicle's parking status
class VehicleCheckResult {
  final String licensePlate;
  final VehicleStatus status;
  final String message;
  final ParkingSession? activeSession;
  final List<Ticket> unpaidTickets;
  final DateTime checkedAt;

  const VehicleCheckResult({
    required this.licensePlate,
    required this.status,
    required this.message,
    this.activeSession,
    this.unpaidTickets = const [],
    required this.checkedAt,
  });

  /// Check if the vehicle parking is valid
  bool get isValid => status == VehicleStatus.valid;

  /// Check if the vehicle has any issue
  bool get hasIssue =>
      status == VehicleStatus.expired ||
      status == VehicleStatus.notFound ||
      status == VehicleStatus.hasTickets;

  /// Get a human-readable status text
  String get statusText {
    switch (status) {
      case VehicleStatus.valid:
        return 'Valid';
      case VehicleStatus.expired:
        return 'Expired';
      case VehicleStatus.notFound:
        return 'No Session';
      case VehicleStatus.hasTickets:
        return 'Has Unpaid Tickets';
    }
  }

  /// Get remaining parking time (if valid session)
  String? get remainingTime {
    if (activeSession == null || !activeSession!.isActive) return null;

    final remaining = activeSession!.remainingMinutes;
    if (remaining <= 0) return 'Expired';

    if (remaining >= 60) {
      final hours = remaining ~/ 60;
      final mins = remaining % 60;
      return '${hours}h ${mins}m';
    }
    return '${remaining}m';
  }
}

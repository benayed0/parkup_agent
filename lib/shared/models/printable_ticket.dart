import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';
import 'ticket.dart';

/// Line type for styling in the UI
enum PrintLineType {
  header,
  plate,
  amount,
  date,
  status,
  text,
  phone,
  coordinates,
  footer,
}

/// A single line in the printable ticket
class PrintableTicketLine {
  final String label;
  final String value;
  final PrintLineType type;

  const PrintableTicketLine({
    required this.label,
    required this.value,
    required this.type,
  });

  factory PrintableTicketLine.fromJson(Map<String, dynamic> json) {
    return PrintableTicketLine(
      label: json['label'] as String,
      value: json['value'] as String,
      type: _parseType(json['type'] as String),
    );
  }

  static PrintLineType _parseType(String type) {
    switch (type) {
      case 'header':
        return PrintLineType.header;
      case 'plate':
        return PrintLineType.plate;
      case 'amount':
        return PrintLineType.amount;
      case 'date':
        return PrintLineType.date;
      case 'status':
        return PrintLineType.status;
      case 'phone':
        return PrintLineType.phone;
      case 'coordinates':
        return PrintLineType.coordinates;
      case 'footer':
        return PrintLineType.footer;
      default:
        return PrintLineType.text;
    }
  }
}

/// QR code data for display and printing
class QrCodeData {
  final String dataUrl;
  final String buffer;
  final String content;

  const QrCodeData({
    required this.dataUrl,
    required this.buffer,
    required this.content,
  });

  factory QrCodeData.fromJson(Map<String, dynamic> json) {
    return QrCodeData(
      dataUrl: json['dataUrl'] as String,
      buffer: json['buffer'] as String,
      content: json['content'] as String,
    );
  }
}

/// Complete printable ticket data from the API (optimized response)
class PrintableTicketData {
  final List<PrintableTicketLine> lines;
  final QrCodeData qrCode;
  final String ticketId;
  final String ticketNumber;

  const PrintableTicketData({
    required this.lines,
    required this.qrCode,
    required this.ticketId,
    required this.ticketNumber,
  });

  factory PrintableTicketData.fromJson(Map<String, dynamic> json) {
    return PrintableTicketData(
      lines: (json['lines'] as List)
          .map((l) => PrintableTicketLine.fromJson(l as Map<String, dynamic>))
          .toList(),
      qrCode: QrCodeData.fromJson(json['qrCode'] as Map<String, dynamic>),
      ticketId: json['ticketId'] as String,
      ticketNumber: json['ticketNumber'] as String,
    );
  }

  /// Build PrintableTicketData from Ticket with localized labels
  factory PrintableTicketData.fromTicket({
    required Ticket ticket,
    required QrCodeData qrCode,
    required AppLocalizations l10n,
  }) {
    final parkingZone = ticket.parkingZone;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    // Get localized reason
    String reasonLabel;
    switch (ticket.reason) {
      case TicketReason.carSabot:
        reasonLabel = l10n.printReasonCarSabot;
        break;
      case TicketReason.pound:
        reasonLabel = l10n.printReasonPound;
        break;
    }

    final lines = <PrintableTicketLine>[
      // License plate
      PrintableTicketLine(
        label: l10n.printLabelPlate,
        value: ticket.licensePlate,
        type: PrintLineType.plate,
      ),
      // Reason
      PrintableTicketLine(
        label: l10n.printLabelReason,
        value: reasonLabel,
        type: PrintLineType.text,
      ),
      // Fine amount
      PrintableTicketLine(
        label: l10n.printLabelFine,
        value: '${ticket.fineAmount.toStringAsFixed(0)} TND',
        type: PrintLineType.amount,
      ),
      // Date
      PrintableTicketLine(
        label: l10n.printLabelDate,
        value: dateFormat.format(ticket.issuedAt),
        type: PrintLineType.date,
      ),
      // Time
      PrintableTicketLine(
        label: l10n.printLabelTime,
        value: timeFormat.format(ticket.issuedAt),
        type: PrintLineType.date,
      ),
    ];

    // Add address if available
    if (ticket.address != null && ticket.address!.isNotEmpty) {
      lines.add(PrintableTicketLine(
        label: l10n.printLabelAddress,
        value: ticket.address!,
        type: PrintLineType.text,
      ));
    }

    // Add parking zone info if available
    if (parkingZone != null) {
      // Zone name
      lines.add(PrintableTicketLine(
        label: l10n.printLabelZone,
        value: parkingZone.name,
        type: PrintLineType.text,
      ));

      // Zone address
      if (parkingZone.address != null && parkingZone.address!.isNotEmpty) {
        lines.add(PrintableTicketLine(
          label: l10n.printLabelZoneAddress,
          value: parkingZone.address!,
          type: PrintLineType.text,
        ));
      }

      // Zone phone
      if (parkingZone.phoneNumber != null && parkingZone.phoneNumber!.isNotEmpty) {
        lines.add(PrintableTicketLine(
          label: l10n.printLabelZonePhone,
          value: parkingZone.phoneNumber!,
          type: PrintLineType.phone,
        ));
      }
    }

    return PrintableTicketData(
      lines: lines,
      qrCode: qrCode,
      ticketId: ticket.id,
      ticketNumber: ticket.ticketNumber,
    );
  }
}

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
}

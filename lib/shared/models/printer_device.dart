/// Model representing a Bluetooth thermal printer device
class PrinterDevice {
  final String name;
  final String address;
  final bool isConnected;

  const PrinterDevice({
    required this.name,
    required this.address,
    this.isConnected = false,
  });

  PrinterDevice copyWith({
    String? name,
    String? address,
    bool? isConnected,
  }) {
    return PrinterDevice(
      name: name ?? this.name,
      address: address ?? this.address,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  /// Create from JSON (for SharedPreferences persistence)
  factory PrinterDevice.fromJson(Map<String, dynamic> json) {
    return PrinterDevice(
      name: json['name'] as String? ?? 'Unknown',
      address: json['address'] as String,
      isConnected: json['isConnected'] as bool? ?? false,
    );
  }

  /// Convert to JSON (for SharedPreferences persistence)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'isConnected': isConnected,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrinterDevice && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() => 'PrinterDevice(name: $name, address: $address, isConnected: $isConnected)';
}

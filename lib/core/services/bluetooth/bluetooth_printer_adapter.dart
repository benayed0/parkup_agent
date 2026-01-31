import 'dart:async';

/// Represents a discovered Bluetooth device
class DiscoveredPrinter {
  final String name;
  final String address;
  final int rssi;
  final bool isBonded;

  const DiscoveredPrinter({
    required this.name,
    required this.address,
    this.rssi = 0,
    this.isBonded = false,
  });
}

/// Abstract adapter for platform-specific Bluetooth printer communication.
///
/// Android uses Classic Bluetooth (SPP) via flutter_bluetooth_serial.
/// iOS uses BLE via flutter_blue_plus since iOS doesn't allow Classic BT for third-party apps.
abstract class BluetoothPrinterAdapter {
  /// Whether Bluetooth is available on this device
  Future<bool> get isAvailable;

  /// Whether Bluetooth is currently enabled
  Future<bool> get isEnabled;

  /// Whether we're currently connected to a printer
  bool get isConnected;

  /// Start scanning for Bluetooth devices.
  /// Returns a stream of discovered devices.
  Stream<DiscoveredPrinter> startScan();

  /// Stop scanning for devices
  Future<void> stopScan();

  /// Connect to a device by address.
  /// Returns true if connection succeeded.
  Future<bool> connect(String address);

  /// Request pairing/bonding with a device (Android only, no-op on iOS)
  Future<bool> requestPairing(String address);

  /// Disconnect from the current device
  Future<void> disconnect();

  /// Send raw bytes to the connected printer.
  /// Data is sent in chunks to avoid buffer overflow.
  Future<bool> sendBytes(List<int> bytes);

  /// Clean up resources
  void dispose();
}

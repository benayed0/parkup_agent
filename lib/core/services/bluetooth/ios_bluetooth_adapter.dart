import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'bluetooth_printer_adapter.dart';

/// iOS implementation using BLE via flutter_blue_plus.
/// iOS does not support Classic Bluetooth SPP for third-party apps,
/// so we must use BLE to communicate with thermal printers.
///
/// Most thermal printers expose a BLE write characteristic that accepts
/// raw ESC/POS bytes, typically under a known service UUID.
class IosBluetoothAdapter implements BluetoothPrinterAdapter {
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription? _scanSubscription;
  StreamSubscription? _connectionSubscription;

  /// Common BLE service/characteristic UUIDs used by thermal printers.
  /// Many printers use the Nordic UART Service (NUS) or similar serial-over-BLE profiles.
  static const _printerServiceUuids = [
    '000018f0-0000-1000-8000-00805f9b34fb', // Common thermal printer service
    '49535343-fe7d-4ae5-8fa9-9fafd205e455', // Microchip/ISSC serial service
    '0000ff00-0000-1000-8000-00805f9b34fb', // Generic printer service
    'e7810a71-73ae-499d-8c15-faa9aef0c3f2', // RN4870/RN4871 serial service
  ];

  static const _printerWriteCharUuids = [
    '00002af1-0000-1000-8000-00805f9b34fb', // Common write characteristic
    '49535343-8841-43f4-a8d4-ecbe34729bb3', // ISSC write characteristic
    '0000ff02-0000-1000-8000-00805f9b34fb', // Generic write char
    'bef8d6c9-9c21-4c9e-b632-bd58c1009f9f', // RN4870 write char
  ];

  @override
  Future<bool> get isAvailable async => await FlutterBluePlus.isSupported;

  @override
  Future<bool> get isEnabled async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  @override
  bool get isConnected => _connectedDevice != null && _writeCharacteristic != null;

  @override
  Stream<DiscoveredPrinter> startScan() {
    final controller = StreamController<DiscoveredPrinter>();
    final seenAddresses = <String>{};

    // Start BLE scan
    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: false,
    );

    _scanSubscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        for (final result in results) {
          final address = result.device.remoteId.str;
          if (seenAddresses.contains(address)) continue;
          seenAddresses.add(address);

          controller.add(DiscoveredPrinter(
            name: result.device.platformName.isNotEmpty
                ? result.device.platformName
                : result.advertisementData.advName,
            address: address,
            rssi: result.rssi,
            isBonded: false, // BLE doesn't have the same bonding concept exposed here
          ));
        }
      },
      onError: (error) {
        controller.addError(error);
      },
    );

    // Close stream when scan completes
    FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning && !controller.isClosed) {
        controller.close();
      }
    });

    return controller.stream;
  }

  @override
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _scanSubscription?.cancel();
    _scanSubscription = null;
  }

  @override
  Future<bool> requestPairing(String address) async {
    // iOS handles BLE pairing automatically when connecting/reading encrypted characteristics.
    // No explicit pairing step needed.
    return true;
  }

  @override
  Future<bool> connect(String address) async {
    try {
      final device = BluetoothDevice.fromId(address);

      // Listen for disconnection
      _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _writeCharacteristic = null;
        }
      });

      // Connect to device
      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );

      // Discover services and find the write characteristic
      final services = await device.discoverServices();
      _writeCharacteristic = _findWriteCharacteristic(services);

      if (_writeCharacteristic == null) {
        debugPrint('BLE: No suitable write characteristic found. Trying fallback...');
        // Fallback: look for any writable characteristic
        _writeCharacteristic = _findAnyWritableCharacteristic(services);
      }

      if (_writeCharacteristic == null) {
        debugPrint('BLE: No writable characteristic found at all. Disconnecting.');
        await device.disconnect();
        return false;
      }

      _connectedDevice = device;

      // Request higher MTU for faster data transfer
      try {
        await device.requestMtu(512);
      } catch (_) {
        // MTU negotiation failure is non-fatal
      }

      debugPrint('BLE: Connected to ${device.platformName} via characteristic ${_writeCharacteristic!.uuid}');
      return true;
    } catch (e) {
      debugPrint('BLE connect error: $e');
      _connectedDevice = null;
      _writeCharacteristic = null;
      return false;
    }
  }

  /// Find a write characteristic matching known printer UUIDs
  BluetoothCharacteristic? _findWriteCharacteristic(List<BluetoothService> services) {
    for (final service in services) {
      final serviceUuid = service.uuid.toString().toLowerCase();

      // Check if this is a known printer service
      final isKnownService = _printerServiceUuids.any(
        (uuid) => serviceUuid.contains(uuid.substring(0, 8)),
      );

      if (!isKnownService) continue;

      for (final char in service.characteristics) {
        final charUuid = char.uuid.toString().toLowerCase();

        // Check for known write characteristics
        final isKnownChar = _printerWriteCharUuids.any(
          (uuid) => charUuid.contains(uuid.substring(0, 8)),
        );

        if (isKnownChar && (char.properties.write || char.properties.writeWithoutResponse)) {
          return char;
        }
      }

      // If known service but no known char, try any writable char in that service
      for (final char in service.characteristics) {
        if (char.properties.write || char.properties.writeWithoutResponse) {
          return char;
        }
      }
    }
    return null;
  }

  /// Fallback: find any writable characteristic from any service
  BluetoothCharacteristic? _findAnyWritableCharacteristic(List<BluetoothService> services) {
    for (final service in services) {
      // Skip standard BLE services (Generic Access, Generic Attribute, Device Info, etc.)
      final serviceUuid = service.uuid.toString().toLowerCase();
      if (serviceUuid.startsWith('00001800') ||
          serviceUuid.startsWith('00001801') ||
          serviceUuid.startsWith('0000180a')) {
        continue;
      }

      for (final char in service.characteristics) {
        if (char.properties.write || char.properties.writeWithoutResponse) {
          debugPrint('BLE fallback: using service=${service.uuid} char=${char.uuid}');
          return char;
        }
      }
    }
    return null;
  }

  @override
  Future<void> disconnect() async {
    try {
      _connectionSubscription?.cancel();
      _connectionSubscription = null;
      await _connectedDevice?.disconnect();
    } catch (_) {}
    _connectedDevice = null;
    _writeCharacteristic = null;
  }

  @override
  Future<bool> sendBytes(List<int> bytes) async {
    if (_writeCharacteristic == null || _connectedDevice == null) return false;

    try {
      // BLE has smaller MTU than classic Bluetooth — send in smaller chunks.
      // Typical BLE MTU is 20-512 bytes; use a safe default of 182 bytes.
      final mtu = _connectedDevice!.mtuNow;
      // ATT overhead is 3 bytes, so usable payload = MTU - 3
      final chunkSize = (mtu > 23) ? mtu - 3 : 20;

      final useWriteWithoutResponse = _writeCharacteristic!.properties.writeWithoutResponse;

      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);

        await _writeCharacteristic!.write(
          Uint8List.fromList(chunk),
          withoutResponse: useWriteWithoutResponse,
        );

        // Small delay between chunks to let the printer process
        if (end < bytes.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
      return true;
    } catch (e) {
      debugPrint('BLE send error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _connectedDevice?.disconnect();
  }
}

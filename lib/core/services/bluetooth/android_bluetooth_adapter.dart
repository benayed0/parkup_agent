import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'bluetooth_printer_adapter.dart';

/// Android implementation using Classic Bluetooth (SPP) via flutter_bluetooth_serial.
/// Classic Bluetooth is the standard protocol for thermal printers on Android.
class AndroidBluetoothAdapter implements BluetoothPrinterAdapter {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  StreamSubscription? _scanSubscription;
  StreamController<DiscoveredPrinter>? _scanController;

  @override
  Future<bool> get isAvailable async => await _bluetooth.isAvailable ?? false;

  @override
  Future<bool> get isEnabled async => await _bluetooth.isEnabled ?? false;

  @override
  bool get isConnected => _connection?.isConnected ?? false;

  @override
  Stream<DiscoveredPrinter> startScan() {
    _scanController = StreamController<DiscoveredPrinter>();

    _scanSubscription = _bluetooth.startDiscovery().listen(
      (result) {
        _scanController?.add(DiscoveredPrinter(
          name: result.device.name ?? '',
          address: result.device.address,
          rssi: result.rssi,
          isBonded: result.device.isBonded,
        ));
      },
      onError: (error) {
        _scanController?.addError(error);
        _scanController?.close();
      },
      onDone: () {
        _scanController?.close();
      },
    );

    return _scanController!.stream;
  }

  @override
  Future<void> stopScan() async {
    try {
      await _bluetooth.cancelDiscovery();
    } catch (_) {}
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _scanController?.close();
    _scanController = null;
  }

  @override
  Future<bool> requestPairing(String address) async {
    try {
      final bonded = await _bluetooth.bondDeviceAtAddress(address);
      return bonded ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> connect(String address) async {
    try {
      _connection = await BluetoothConnection.toAddress(address)
          .timeout(const Duration(seconds: 10));
      return _connection?.isConnected ?? false;
    } catch (_) {
      _connection = null;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _connection?.close();
    } catch (_) {}
    _connection = null;
  }

  @override
  Future<bool> sendBytes(List<int> bytes) async {
    if (_connection == null || !_connection!.isConnected) return false;

    try {
      const chunkSize = 512;
      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);
        _connection!.output.add(Uint8List.fromList(chunk));
        await _connection!.output.allSent;
        if (end < bytes.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanController?.close();
    _connection?.close();
  }
}

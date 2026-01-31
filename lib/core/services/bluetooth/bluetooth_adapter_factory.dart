import 'dart:io' show Platform;

import 'bluetooth_printer_adapter.dart';
import 'android_bluetooth_adapter.dart';
import 'ios_bluetooth_adapter.dart';

/// Creates the appropriate Bluetooth adapter for the current platform.
///
/// - Android: Uses Classic Bluetooth (SPP) via flutter_bluetooth_serial
/// - iOS: Uses BLE via flutter_blue_plus
BluetoothPrinterAdapter createBluetoothAdapter() {
  if (Platform.isIOS) {
    return IosBluetoothAdapter();
  }
  return AndroidBluetoothAdapter();
}

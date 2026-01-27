import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

import '../../shared/models/printer_device.dart' as models;
import '../../shared/models/printable_ticket.dart';

/// Connection status for the printer
enum PrinterConnectionStatus { disconnected, connecting, connected, error }

/// Printer service
/// Handles Bluetooth thermal printer discovery, connection, and printing
class PrinterService extends ChangeNotifier {
  static const String _savedPrinterKey = 'saved_printer';

  SharedPreferences? _prefs;
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  StreamSubscription? _scanSubscription;

  models.PrinterDevice? _connectedPrinter;
  models.PrinterDevice? _savedPrinter;
  PrinterConnectionStatus _status = PrinterConnectionStatus.disconnected;
  String? _errorMessage;
  List<BluetoothDiscoveryResult> _discoveredDevices = [];
  bool _isScanning = false;

  // Print lock - block concurrent print requests
  bool _isPrinting = false;
  bool _cancelRequested = false;

  // Getters
  models.PrinterDevice? get connectedPrinter => _connectedPrinter;
  models.PrinterDevice? get savedPrinter => _savedPrinter;
  PrinterConnectionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<BluetoothDiscoveryResult> get discoveredDevices => _discoveredDevices;
  bool get isScanning => _isScanning;
  bool get isConnected => _status == PrinterConnectionStatus.connected;
  bool get hasSavedPrinter => _savedPrinter != null;
  bool get isPrinting => _isPrinting;
  bool get isCancelRequested => _cancelRequested;

  /// Initialize service - load saved printer and auto-reconnect
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadSavedPrinter();

    // Auto-reconnect to saved printer on startup (silent, non-blocking)
    if (_savedPrinter != null) {
      _autoReconnect();
    }
  }

  /// Silent auto-reconnect (doesn't show errors, runs in background)
  Future<void> _autoReconnect() async {
    if (_savedPrinter == null) return;

    try {
      // Check if Bluetooth is available and enabled
      final isAvailable = await _bluetooth.isAvailable ?? false;
      final isEnabled = await _bluetooth.isEnabled ?? false;

      if (!isAvailable || !isEnabled) {
        _status = PrinterConnectionStatus.disconnected;
        notifyListeners();
        return;
      }

      // Check permissions
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        _status = PrinterConnectionStatus.disconnected;
        notifyListeners();
        return;
      }

      _status = PrinterConnectionStatus.connecting;
      notifyListeners();

      // Small delay to let Bluetooth stack initialize
      await Future.delayed(const Duration(milliseconds: 500));

      _connection = await BluetoothConnection.toAddress(
        _savedPrinter!.address,
      ).timeout(const Duration(seconds: 10));

      if (_connection != null && _connection!.isConnected) {
        _connectedPrinter = _savedPrinter!.copyWith(isConnected: true);
        _status = PrinterConnectionStatus.connected;
      } else {
        _status = PrinterConnectionStatus.disconnected;
      }
    } catch (_) {
      // Silent fail - don't show error on auto-reconnect
      _status = PrinterConnectionStatus.disconnected;
    }
    notifyListeners();
  }

  /// Load saved printer from SharedPreferences
  Future<void> _loadSavedPrinter() async {
    _prefs ??= await SharedPreferences.getInstance();
    final savedJson = _prefs!.getString(_savedPrinterKey);
    if (savedJson != null) {
      try {
        final json = jsonDecode(savedJson) as Map<String, dynamic>;
        _savedPrinter = models.PrinterDevice.fromJson(json);
        notifyListeners();
      } catch (_) {
        // Invalid saved data, ignore
      }
    }
  }

  /// Save printer to SharedPreferences
  Future<void> _savePrinter(models.PrinterDevice printer) async {
    _prefs ??= await SharedPreferences.getInstance();
    _savedPrinter = printer;
    await _prefs!.setString(_savedPrinterKey, jsonEncode(printer.toJson()));
    notifyListeners();
  }

  /// Clear saved printer
  Future<void> clearSavedPrinter() async {
    _prefs ??= await SharedPreferences.getInstance();
    _savedPrinter = null;
    await _prefs!.remove(_savedPrinterKey);
    notifyListeners();
  }

  /// Request Bluetooth permissions
  Future<bool> requestPermissions() async {
    final bluetoothScan = await Permission.bluetoothScan.request();
    final bluetoothConnect = await Permission.bluetoothConnect.request();
    final location = await Permission.locationWhenInUse.request();

    return bluetoothScan.isGranted &&
        bluetoothConnect.isGranted &&
        location.isGranted;
  }

  /// Start scanning for Bluetooth devices
  Future<void> startScan() async {
    if (_isScanning) return;

    // Check permissions first
    final hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      _errorMessage = 'Bluetooth permissions denied';
      notifyListeners();
      return;
    }

    _isScanning = true;
    _discoveredDevices = [];
    _errorMessage = null;
    notifyListeners();

    try {
      // Start Bluetooth discovery
      _scanSubscription = _bluetooth.startDiscovery().listen(
        (result) {
          // Check if device already in list
          final existingIndex = _discoveredDevices.indexWhere(
            (d) => d.device.address == result.device.address,
          );
          if (existingIndex < 0) {
            _discoveredDevices.add(result);
            notifyListeners();
          }
        },
        onError: (error) {
          _errorMessage = 'Scan error: $error';
          _isScanning = false;
          notifyListeners();
        },
        onDone: () {
          _isScanning = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Scan failed: $e';
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    try {
      await _bluetooth.cancelDiscovery();
    } catch (_) {}
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    notifyListeners();
  }

  /// Stop scanning without notifying listeners (for use during disposal)
  void stopScanSilent() {
    try {
      _bluetooth.cancelDiscovery();
    } catch (_) {}
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
  }

  /// Request pairing with a device
  Future<bool> requestPairing(BluetoothDevice device) async {
    try {
      final bonded = await _bluetooth.bondDeviceAtAddress(device.address);
      return bonded ?? false;
    } catch (e) {
      _errorMessage = 'Pairing failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Connect to a printer
  Future<bool> connect(BluetoothDiscoveryResult result) async {
    final device = result.device;

    // Check if device is paired
    if (!device.isBonded) {
      // Request pairing first
      final paired = await requestPairing(device);
      if (!paired) {
        _errorMessage = 'Device not paired';
        notifyListeners();
        return false;
      }
    }

    _status = PrinterConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      _connection = await BluetoothConnection.toAddress(device.address);

      if (_connection != null && _connection!.isConnected) {
        final printerDevice = models.PrinterDevice(
          name: device.name ?? 'Unknown Printer',
          address: device.address,
          isConnected: true,
        );

        _connectedPrinter = printerDevice;
        _status = PrinterConnectionStatus.connected;

        // Save as last connected printer
        await _savePrinter(printerDevice);

        notifyListeners();
        return true;
      } else {
        _status = PrinterConnectionStatus.error;
        _errorMessage = 'Connection failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = PrinterConnectionStatus.error;
      _errorMessage = 'Connection failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Connect to a printer by address (for reconnecting to saved printer)
  Future<bool> connectByAddress(String name, String address) async {
    _status = PrinterConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      _connection = await BluetoothConnection.toAddress(address);

      if (_connection != null && _connection!.isConnected) {
        final printerDevice = models.PrinterDevice(
          name: name,
          address: address,
          isConnected: true,
        );

        _connectedPrinter = printerDevice;
        _status = PrinterConnectionStatus.connected;

        notifyListeners();
        return true;
      } else {
        _status = PrinterConnectionStatus.error;
        _errorMessage = 'Connection failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _status = PrinterConnectionStatus.error;
      _errorMessage = 'Connection failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Disconnect from current printer
  Future<void> disconnect() async {
    try {
      await _connection?.close();
    } catch (_) {
      // Ignore disconnect errors
    }
    _connection = null;
    _connectedPrinter = null;
    _status = PrinterConnectionStatus.disconnected;
    _errorMessage = null;
    notifyListeners();
  }

  /// Try to reconnect to saved printer
  Future<bool> reconnectToSavedPrinter() async {
    if (_savedPrinter == null) return false;
    return await connectByAddress(_savedPrinter!.name, _savedPrinter!.address);
  }

  /// Cancel the current print job
  void cancelPrint() {
    if (_isPrinting) {
      _cancelRequested = true;
      notifyListeners();
    }
  }

  /// Send raw bytes to printer
  Future<bool> _sendBytes(List<int> bytes) async {
    if (_connection == null) {
      _errorMessage = 'No connection object';
      _status = PrinterConnectionStatus.disconnected;
      _connectedPrinter = null;
      notifyListeners();
      return false;
    }

    if (!_connection!.isConnected) {
      _errorMessage = 'Connection lost';
      _status = PrinterConnectionStatus.disconnected;
      _connectedPrinter = null;
      notifyListeners();
      return false;
    }

    try {
      // Send bytes in chunks to avoid buffer overflow
      const chunkSize = 512;
      for (var i = 0; i < bytes.length; i += chunkSize) {
        // Check for cancellation request
        if (_cancelRequested) {
          _errorMessage = 'Print cancelled';
          return false;
        }

        final end = (i + chunkSize < bytes.length)
            ? i + chunkSize
            : bytes.length;
        final chunk = bytes.sublist(i, end);
        _connection!.output.add(Uint8List.fromList(chunk));
        await _connection!.output.allSent;
        // Small delay between chunks
        if (end < bytes.length) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
      return true;
    } catch (e) {
      _errorMessage = 'Send failed: $e';
      _status = PrinterConnectionStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Check if text contains non-ASCII characters (Arabic, etc.)
  bool _containsNonAscii(String text) {
    for (final char in text.runes) {
      if (char > 127) return true;
    }
    return false;
  }

  /// Convert non-ASCII text to safe ASCII (replaces non-ASCII with ?)
  String _toSafeAscii(String text) {
    if (!_containsNonAscii(text)) return text;
    return text.runes.map((r) => r > 127 ? '?' : String.fromCharCode(r)).join();
  }

  /// Paper width in dots for 58mm thermal printer
  static const int _paperWidthDots = 384;

  // Cached divider images
  img.Image? _cachedDividerDouble;
  img.Image? _cachedDividerSingle;

  /// Create a full-width double line divider image
  img.Image _getDividerDouble() {
    if (_cachedDividerDouble != null) return _cachedDividerDouble!;

    const int height = 6;
    final divider = img.Image(_paperWidthDots, height);
    const int white = 0xFFFFFFFF;
    const int black = 0xFF000000;
    img.fill(divider, white);

    // Draw two horizontal lines (double divider)
    for (int x = 0; x < _paperWidthDots; x++) {
      divider.setPixel(x, 1, black);
      divider.setPixel(x, 4, black);
    }

    _cachedDividerDouble = divider;
    return divider;
  }

  /// Create a full-width single dashed line divider image
  img.Image _getDividerSingle() {
    if (_cachedDividerSingle != null) return _cachedDividerSingle!;

    const int height = 4;
    final divider = img.Image(_paperWidthDots, height);
    const int white = 0xFFFFFFFF;
    const int black = 0xFF000000;
    img.fill(divider, white);

    // Draw dashed line (8px dash, 4px gap)
    for (int x = 0; x < _paperWidthDots; x++) {
      if ((x ~/ 8) % 2 == 0) {
        divider.setPixel(x, 1, black);
        divider.setPixel(x, 2, black);
      }
    }

    _cachedDividerSingle = divider;
    return divider;
  }

  // Cached logo image for printing
  img.Image? _cachedLogo;

  /// Load and process logo for thermal printing
  /// Converts colored logo to black on white for thermal printer
  Future<img.Image?> _loadLogo() async {
    // Return cached logo if available
    if (_cachedLogo != null) return _cachedLogo;

    try {
      // Load logo from assets
      final byteData = await rootBundle.load('assets/icons/parkup-logo.png');
      final bytes = byteData.buffer.asUint8List();
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) return null;

      // Resize to fit thermal paper (150px width for header)
      final resized = img.copyResize(originalImage, width: 150);

      // Create new image with white background
      final processed = img.Image(resized.width, resized.height);
      const int white = 0xFFFFFFFF; // ARGB white
      const int black = 0xFF000000; // ARGB black
      img.fill(processed, white);

      // Convert colored pixels to black, transparent to white
      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final pixel = resized.getPixel(x, y);
          // Extract ARGB components from integer pixel
          final a = (pixel >> 24) & 0xFF;
          final r = (pixel >> 16) & 0xFF;
          final g = (pixel >> 8) & 0xFF;
          final b = pixel & 0xFF;

          // If pixel is mostly transparent, keep white
          if (a < 128) {
            processed.setPixel(x, y, white);
          } else {
            // Convert to grayscale and threshold to black/white
            final gray = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
            // If the pixel is dark enough (blue logo), make it black
            if (gray < 200) {
              processed.setPixel(x, y, black);
            } else {
              processed.setPixel(x, y, white);
            }
          }
        }
      }

      _cachedLogo = processed;
      return processed;
    } catch (e) {
      debugPrint('Error loading logo: $e');
      return null;
    }
  }

  /// Render text to an image for printing non-ASCII characters
  /// Supports text wrapping for long text with maxWidth constraint
  Future<img.Image?> _textToImage(
    String text, {
    double fontSize = 24,
    bool bold = true,
    TextAlign textAlign = TextAlign.center,
    double? maxWidth,
  }) async {
    try {
      // Create a picture recorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Text style
      final textStyle = TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      );

      // Create text painter with optional max width for wrapping
      final textPainter = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
        textAlign: textAlign,
      );

      // Layout with max width constraint for text wrapping
      if (maxWidth != null) {
        textPainter.layout(maxWidth: maxWidth - 20);
      } else {
        textPainter.layout();
      }

      // Draw white background
      final width = maxWidth?.toInt() ?? (textPainter.width.ceil() + 20);
      final height = textPainter.height.ceil() + 10;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = Colors.white,
      );

      // Draw text
      textPainter.paint(canvas, const Offset(10, 5));

      // Convert to image
      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(width, height);
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      // Decode PNG to image package format
      final pngBytes = byteData.buffer.asUint8List();
      return img.decodeImage(pngBytes);
    } catch (e) {
      debugPrint('Error converting text to image: $e');
      return null;
    }
  }

  /// Render a license plate like the LicensePlateDisplay widget
  /// Format: "LEFT_NUM  LABEL  RIGHT_NUM" with proper styling
  Future<img.Image?> _licensePlateToImage(String plateText) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Parse the plate - typically format is "NUM LABEL NUM" or "NUM LABEL"
      // e.g., "232 تونس 32" or "123456 ن ت"
      final parts = plateText.split(' ');

      String leftNum = '';
      String label = '';
      String rightNum = '';

      if (parts.length >= 3) {
        // Standard format: NUM LABEL NUM (e.g., "232 تونس 32")
        leftNum = parts.first;
        rightNum = parts.last;
        label = parts.sublist(1, parts.length - 1).join(' ');
      } else if (parts.length == 2) {
        // RS/Libya format: NUM LABEL (e.g., "123456 ن ت")
        leftNum = parts.first;
        label = parts.last;
      } else {
        // Single value - just render as is
        leftNum = plateText;
      }

      // Styles
      const double fontSize = 36;
      const double labelFontSize = 28;

      final numStyle = TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 4,
        fontFamily: 'monospace',
      );

      final labelStyle = TextStyle(
        color: Colors.black,
        fontSize: labelFontSize,
        fontWeight: FontWeight.bold,
      );

      // Create text painters
      final leftPainter = TextPainter(
        text: TextSpan(text: leftNum, style: numStyle),
        textDirection: TextDirection.ltr,
      );
      leftPainter.layout();

      final labelPainter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.rtl, // Arabic text
      );
      labelPainter.layout();

      final rightPainter = TextPainter(
        text: TextSpan(text: rightNum, style: numStyle),
        textDirection: TextDirection.ltr,
      );
      rightPainter.layout();

      // Calculate total width with spacing
      const double spacing = 20;
      final totalWidth = leftPainter.width +
          (label.isNotEmpty ? spacing + labelPainter.width + spacing : 0) +
          (rightNum.isNotEmpty ? rightPainter.width : 0) + 40;
      final width = totalWidth.ceil();
      final height = (fontSize + 16).ceil();

      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = Colors.white,
      );

      // Draw plate components centered
      double xOffset = 20;
      final yOffset = (height - leftPainter.height) / 2;

      // Left number
      leftPainter.paint(canvas, Offset(xOffset, yOffset));
      xOffset += leftPainter.width;

      // Label (Arabic)
      if (label.isNotEmpty) {
        xOffset += spacing;
        final labelY = (height - labelPainter.height) / 2;
        labelPainter.paint(canvas, Offset(xOffset, labelY));
        xOffset += labelPainter.width + spacing;
      }

      // Right number
      if (rightNum.isNotEmpty) {
        rightPainter.paint(canvas, Offset(xOffset, yOffset));
      }

      // Convert to image
      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(width, height);
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      return img.decodeImage(pngBytes);
    } catch (e) {
      debugPrint('Error converting license plate to image: $e');
      return null;
    }
  }

  /// Render a label-value row as an image for Arabic text
  /// Set valueLtr to true for values that should always be LTR (phone numbers, etc.)
  Future<img.Image?> _rowToImage(
    String label,
    String value, {
    double fontSize = 28,
    bool valueBold = true,
    bool valueLtr = false,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Check if Arabic (RTL)
      final isRtl = _containsNonAscii(label);

      // Styles - both label and value are bold for better readability
      final labelStyle = TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      );
      final valueStyle = TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      );

      // For RTL: "label :" on right, value on left. For LTR: "label: value"
      final labelPainter = TextPainter(
        text: TextSpan(text: '$label: ', style: labelStyle),
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      );
      labelPainter.layout();

      // Value is always LTR if valueLtr is true (for phone numbers, etc.)
      final valuePainter = TextPainter(
        text: TextSpan(text: value, style: valueStyle),
        textDirection: valueLtr ? TextDirection.ltr : (isRtl ? TextDirection.rtl : TextDirection.ltr),
      );
      valuePainter.layout();

      // Use full paper width for RTL to right-align properly
      const int paperWidth = 380;
      final totalWidth = (labelPainter.width + valuePainter.width).ceil() + 20;
      final width = isRtl ? paperWidth : (totalWidth > paperWidth ? paperWidth : totalWidth);
      final height = labelPainter.height.ceil() + 10;

      // Draw white background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = Colors.white,
      );

      if (isRtl) {
        // RTL: Label on far right, then value to its left
        // Reading right-to-left: label -> colon -> value
        final labelX = width - 5 - labelPainter.width;
        final valueX = labelX - valuePainter.width;
        labelPainter.paint(canvas, Offset(labelX, 5));
        valuePainter.paint(canvas, Offset(valueX, 5));
      } else {
        // LTR: Draw from left side - label first, then value
        labelPainter.paint(canvas, const Offset(5, 5));
        valuePainter.paint(canvas, Offset(5 + labelPainter.width, 5));
      }

      // Convert to image
      final picture = recorder.endRecording();
      final uiImage = await picture.toImage(width, height);
      final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      return img.decodeImage(pngBytes);
    } catch (e) {
      debugPrint('Error converting row to image: $e');
      return null;
    }
  }

  /// Build ESC/POS commands for printing
  Future<List<int>> _buildTestPageBytes() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(
      'PARKUP AGENT',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.imageRaster(_getDividerDouble(), align: PosAlign.center);
    bytes += generator.text(
      'Test Print',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Printer connected!',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      '58mm Thermal Printer',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.imageRaster(_getDividerSingle(), align: PosAlign.center);
    bytes += generator.text(
      DateTime.now().toString().substring(0, 19),
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
      ),
    );
    // Raw cut command without extra feed (GS V 66 1 = partial cut with 1 line feed)
    bytes += [0x1D, 0x56, 0x42, 0x01];

    return bytes;
  }

  /// Print a test page
  Future<bool> printTestPage() async {
    if (!isConnected) {
      _errorMessage = 'No printer connected';
      notifyListeners();
      return false;
    }

    // Block if already printing
    if (_isPrinting) {
      _errorMessage = 'Print job already in progress';
      notifyListeners();
      return false;
    }

    _isPrinting = true;
    _cancelRequested = false;
    notifyListeners();

    try {
      final bytes = await _buildTestPageBytes();
      return await _sendBytes(bytes);
    } catch (e) {
      _errorMessage = 'Print error: $e';
      notifyListeners();
      return false;
    } finally {
      _isPrinting = false;
      _cancelRequested = false;
      notifyListeners();
    }
  }

  /// Build ESC/POS commands for ticket
  Future<List<int>> _buildTicketBytes(PrintableTicketData ticketData) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // Header with logo
    final logo = await _loadLogo();
    if (logo != null) {
      bytes += generator.imageRaster(logo, align: PosAlign.center);
      bytes += generator.feed(1);
    } else {
      // Fallback to text if logo fails to load
      bytes += generator.text(
        'PARKUP',
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
    }
    // Title as image for consistent large size
    final titleImage = await _textToImage(
      'PARKING TICKET',
      fontSize: 32,
      bold: true,
      textAlign: TextAlign.center,
    );
    if (titleImage != null) {
      bytes += generator.imageRaster(titleImage, align: PosAlign.center);
    }
    bytes += generator.imageRaster(_getDividerDouble(), align: PosAlign.center);

    // Process each line from the ticket data
    // Skip: header (duplicate ticket#), status, coordinates, due date, agent info
    for (final line in ticketData.lines) {
      // Skip unwanted line types
      if (line.type == PrintLineType.header ||
          line.type == PrintLineType.status ||
          line.type == PrintLineType.coordinates) {
        continue;
      }

      // Skip due date and agent info by label
      final labelLower = line.label.toLowerCase();
      if (labelLower.contains('due') ||
          labelLower.contains('agent') ||
          labelLower.contains('code')) {
        continue;
      }

      switch (line.type) {
        case PrintLineType.header:
        case PrintLineType.status:
        case PrintLineType.coordinates:
          // Already skipped above
          break;

        case PrintLineType.plate:
          // Render license plate with proper formatting (NUM LABEL NUM)
          final plateImage = await _licensePlateToImage(line.value);
          if (plateImage != null) {
            bytes += generator.imageRaster(
              plateImage,
              align: PosAlign.center,
            );
          } else {
            // Fallback to simple text
            bytes += generator.text(
              _toSafeAscii(line.value),
              styles: const PosStyles(
                align: PosAlign.center,
                bold: true,
                height: PosTextSize.size2,
                width: PosTextSize.size2,
              ),
            );
          }
          break;

        case PrintLineType.amount:
        case PrintLineType.date:
        case PrintLineType.text:
          // For long values, print label and value on separate lines with wrapping
          if (line.value.length > 20) {
            // Print label
            final labelImage = await _textToImage(
              '${line.label}:',
              fontSize: 24,
              bold: true,
              textAlign: TextAlign.left,
            );
            if (labelImage != null) {
              bytes += generator.imageRaster(labelImage, align: PosAlign.left);
            }
            // Print value with text wrapping (max 380px for 58mm paper)
            final valueImage = await _textToImage(
              line.value,
              fontSize: 22,
              bold: false,
              textAlign: TextAlign.left,
              maxWidth: 380,
            );
            if (valueImage != null) {
              bytes += generator.imageRaster(valueImage, align: PosAlign.left);
            }
          } else {
            // Render as single row for short values
            final rowImage = await _rowToImage(
              line.label,
              line.value,
            );
            if (rowImage != null) {
              bytes += generator.imageRaster(rowImage, align: PosAlign.left);
            }
          }
          break;

        case PrintLineType.phone:
          // Phone numbers should always be LTR
          final phoneRowImage = await _rowToImage(
            line.label,
            line.value,
            valueLtr: true,
          );
          if (phoneRowImage != null) {
            bytes += generator.imageRaster(phoneRowImage, align: PosAlign.left);
          }
          break;

        case PrintLineType.status:
        case PrintLineType.coordinates:
        case PrintLineType.footer:
          // Skip these types
          break;
      }
    }

    // QR Code section
    bytes += generator.imageRaster(_getDividerSingle(), align: PosAlign.center);

    // Print QR code from the pre-generated image
    try {
      final qrDataUrl = ticketData.qrCode.dataUrl;
      final base64Data = qrDataUrl.split(',').last;
      final qrBytes = base64Decode(base64Data);
      final qrImage = img.decodeImage(qrBytes);
      if (qrImage != null) {
        // Resize to fill 58mm paper width (384 dots max, use 300 for QR)
        final resized = img.copyResize(qrImage, width: 300, height: 300);
        bytes += generator.imageRaster(resized, align: PosAlign.center);
      }
    } catch (e) {
      // Fallback to native QR command if image fails
      bytes += generator.qrcode(ticketData.qrCode.content, size: QRSize.Size6);
    }

    bytes += generator.text(
      ticketData.ticketNumber,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    // Raw cut command without extra feed (GS V 66 1 = partial cut with 1 line feed)
    bytes += [0x1D, 0x56, 0x42, 0x01];

    return bytes;
  }

  /// Print a parking ticket
  Future<bool> printTicket(PrintableTicketData ticketData) async {
    if (!isConnected) {
      _errorMessage = 'No printer connected';
      notifyListeners();
      return false;
    }

    // Block if already printing
    if (_isPrinting) {
      _errorMessage = 'Print job already in progress';
      notifyListeners();
      return false;
    }

    _isPrinting = true;
    _cancelRequested = false;
    notifyListeners();

    try {
      final bytes = await _buildTicketBytes(ticketData);
      return await _sendBytes(bytes);
    } catch (e) {
      _errorMessage = 'Print error: $e';
      notifyListeners();
      return false;
    } finally {
      _isPrinting = false;
      _cancelRequested = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _connection?.close();
    super.dispose();
  }
}

/// Singleton instance
final printerService = PrinterService();

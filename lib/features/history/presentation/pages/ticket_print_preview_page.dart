import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';
import '../../../create_ticket/data/repositories/ticket_repository.dart';

class TicketPrintPreviewPage extends StatefulWidget {
  final String ticketId;

  const TicketPrintPreviewPage({
    super.key,
    required this.ticketId,
  });

  @override
  State<TicketPrintPreviewPage> createState() => _TicketPrintPreviewPageState();
}

class _TicketPrintPreviewPageState extends State<TicketPrintPreviewPage> {
  PrintableTicketData? _printData;
  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey _printKey = GlobalKey();
  bool _dataLoaded = false;
  bool _hasPrinterError = false;
  bool _wasConnected = false;

  @override
  void initState() {
    super.initState();
    _wasConnected = printerService.isConnected;
    printerService.addListener(_onPrinterChanged);
  }

  @override
  void dispose() {
    printerService.removeListener(_onPrinterChanged);
    super.dispose();
  }

  void _onPrinterChanged() {
    if (!mounted) return;

    final isConnected = printerService.isConnected;

    // Clear error when printer connects
    if (isConnected && !_wasConnected) {
      _hasPrinterError = false;
    }

    // Show notification when printer disconnects unexpectedly
    if (!isConnected && _wasConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.print_disabled, color: Colors.white),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.noPrinterConnected),
            ],
          ),
          backgroundColor: AppColors.warning,
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.connectPrinter,
            textColor: Colors.white,
            onPressed: _showPrinterModal,
          ),
        ),
      );
    }

    _wasConnected = isConnected;
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load once - didChangeDependencies can be called multiple times
    if (!_dataLoaded) {
      _dataLoaded = true;
      _loadPrintData();
    }
  }

  Future<void> _loadPrintData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final l10n = AppLocalizations.of(context)!;

      // Fetch ticket data and QR code in parallel
      final results = await Future.wait([
        ticketRepository.getTicketById(widget.ticketId),
        ticketRepository.getTicketQrCode(widget.ticketId),
      ]);

      final ticket = results[0] as Ticket;
      final qrCode = results[1] as QrCodeData;

      // Build PrintableTicketData with localized labels
      // (parking zone is already populated in ticket)
      final data = PrintableTicketData.fromTicket(
        ticket: ticket,
        qrCode: qrCode,
        l10n: l10n,
      );

      if (mounted) {
        setState(() {
          _printData = data;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.failedToLoadPrintData;
          _isLoading = false;
        });
      }
    }
  }

  /// Show printer settings in a bottom modal sheet
  void _showPrinterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PrinterBottomSheet(),
    );
  }

  Future<void> _openPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openMap(String coordinates) async {
    final parts = coordinates.split(',').map((s) => s.trim()).toList();
    if (parts.length == 2) {
      final lat = parts[0];
      final lng = parts[1];
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _handlePrint() async {
    final l10n = AppLocalizations.of(context)!;

    // Check if printer is connected
    if (!printerService.isConnected) {
      // Show printer modal instead of navigating
      _showPrinterModal();
      setState(() {
        _hasPrinterError = true;
      });
      return;
    }

    // Show printing indicator with stop button
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.printing)),
            ],
          ),
          action: SnackBarAction(
            label: l10n.stopPrint,
            textColor: Colors.white,
            onPressed: () {
              printerService.cancelPrint();
            },
          ),
          duration: const Duration(seconds: 30),
        ),
      );
    }

    // Print the ticket
    final success = await printerService.printTicket(_printData!);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Check if it was cancelled
      final wasCancelled = printerService.errorMessage == 'Print cancelled';

      // Update printer error state
      setState(() {
        _hasPrinterError = !success && !wasCancelled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? l10n.printSuccess
              : wasCancelled
                  ? l10n.printCancelled
                  : '${l10n.printFailed}: ${printerService.errorMessage ?? "Unknown error"}'),
          backgroundColor: success
              ? AppColors.success
              : wasCancelled
                  ? AppColors.warning
                  : AppColors.error,
          duration: Duration(seconds: success ? 3 : 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Show printer button if not connected or has error
    final showPrinterButton = !printerService.isConnected || _hasPrinterError;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.printPreview),
        actions: [
          if (showPrinterButton)
            IconButton(
              icon: Icon(
                Icons.print,
                color: printerService.isConnected ? null : AppColors.warning,
              ),
              onPressed: _showPrinterModal,
              tooltip: l10n.printerSettings,
            ),
        ],
      ),
      body: _buildBody(l10n),
      bottomNavigationBar: _printData != null ? _buildBottomBar(l10n, showPrinterButton) : null,
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(l10n.error, style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _loadPrintData,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: RepaintBoundary(
        key: _printKey,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with logo/title
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/icons/parkup-logo.png',
                        height: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.parkingTicket,
                      style: AppTextStyles.h2.copyWith(
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),

              // Ticket content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Lines
                    ..._printData!.lines.map((line) => _buildLine(line, l10n)),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // QR Code
                    Text(
                      l10n.scanToPay,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQrCode(),
                    const SizedBox(height: 8),
                    Text(
                      _printData!.ticketNumber,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLine(PrintableTicketLine line, AppLocalizations l10n) {
    switch (line.type) {
      case PrintLineType.header:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Center(
            child: Text(
              line.value,
              style: AppTextStyles.h1.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
        );

      case PrintLineType.plate:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Center(
            child: LicensePlateDisplay.fromString(
              line.value,
              scale: 1.0,
            ),
          ),
        );

      case PrintLineType.amount:
        return _buildDetailRow(
          line.label,
          line.value,
          valueStyle: AppTextStyles.h3.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        );

      case PrintLineType.status:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(line.label, style: AppTextStyles.bodySmall),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(line.value).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  line.value,
                  style: AppTextStyles.label.copyWith(
                    color: _getStatusColor(line.value),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

      case PrintLineType.phone:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(line.label, style: AppTextStyles.bodySmall),
              GestureDetector(
                onTap: () => _openPhone(line.value),
                // Force LTR for phone numbers
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    line.value,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case PrintLineType.coordinates:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(line.label, style: AppTextStyles.bodySmall),
              GestureDetector(
                onTap: () => _openMap(line.value),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.viewOnMap,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case PrintLineType.footer:
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            line.value,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        );

      case PrintLineType.date:
      case PrintLineType.text:
        return _buildDetailRow(line.label, line.value);
    }
  }

  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
    // For long values, show label and value on separate lines
    if (value.length > 25) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: valueStyle ??
                  AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: valueStyle ??
                  AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCode() {
    final dataUrl = _printData!.qrCode.dataUrl;
    // Extract base64 from data URL
    final base64Data = dataUrl.split(',').last;
    final bytes = base64Decode(base64Data);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Image.memory(
        Uint8List.fromList(bytes),
        width: 150,
        height: 150,
        fit: BoxFit.contain,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'paid':
        return AppColors.success;
      case 'overdue':
        return AppColors.error;
      case 'appealed':
        return AppColors.info;
      case 'dismissed':
        return AppColors.secondary;
      case 'sabot removed':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildBottomBar(AppLocalizations l10n, bool showPrinterButton) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (showPrinterButton) ...[
              IconButton(
                onPressed: _showPrinterModal,
                icon: Icon(
                  printerService.isConnected ? Icons.settings : Icons.print_disabled,
                  color: printerService.isConnected ? AppColors.textSecondary : AppColors.warning,
                ),
                tooltip: l10n.printerSettings,
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handlePrint,
                icon: const Icon(Icons.print),
                label: Text(l10n.print),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for printer settings
class _PrinterBottomSheet extends StatefulWidget {
  const _PrinterBottomSheet();

  @override
  State<_PrinterBottomSheet> createState() => _PrinterBottomSheetState();
}

class _PrinterBottomSheetState extends State<_PrinterBottomSheet> {
  bool _showAllDevices = false;

  @override
  void initState() {
    super.initState();
    printerService.addListener(_onServiceChanged);
    // Auto-start scan when modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!printerService.isConnected) {
        printerService.startScan();
      }
    });
  }

  @override
  void dispose() {
    printerService.removeListener(_onServiceChanged);
    printerService.stopScanSilent();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool _isProbablyPrinter(String? name) {
    if (name == null || name.isEmpty) return false;
    final lowerName = name.toLowerCase();
    final printerKeywords = [
      'print', 'printer', 'pos', 'thermal', 'receipt',
      '58mm', '80mm', '58', '80',
      'esc', 'escpos', 'esc/pos',
      'epson', 'star', 'bixolon', 'xprinter', 'goojprt', 'munbyn',
      'rongta', 'hoin', 'milestone', 'netum', 'issyzonepos',
      'zjiang', 'gprinter', 'sewoo', 'citizen', 'custom',
      'MPT', 'mpt', 'rpm', 'spp', 'bt-', 'pt-', 'rpp',
    ];
    return printerKeywords.any((keyword) => lowerName.contains(keyword));
  }

  List<BluetoothDiscoveryResult> get _filteredDevices {
    final devices = printerService.discoveredDevices;
    if (_showAllDevices) return devices;
    final printers = devices.where((d) => _isProbablyPrinter(d.device.name)).toList();
    printers.sort((a, b) => (b.rssi).compareTo(a.rssi));
    return printers;
  }

  Future<void> _connectToDevice(BluetoothDiscoveryResult result) async {
    final success = await printerService.connect(result);
    if (mounted && success) {
      Navigator.of(context).pop(); // Close modal on successful connection
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(l10n.printerSettings, style: AppTextStyles.h3),
                const Spacer(),
                if (printerService.isScanning)
                  IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: () => printerService.stopScan(),
                    tooltip: l10n.stopScan,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => printerService.startScan(),
                    tooltip: l10n.scanForPrinters,
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Connection status
          if (printerService.isConnected)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.printerConnected, style: AppTextStyles.label),
                        Text(
                          printerService.connectedPrinter?.name ?? '',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => printerService.disconnect(),
                    child: Text(l10n.disconnectPrinter),
                  ),
                ],
              ),
            ),
          // Error message
          if (printerService.errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      printerService.errorMessage!,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          // Device list
          Expanded(
            child: printerService.isScanning && _filteredDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(l10n.scanning, style: AppTextStyles.bodySmall),
                      ],
                    ),
                  )
                : _filteredDevices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bluetooth_searching, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(l10n.noDevicesFound, style: AppTextStyles.bodySmall),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => setState(() => _showAllDevices = !_showAllDevices),
                              child: Text(_showAllDevices ? 'Show printers only' : 'Show all devices'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredDevices.length,
                        itemBuilder: (context, index) {
                          final result = _filteredDevices[index];
                          final device = result.device;
                          final isConnecting = printerService.status == PrinterConnectionStatus.connecting;

                          return ListTile(
                            leading: Icon(
                              device.isBonded ? Icons.bluetooth_connected : Icons.bluetooth,
                              color: device.isBonded ? AppColors.primary : null,
                            ),
                            title: Text(device.name ?? 'Unknown Device'),
                            subtitle: Text(device.address),
                            trailing: isConnecting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.chevron_right),
                            onTap: isConnecting ? null : () => _connectToDevice(result),
                          );
                        },
                      ),
          ),
          // Toggle show all devices
          if (_filteredDevices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () => setState(() => _showAllDevices = !_showAllDevices),
                child: Text(_showAllDevices ? 'Show printers only' : 'Show all devices'),
              ),
            ),
        ],
      ),
    );
  }
}

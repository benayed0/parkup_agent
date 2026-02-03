import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../../l10n/app_localizations.dart';
import '../core.dart';

/// Reusable bottom sheet for Bluetooth printer discovery and connection.
/// Shows scanning state, device list, connection status, and error messages.
class PrinterBottomSheet extends StatefulWidget {
  const PrinterBottomSheet({super.key});

  /// Show the printer bottom sheet as a modal.
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PrinterBottomSheet(),
    );
  }

  @override
  State<PrinterBottomSheet> createState() => _PrinterBottomSheetState();
}

class _PrinterBottomSheetState extends State<PrinterBottomSheet> {
  bool _showAllDevices = false;

  @override
  void initState() {
    super.initState();
    printerService.addListener(_onServiceChanged);
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
    const printerKeywords = [
      'print', 'printer', 'pos', 'thermal', 'receipt',
      '58mm', '80mm', '58', '80',
      'esc', 'escpos', 'esc/pos',
      'epson', 'star', 'bixolon', 'xprinter', 'goojprt',
      'munbyn', 'rongta', 'hoin', 'milestone', 'netum',
      'issyzonepos', 'zjiang', 'gprinter', 'sewoo', 'citizen', 'custom',
      'MPT', 'mpt', 'rpm', 'spp', 'bt-', 'pt-', 'rpp',
    ];
    return printerKeywords.any((keyword) => lowerName.contains(keyword));
  }

  List<BluetoothDiscoveryResult> get _filteredDevices {
    final devices = printerService.discoveredDevices;
    if (_showAllDevices) return devices;
    final printers = devices
        .where((d) => _isProbablyPrinter(d.device.name))
        .toList();
    printers.sort((a, b) => (b.rssi).compareTo(a.rssi));
    return printers;
  }

  Future<void> _connectToDevice(BluetoothDiscoveryResult result) async {
    final success = await printerService.connect(result);
    if (mounted && success) {
      Navigator.of(context).pop();
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
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
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
                        Icon(
                          Icons.bluetooth_searching,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noDevicesFound,
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(
                            () => _showAllDevices = !_showAllDevices,
                          ),
                          child: Text(
                            _showAllDevices
                                ? l10n.showPrintersOnly
                                : l10n.showAllDevices,
                          ),
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
                      final isConnecting =
                          printerService.status ==
                          PrinterConnectionStatus.connecting;

                      return ListTile(
                        leading: Icon(
                          device.isBonded
                              ? Icons.bluetooth_connected
                              : Icons.bluetooth,
                          color: device.isBonded ? AppColors.primary : null,
                        ),
                        title: Text(device.name ?? l10n.unknownDevice),
                        subtitle: Text(device.address),
                        trailing: isConnecting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: isConnecting
                            ? null
                            : () => _connectToDevice(result),
                      );
                    },
                  ),
          ),
          // Toggle show all devices
          if (_filteredDevices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () =>
                    setState(() => _showAllDevices = !_showAllDevices),
                child: Text(
                  _showAllDevices ? l10n.showPrintersOnly : l10n.showAllDevices,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

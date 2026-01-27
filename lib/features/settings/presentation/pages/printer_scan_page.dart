import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/core.dart';

/// Printer scan page
/// Allows users to discover and connect to Bluetooth thermal printers
class PrinterScanPage extends StatefulWidget {
  const PrinterScanPage({super.key});

  @override
  State<PrinterScanPage> createState() => _PrinterScanPageState();
}

class _PrinterScanPageState extends State<PrinterScanPage> {
  bool _showAllDevices = false;

  /// Check if device name suggests it's a thermal printer
  bool _isProbablyPrinter(String? name) {
    if (name == null || name.isEmpty) return false;
    final lowerName = name.toLowerCase();

    // Common thermal printer keywords
    final printerKeywords = [
      'print', 'printer', 'pos', 'thermal', 'receipt',
      '58mm', '80mm', '58', '80',
      'esc', 'escpos', 'esc/pos',
      // Common brands
      'epson', 'star', 'bixolon', 'xprinter', 'goojprt', 'munbyn',
      'rongta', 'hoin', 'milestone', 'netum', 'issyzonepos',
      'zjiang', 'gprinter', 'sewoo', 'citizen', 'custom',
      'MPT', 'mpt', 'rpm', 'spp', 'bt-', 'pt-', 'rpp',
    ];

    return printerKeywords.any((keyword) => lowerName.contains(keyword));
  }

  /// Get filtered device list
  List<BluetoothDiscoveryResult> get _filteredDevices {
    final devices = printerService.discoveredDevices;
    if (_showAllDevices) return devices;

    // Filter to likely printers, sorted by signal strength
    final printers = devices
        .where((d) => _isProbablyPrinter(d.device.name))
        .toList();
    printers.sort(
      (a, b) => (b.rssi).compareTo(a.rssi),
    ); // Stronger signal first
    return printers;
  }

  @override
  void initState() {
    super.initState();
    printerService.addListener(_onServiceChanged);
    // Auto-start scan when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
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

  Future<void> _startScan() async {
    await printerService.startScan();
  }

  Future<void> _connectToDevice(BluetoothDiscoveryResult result) async {
    final l10n = AppLocalizations.of(context)!;
    final success = await printerService.connect(result);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.printerConnected),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(printerService.errorMessage ?? l10n.connectionFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    await printerService.disconnect();
  }

  Future<void> _testPrint() async {
    final l10n = AppLocalizations.of(context)!;

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
            Text(l10n.printing),
          ],
        ),
        duration: const Duration(seconds: 5),
      ),
    );

    final success = await printerService.printTestPage();

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.printSuccess : l10n.printFailed),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.printerSettings),
        actions: [
          if (printerService.isScanning)
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: l10n.stopScan,
              onPressed: () => printerService.stopScan(),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: l10n.scanForPrinters,
              onPressed: _startScan,
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Connection status card
                    _buildStatusCard(l10n),

                    // Error message if any
                    if (printerService.errorMessage != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
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

                    const SizedBox(height: 16),

                    // Scanning indicator or device list
                    _buildDeviceList(l10n, constraints.maxHeight * 0.5),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(AppLocalizations l10n) {
    final isConnected = printerService.isConnected;
    final connectedPrinter = printerService.connectedPrinter;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? AppColors.success : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.success
                      : AppColors.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isConnected
                      ? l10n.connectedTo(connectedPrinter?.name ?? 'Printer')
                      : l10n.noPrinterConnected,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isConnected)
                Icon(Icons.print, color: AppColors.success, size: 24),
            ],
          ),
          if (isConnected && connectedPrinter != null) ...[
            const SizedBox(height: 8),
            Text(connectedPrinter.address, style: AppTextStyles.caption),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _disconnect,
                    icon: const Icon(Icons.link_off),
                    label: Text(l10n.disconnectPrinter),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testPrint,
                    icon: const Icon(Icons.print),
                    label: Text(l10n.testPrint),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
          // Saved printer hint when not connected
          if (!isConnected && printerService.hasSavedPrinter) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.history, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.savedPrinter,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                        Text(
                          printerService.savedPrinter?.name ?? '',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final success = await printerService
                          .reconnectToSavedPrinter();
                      if (mounted && !success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              printerService.errorMessage ??
                                  l10n.reconnectionFailed,
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
                    child: Text(l10n.connectPrinter),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceList(AppLocalizations l10n, double minHeight) {
    final allDevices = printerService.discoveredDevices;
    final devices = _filteredDevices;
    final hiddenCount = allDevices.length - devices.length;

    if (printerService.isScanning && allDevices.isEmpty) {
      return SizedBox(
        height: minHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.scanning, style: AppTextStyles.body),
              const SizedBox(height: 8),
              Text(
                l10n.makeSurePrinterOn,
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      );
    }

    if (devices.isEmpty) {
      return SizedBox(
        height: minHeight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bluetooth_searching,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _showAllDevices ? l10n.noDevicesFound : l10n.noPrintersFound,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.turnOnPrinterAndScan,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startScan,
                icon: const Icon(Icons.bluetooth_searching),
                label: Text(l10n.scanForPrinters),
              ),
              if (!_showAllDevices && hiddenCount > 0) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _showAllDevices = true),
                  child: Text(l10n.showAllDevicesCount(hiddenCount)),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                _showAllDevices ? l10n.availableDevices : l10n.printers,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text('(${devices.length})', style: AppTextStyles.caption),
              if (printerService.isScanning) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
              const Spacer(),
              if (hiddenCount > 0 || _showAllDevices)
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showAllDevices = !_showAllDevices),
                  icon: Icon(
                    _showAllDevices ? Icons.filter_list : Icons.filter_list_off,
                    size: 18,
                  ),
                  label: Text(
                    _showAllDevices
                        ? l10n.printersOnly
                        : l10n.showAllCount(hiddenCount),
                    style: AppTextStyles.caption,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final result = devices[index];
            final device = result.device;
            final isConnecting =
                printerService.status == PrinterConnectionStatus.connecting;
            final isThisDeviceConnected =
                printerService.isConnected &&
                printerService.connectedPrinter?.address == device.address;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: _buildDeviceIcon(
                  device.name,
                  device.isBonded,
                  isThisDeviceConnected,
                ),
                title: Text(
                  device.name ?? l10n.unknownDevice,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.address, style: AppTextStyles.caption),
                    if (!device.isBonded)
                      Text(
                        l10n.notPairedTapToPair,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.warning,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
                trailing: isThisDeviceConnected
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : isConnecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : device.isBonded
                    ? const Icon(Icons.chevron_right)
                    : const Icon(Icons.bluetooth, color: AppColors.warning),
                onTap: isThisDeviceConnected || isConnecting
                    ? null
                    : () => _connectToDevice(result),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDeviceIcon(String? deviceName, bool isPaired, bool isConnected) {
    IconData icon;
    Color color;

    final name = deviceName?.toLowerCase() ?? '';

    if (isConnected) {
      icon = Icons.print;
      color = AppColors.success;
    } else if (name.contains('print') ||
        name.contains('pos') ||
        name.contains('thermal') ||
        name.contains('58') ||
        name.contains('80')) {
      icon = Icons.print;
      color = isPaired ? AppColors.primary : AppColors.warning;
    } else {
      icon = Icons.bluetooth;
      color = isPaired ? AppColors.textSecondary : AppColors.warning;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }
}

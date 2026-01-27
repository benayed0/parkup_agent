import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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

  Future<void> _shareAsImage() async {
    try {
      final boundary = _printKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/ticket_${_printData?.ticketNumber ?? 'unknown'}.png',
      );
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Parking Ticket #${_printData?.ticketNumber}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.failedToShare}: $e')),
        );
      }
    }
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
      // Navigate to printer scan page
      await Navigator.of(context).pushNamed(AppRoutes.printerScan);

      // If still not connected after returning, show message
      if (!printerService.isConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.connectToPrinterFirst),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.printPreview),
        actions: [
          if (_printData != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareAsImage,
              tooltip: l10n.shareAsImage,
            ),
        ],
      ),
      body: _buildBody(l10n),
      bottomNavigationBar: _printData != null ? _buildBottomBar(l10n) : null,
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

  Widget _buildBottomBar(AppLocalizations l10n) {
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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareAsImage,
                icon: const Icon(Icons.share),
                label: Text(l10n.share),
              ),
            ),
            const SizedBox(width: 12),
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

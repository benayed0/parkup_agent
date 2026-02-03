import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';
import '../../../create_ticket/data/repositories/ticket_repository.dart';

class TicketPrintPreviewPage extends StatefulWidget {
  final String ticketId;

  const TicketPrintPreviewPage({super.key, required this.ticketId});

  @override
  State<TicketPrintPreviewPage> createState() => _TicketPrintPreviewPageState();
}

class _TicketPrintPreviewPageState extends State<TicketPrintPreviewPage> {
  Ticket? _ticket;
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
    localeService.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    printerService.removeListener(_onPrinterChanged);
    localeService.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
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
    if (!_dataLoaded) {
      _dataLoaded = true;
      _loadTicket();
    }
  }

  Future<void> _loadTicket() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ticket = await ticketRepository.getTicketById(widget.ticketId);

      if (mounted) {
        setState(() {
          _ticket = ticket;
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

  void _showPrinterModal() {
    PrinterBottomSheet.show(context);
  }

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocaleService.supportedLocales.map((locale) {
            final isSelected =
                localeService.currentLocale?.languageCode ==
                    locale.languageCode;
            return ListTile(
              leading: Text(
                LocaleService.getLocaleFlag(locale),
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(LocaleService.getLocaleName(locale)),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              selected: isSelected,
              onTap: () {
                localeService.setLocale(locale);
                Navigator.of(dialogContext).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _openPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handlePrint() async {
    final l10n = AppLocalizations.of(context)!;

    if (!printerService.isConnected) {
      _showPrinterModal();
      setState(() {
        _hasPrinterError = true;
      });
      return;
    }

    // Build PrintableTicketData for the printer service
    final printData = PrintableTicketData.fromTicket(
      ticket: _ticket!,
      l10n: l10n,
    );

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

    final success = await printerService.printTicket(printData);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final wasCancelled = printerService.errorMessage == l10n.printCancelled;

      setState(() {
        _hasPrinterError = !success && !wasCancelled;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? l10n.printSuccess
                : wasCancelled
                ? l10n.printCancelled
                : '${l10n.printFailed}: ${printerService.errorMessage ?? l10n.unknownError}',
          ),
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

    final showPrinterButton = !printerService.isConnected || _hasPrinterError;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.printPreview),
        actions: [
          IconButton(
            icon: Text(
              LocaleService.getLocaleFlag(
                localeService.currentLocale ?? const Locale('en'),
              ),
              style: const TextStyle(fontSize: 20),
            ),
            onPressed: () => _showLanguageDialog(context),
            tooltip: l10n.language,
          ),
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
      bottomNavigationBar: _ticket != null
          ? _buildBottomBar(l10n, showPrinterButton)
          : null,
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
                onPressed: _loadTicket,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    final ticket = _ticket!;
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final parkingZone = ticket.parkingZone;

    // Get localized reason
    String reasonLabel;
    switch (ticket.reason) {
      case TicketReason.carSabot:
        reasonLabel = l10n.printReasonCarSabot;
        break;
      case TicketReason.pound:
        reasonLabel = l10n.printReasonPound;
        break;
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
                        'assets/icons/parkup-agent-logo.png',
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
                    // License plate
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        children: [
                          Text(
                            l10n.printLabelPlate,
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          LicensePlateDisplay.fromPlate(
                            ticket.plate,
                            scale: 1.0,
                          ),
                        ],
                      ),
                    ),

                    // Reason
                    _buildDetailRow(l10n.printLabelReason, reasonLabel),

                    // Fine amount
                    _buildDetailRow(
                      l10n.printLabelFine,
                      '${ticket.fineAmount.toStringAsFixed(0)} TND',
                      valueStyle: AppTextStyles.h3.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Date
                    _buildDetailRow(
                      l10n.printLabelDate,
                      dateFormat.format(ticket.issuedAt),
                    ),

                    // Time
                    _buildDetailRow(
                      l10n.printLabelTime,
                      timeFormat.format(ticket.issuedAt),
                    ),

                    // Address
                    if (ticket.address != null && ticket.address!.isNotEmpty)
                      _buildDetailRow(l10n.printLabelAddress, ticket.address!),

                    // Parking zone info
                    if (parkingZone != null) ...[
                      _buildDetailRow(l10n.printLabelZone, parkingZone.name),
                      if (parkingZone.address != null &&
                          parkingZone.address!.isNotEmpty)
                        _buildDetailRow(
                          l10n.printLabelZoneAddress,
                          parkingZone.address!,
                        ),
                      if (parkingZone.phoneNumber != null &&
                          parkingZone.phoneNumber!.isNotEmpty)
                        _buildPhoneRow(
                          l10n.printLabelZonePhone,
                          parkingZone.phoneNumber!,
                        ),
                    ],

                    // Location
                    _buildLocationRow(l10n, ticket),

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
                      ticket.ticketNumber,
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

  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle}) {
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
              style:
                  valueStyle ??
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
              style:
                  valueStyle ??
                  AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneRow(String label, String phone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          GestureDetector(
            onTap: () => _openPhone(phone),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                phone,
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
  }

  Widget _buildLocationRow(AppLocalizations l10n, Ticket ticket) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.goToLocation, style: AppTextStyles.bodySmall),
          GestureDetector(
            onTap: () => _openMap(
              ticket.position.latitude,
              ticket.position.longitude,
            ),
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
  }

  Widget _buildQrCode() {
    final qrCode = _ticket!.qrCode;
    if (qrCode == null) {
      return const SizedBox.shrink();
    }
    final base64Data = qrCode.dataUrl.split(',').last;
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
                  printerService.isConnected
                      ? Icons.settings
                      : Icons.print_disabled,
                  color: printerService.isConnected
                      ? AppColors.textSecondary
                      : AppColors.warning,
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

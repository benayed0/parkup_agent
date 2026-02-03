import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../create_ticket/data/repositories/ticket_repository.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../widgets/check_result_card.dart';

/// Check vehicle page - optimized for fast agent workflow
/// Auto-checks when plate is complete, minimal friction
class CheckVehiclePage extends StatefulWidget {
  const CheckVehiclePage({super.key});

  @override
  State<CheckVehiclePage> createState() => _CheckVehiclePageState();
}

class _CheckVehiclePageState extends State<CheckVehiclePage> {
  bool _isLoading = false;
  bool _isCreatingTicket = false;
  VehicleCheckResult? _checkResult;
  LicensePlate _currentPlate = const LicensePlate.empty();
  LicensePlate? _lastCheckedPlate; // Track what we already checked
  Position? _position;
  Timer? _debounceTimer;
  int _inputKey = 0; // Key to force rebuild of input widget
  Ticket? _createdTicket; // Track ticket just created for print flow
  bool _isPrinting = false;

  // Parking zone selection
  List<ParkingZone> _zones = [];
  ParkingZone? _selectedZone;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadZones();

    // Parse route arguments after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _parseRouteArguments();
    });
  }

  void _parseRouteArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Map<String, dynamic>) return;

    // Parse plate data
    final plateData = args['plate'] as Map<String, dynamic>?;
    final licensePlate = args['licensePlate'] as String?;
    final zoneId = args['zoneId'] as String?;

    // Set zone if provided
    if (zoneId != null && _zones.isNotEmpty) {
      final zone = _zones.where((z) => z.id == zoneId).firstOrNull;
      if (zone != null) {
        setState(() => _selectedZone = zone);
      }
    }

    // Parse and set plate
    if (plateData != null) {
      final plate = _parsePlateFromApi(plateData);
      if (plate != null) {
        setState(() {
          _currentPlate = plate;
          _inputKey++; // Force input widget to rebuild with new values
        });
        // Trigger auto-check after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _isPlateComplete(_currentPlate)) {
            _handleAutoCheck();
          }
        });
      }
    } else if (licensePlate != null && licensePlate.isNotEmpty) {
      // Fallback: just set formatted string (won't be parsed properly)
      setState(() {
        _currentPlate = LicensePlate(
          type: PlateType.tunis,
          left: licensePlate,
        );
        _inputKey++;
      });
    }
  }

  /// Parse plate data from API format to LicensePlate
  LicensePlate? _parsePlateFromApi(Map<String, dynamic> data) {
    final typeStr = data['type'] as String?;
    if (typeStr == null) return null;

    // Map API type string to PlateType enum
    final type = _plateTypeFromString(typeStr);

    return LicensePlate(
      type: type,
      left: data['left'] as String?,
      right: data['right'] as String?,
    );
  }

  /// Convert API plate type string to PlateType enum
  PlateType _plateTypeFromString(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'tunis':
        return PlateType.tunis;
      case 'rs':
        return PlateType.rs;
      case 'government':
        return PlateType.government;
      case 'libya':
        return PlateType.libya;
      case 'algeria':
        return PlateType.algeria;
      case 'eu':
        return PlateType.eu;
      case 'other':
        return PlateType.other;
      case 'cmd':
        return PlateType.cmd;
      case 'cd':
        return PlateType.cd;
      case 'md':
        return PlateType.md;
      case 'pat':
        return PlateType.pat;
      case 'cc':
        return PlateType.cc;
      case 'mc':
        return PlateType.mc;
      default:
        return PlateType.tunis;
    }
  }

  void _loadZones() {
    final agent = authRepository.currentAgent;
    if (agent != null && agent.assignedZones != null && agent.assignedZones!.isNotEmpty) {
      setState(() {
        _zones = agent.assignedZones!;
        _selectedZone = _zones.first; // Default to first zone
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initLocation() async {
    _position = locationService.cachedPosition;
    if (_position != null) return;

    // Try to get position
    await _refreshPosition();
  }

  Future<void> _refreshPosition() async {
    print('[GPS] _refreshPosition called');

    // Re-init the location service (handles hot reload)
    print('[GPS] Calling locationService.init()...');
    final initResult = await locationService.init();
    print('[GPS] locationService.init() returned: $initResult');

    print('[GPS] Calling locationService.refreshPosition()...');
    final pos = await locationService.refreshPosition();
    print('[GPS] refreshPosition returned: $pos');

    if (mounted && pos != null) {
      print('[GPS] Setting position: lat=${pos.latitude}, lng=${pos.longitude}');
      setState(() => _position = pos);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.gpsLocationUpdated),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
        ),
      );
    } else if (mounted) {
      print('[GPS] Could not get position. mounted=$mounted, pos=$pos');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.couldNotGetGpsLocation),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onPlateChanged(LicensePlate plate) {
    setState(() {
      _currentPlate = plate;
    });

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Clear result if plate changed significantly
    if (_checkResult != null && _lastCheckedPlate != plate) {
      setState(() => _checkResult = null);
    }

    // Auto-check when plate is complete
    if (_isPlateComplete(plate) && plate != _lastCheckedPlate) {
      // Short debounce to avoid checking while still typing
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        _handleAutoCheck();
      });
    }
  }

  /// Check if plate has enough data to be complete
  bool _isPlateComplete(LicensePlate plate) {
    if (plate.isEmpty) return false;

    // Single field types (RS, EU, Libya, Algeria, Other)
    if (plate.type.hasRightLabel ||
        plate.type.isEu ||
        plate.type.isLibya ||
        plate.type.isAlgeria ||
        plate.type.isOther) {
      // Need at least 2 characters for single field
      return (plate.left?.length ?? 0) >= 2;
    }

    // Two field types - both must have data
    return (plate.left?.isNotEmpty ?? false) &&
           (plate.right?.isNotEmpty ?? false);
  }

  bool get _isPlateValid => _isPlateComplete(_currentPlate);

  /// Auto-check triggered by plate completion
  Future<void> _handleAutoCheck() async {
    if (!_isPlateValid || _isLoading) return;

    // Don't re-check the same plate
    if (_currentPlate == _lastCheckedPlate) return;

    HapticFeedback.lightImpact();
    await _performCheck();
  }

  /// Manual check triggered by button
  Future<void> _handleManualCheck() async {
    if (!_isPlateValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseEnterValidPlate),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    await _performCheck();
  }

  /// Perform the actual check
  Future<void> _performCheck() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await vehicleRepository.checkVehicle(
        _currentPlate,
        zoneId: _selectedZone?.id,
      );

      if (!mounted) return;

      HapticFeedback.mediumImpact();
      setState(() {
        _isLoading = false;
        _checkResult = result;
        _lastCheckedPlate = _currentPlate;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _lastCheckedPlate = _currentPlate;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _lastCheckedPlate = _currentPlate;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToCheckVehicle),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleCreateTicket(TicketReason reason) async {
    final l10n = AppLocalizations.of(context)!;

    // Check if zone is selected
    if (_selectedZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseSelectParkingZone),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Get position with fallbacks
    Position? ticketPosition = _position;

    // Fallback 1: Try to get GPS position if not available
    if (ticketPosition == null) {
      final pos = await locationService.refreshPosition();
      if (pos != null) {
        ticketPosition = pos;
        if (mounted) setState(() => _position = pos);
      }
    }

    // Fallback 2: Use zone center location
    if (ticketPosition == null && _selectedZone!.location != null) {
      ticketPosition = _selectedZone!.location;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.usingZoneLocation),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    // Fallback 3: Default position (should rarely happen)
    ticketPosition ??= const Position(longitude: 10.1815, latitude: 36.8065); // Tunis center

    setState(() => _isCreatingTicket = true);
    HapticFeedback.selectionClick();

    // Get fine amount from zone prices
    final fineAmount = reason == TicketReason.carSabot
        ? _selectedZone!.prices.carSabot
        : _selectedZone!.prices.pound;

    try {
      final ticket = await ticketRepository.createTicket(
        plate: _currentPlate,
        position: ticketPosition,
        reason: reason,
        fineAmount: fineAmount,
        parkingZoneId: _selectedZone!.id,
      );

      if (!mounted) return;

      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text(l10n.ticketCreated(ticket.ticketNumber)),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() => _createdTicket = ticket);

    } on ApiException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToCreateTicket),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingTicket = false);
      }
    }
  }

  Future<void> _printTicket(Ticket ticket) async {
    final l10n = AppLocalizations.of(context)!;

    if (!printerService.isConnected) {
      PrinterBottomSheet.show(context);
      return;
    }

    setState(() => _isPrinting = true);

    try {
      // Re-fetch ticket to get QR code data
      final fullTicket = await ticketRepository.getTicketById(ticket.id);
      if (!mounted) return;

      final printData = PrintableTicketData.fromTicket(
        ticket: fullTicket,
        l10n: l10n,
      );

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
            onPressed: () => printerService.cancelPrint(),
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      final success = await printerService.printTicket(printData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final wasCancelled = printerService.errorMessage == l10n.printCancelled;

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

      if (success) {
        _clearAndReset();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.printFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  void _clearAndReset() {
    setState(() {
      _checkResult = null;
      _createdTicket = null;
      _currentPlate = const LicensePlate.empty();
      _lastCheckedPlate = null;
      _inputKey++; // Force input widget to rebuild with empty values
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.checkVehicle),
        actions: [
          // GPS indicator - tappable to refresh
          IconButton(
            onPressed: _refreshPosition,
            icon: Icon(
              _position != null ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: _position != null ? AppColors.success : AppColors.secondary,
            ),
            tooltip: l10n.refreshGps,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Parking zone selector
                      if (_zones.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<ParkingZone>(
                              value: _selectedZone,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down),
                              hint: Text(l10n.selectZone),
                              items: _zones.map((zone) {
                                return DropdownMenuItem<ParkingZone>(
                                  value: zone,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${zone.code} - ${zone.name}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (zone) {
                                if (zone != null) {
                                  setState(() => _selectedZone = zone);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // License plate input
                      LicensePlateInput(
                        key: ValueKey(_inputKey),
                        initialValue: _currentPlate.isEmpty ? null : _currentPlate,
                        onChanged: _onPlateChanged,
                        label: l10n.licensePlate,
                      ),

                      const SizedBox(height: 12),

                      // Loading indicator or Check button
                      if (_isLoading)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(strokeWidth: 3),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  l10n.checking,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_checkResult == null)
                        // Manual check button - large and easy to tap
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _isPlateValid ? _handleManualCheck : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isPlateValid ? AppColors.primary : AppColors.surface,
                              foregroundColor: _isPlateValid ? Colors.white : AppColors.textTertiary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.search, size: 24),
                            label: Text(
                              l10n.check,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      // Result display
                      if (_checkResult != null) ...[
                        const SizedBox(height: 12),

                        CheckResultCard(result: _checkResult!),

                        const SizedBox(height: 12),

                        // Post-creation: show Print + Done buttons
                        if (_createdTicket != null)
                          Row(
                            children: [
                              // Print ticket button
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed: _isPrinting
                                        ? null
                                        : () => _printTicket(_createdTicket!),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: _isPrinting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.print, size: 22),
                                    label: Text(
                                      _isPrinting ? l10n.printing : l10n.print,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Done / clear button
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: _isPrinting ? null : _clearAndReset,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.primary, width: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.check_circle_outline, size: 22),
                                    label: Text(
                                      l10n.done,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          // Only show ticket buttons if vehicle has an issue (not valid) and zone is selected
                          if (_checkResult!.hasIssue && _selectedZone != null) ...[
                            // Ticket reason buttons - large and easy to tap
                            Row(
                              children: [
                                Expanded(
                                  child: _ReasonButton(
                                    reason: TicketReason.carSabot,
                                    fineAmount: _selectedZone!.prices.carSabot,
                                    icon: Icons.lock,
                                    color: AppColors.warning,
                                    isLoading: _isCreatingTicket,
                                    onPressed: () => _handleCreateTicket(TicketReason.carSabot),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ReasonButton(
                                    reason: TicketReason.pound,
                                    fineAmount: _selectedZone!.prices.pound,
                                    icon: Icons.local_shipping,
                                    color: AppColors.error,
                                    isLoading: _isCreatingTicket,
                                    onPressed: () => _handleCreateTicket(TicketReason.pound),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Recheck and New search buttons
                          Row(
                            children: [
                              // Recheck button
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton.icon(
                                    onPressed: _isCreatingTicket || _isLoading ? null : _handleManualCheck,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.refresh, size: 22),
                                    label: Text(
                                      l10n.recheck,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // New search button
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton.icon(
                                    onPressed: _isCreatingTicket ? null : _clearAndReset,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.primary, width: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.search, size: 22),
                                    label: Text(
                                      l10n.newSearch,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],

                      // Empty state hint
                      if (_checkResult == null && !_isLoading) ...[
                        const Spacer(),
                        Icon(
                          Icons.directions_car,
                          size: 64,
                          color: AppColors.secondary.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.enterPlateThenCheck,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Reason button widget for ticket creation - compact but easy to tap
class _ReasonButton extends StatelessWidget {
  final TicketReason reason;
  final double fineAmount;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ReasonButton({
    required this.reason,
    required this.fineAmount,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                reason.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${fineAmount.toStringAsFixed(0)} TND',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

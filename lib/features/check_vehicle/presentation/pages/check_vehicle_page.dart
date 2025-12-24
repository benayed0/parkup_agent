import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Parking zone selection
  List<ParkingZone> _zones = [];
  ParkingZone? _selectedZone;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadZones();
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
        const SnackBar(
          content: Text('GPS location updated'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 1),
        ),
      );
    } else if (mounted) {
      print('[GPS] Could not get position. mounted=$mounted, pos=$pos');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get GPS location'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 2),
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
        const SnackBar(
          content: Text('Please enter a valid license plate'),
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
        const SnackBar(
          content: Text('Failed to check vehicle. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleCreateTicket(TicketReason reason) async {
    // Check if zone is selected
    if (_selectedZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a parking zone'),
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
          const SnackBar(
            content: Text('Using zone location (GPS unavailable)'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
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
        licensePlate: _checkResult!.licensePlate,
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
              Text('Ticket #${ticket.ticketNumber} created'),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );

      _clearAndReset();
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
        const SnackBar(
          content: Text('Failed to create ticket. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingTicket = false);
      }
    }
  }

  void _clearAndReset() {
    setState(() {
      _checkResult = null;
      _currentPlate = const LicensePlate.empty();
      _lastCheckedPlate = null;
      _inputKey++; // Force input widget to rebuild with empty values
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Vehicle'),
        actions: [
          // GPS indicator - tappable to refresh
          IconButton(
            onPressed: _refreshPosition,
            icon: Icon(
              _position != null ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: _position != null ? AppColors.success : AppColors.secondary,
            ),
            tooltip: 'Refresh GPS',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      hint: const Text('Select Zone'),
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
                label: 'License Plate',
              ),

              const SizedBox(height: 12),

              // Loading indicator or Check button
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Checking...',
                          style: TextStyle(
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
                    label: const Text(
                      'Check',
                      style: TextStyle(
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

                const Spacer(),

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
                          label: const Text(
                            'Recheck',
                            style: TextStyle(
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
                          label: const Text(
                            'New Search',
                            style: TextStyle(
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
                  'Enter license plate, then tap Check',
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

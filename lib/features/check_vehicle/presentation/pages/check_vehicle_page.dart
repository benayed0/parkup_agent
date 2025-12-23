import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';
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

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initLocation() async {
    _position = locationService.cachedPosition;
    if (_position != null) return;

    // Try to get position, retry a few times in background
    for (int i = 0; i < 5 && mounted && _position == null; i++) {
      final pos = await locationService.getCurrentPosition();
      if (mounted && pos != null) {
        setState(() => _position = pos);
        break;
      }
      if (i < 4) await Future.delayed(const Duration(seconds: 2));
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
      final result = await vehicleRepository.checkVehicle(_currentPlate);

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
    // Try to get position if not available
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Getting GPS location...'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 2),
        ),
      );

      // Try to get position with retries
      for (int i = 0; i < 3 && _position == null; i++) {
        final pos = await locationService.refreshPosition();
        if (pos != null && mounted) {
          setState(() => _position = pos);
          break;
        }
        if (i < 2) await Future.delayed(const Duration(seconds: 1));
      }

      // If still no position, show error and abort
      if (_position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot get GPS location. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isCreatingTicket = true);
    HapticFeedback.selectionClick();

    try {
      final ticket = await ticketRepository.createTicket(
        licensePlate: _checkResult!.licensePlate,
        position: _position!,
        reason: reason,
        fineAmount: reason.fineAmount,
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
          // GPS indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              _position != null ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: _position != null ? AppColors.success : AppColors.secondary,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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

                // Only show ticket buttons if vehicle has an issue (not valid)
                if (_checkResult!.hasIssue) ...[
                  // Ticket reason buttons - large and easy to tap
                  Row(
                    children: [
                      Expanded(
                        child: _ReasonButton(
                          reason: TicketReason.carSabot,
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

                // New search button - large and prominent at bottom
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isCreatingTicket ? null : _clearAndReset,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.refresh, size: 22),
                    label: const Text(
                      'New Search',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ReasonButton({
    required this.reason,
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
                '\$${reason.fineAmount.toStringAsFixed(0)}',
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

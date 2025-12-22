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

  void _initLocation() {
    _position = locationService.cachedPosition;
    if (_position == null) {
      locationService.getCurrentPosition().then((pos) {
        if (mounted && pos != null) {
          setState(() => _position = pos);
        }
      });
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
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waiting for GPS location...'),
          backgroundColor: AppColors.warning,
        ),
      );
      final pos = await locationService.refreshPosition();
      if (pos != null && mounted) {
        setState(() => _position = pos);
      }
      return;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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

              const SizedBox(height: 16),

              // Loading indicator or Check button
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Checking...'),
                      ],
                    ),
                  ),
                )
              else if (_checkResult == null)
                // Manual check button (fallback)
                TextButton.icon(
                  onPressed: _isPlateValid ? _handleManualCheck : null,
                  icon: const Icon(Icons.search, size: 20),
                  label: Text(
                    _isPlateValid ? 'Check Now' : 'Enter plate to auto-check',
                    style: TextStyle(
                      color: _isPlateValid
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),

              // Result display
              if (_checkResult != null) ...[
                const SizedBox(height: 8),
                CheckResultCard(result: _checkResult!),

                // Only show ticket buttons if vehicle has an issue (not valid)
                if (_checkResult!.hasIssue) ...[
                  const SizedBox(height: 24),

                  // Ticket reason buttons - prominent for quick action
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
                ],

                const SizedBox(height: 16),

                // New search - quick reset
                Center(
                  child: TextButton.icon(
                    onPressed: _isCreatingTicket ? null : _clearAndReset,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('New Search'),
                  ),
                ),
              ],

              // Empty state hint
              if (_checkResult == null && !_isLoading) ...[
                const SizedBox(height: 32),
                Icon(
                  Icons.speed,
                  size: 48,
                  color: AppColors.secondary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'Type plate number to auto-check',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Reason button widget for ticket creation
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 36,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                reason.label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '\$${reason.fineAmount.toStringAsFixed(0)}',
                style: AppTextStyles.h3.copyWith(
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

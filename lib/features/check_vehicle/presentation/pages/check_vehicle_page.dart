import 'package:flutter/material.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../widgets/check_result_card.dart';

/// Check vehicle page
/// Allows agent to check a vehicle's parking status
class CheckVehiclePage extends StatefulWidget {
  const CheckVehiclePage({super.key});

  @override
  State<CheckVehiclePage> createState() => _CheckVehiclePageState();
}

class _CheckVehiclePageState extends State<CheckVehiclePage> {
  bool _isLoading = false;
  VehicleCheckResult? _checkResult;
  LicensePlate _currentPlate = const LicensePlate.empty();

  void _onPlateChanged(LicensePlate plate) {
    setState(() {
      _currentPlate = plate;
    });
  }

  bool get _isPlateValid {
    if (_currentPlate.isEmpty) return false;
    if (_currentPlate.type.hasRightLabel ||
        _currentPlate.type.isEu ||
        _currentPlate.type.isLibya ||
        _currentPlate.type.isAlgeria ||
        _currentPlate.type.isOther) {
      return _currentPlate.left?.isNotEmpty ?? false;
    }
    return (_currentPlate.left?.isNotEmpty ?? false) &&
           (_currentPlate.right?.isNotEmpty ?? false);
  }

  Future<void> _handleCheck() async {
    if (!_isPlateValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid license plate'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _checkResult = null;
    });

    try {
      final result = await vehicleRepository.checkVehicle(
        _currentPlate.formatted,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _checkResult = result;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to check vehicle. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _handleCreateTicket() {
    if (_checkResult != null) {
      Navigator.of(context).pushNamed(
        AppRoutes.createTicket,
        arguments: _checkResult!.licensePlate,
      );
    }
  }

  void _clearResult() {
    setState(() {
      _checkResult = null;
      _currentPlate = const LicensePlate.empty();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check Vehicle'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // License plate input
              LicensePlateInput(
                initialValue: _currentPlate.isEmpty ? null : _currentPlate,
                onChanged: _onPlateChanged,
                label: 'License Plate',
              ),

              const SizedBox(height: 20),

              // Search button
              PrimaryButton(
                text: 'Check Vehicle',
                onPressed: _isPlateValid ? _handleCheck : null,
                isLoading: _isLoading,
                icon: Icons.search,
              ),

              const SizedBox(height: 24),

              // Result display
              if (_checkResult != null) ...[
                CheckResultCard(
                  result: _checkResult!,
                  onCreateTicket: _checkResult!.hasIssue ? _handleCreateTicket : null,
                ),

                const SizedBox(height: 16),

                // New search button
                OutlinedButton.icon(
                  onPressed: _clearResult,
                  icon: const Icon(Icons.refresh),
                  label: const Text('New Search'),
                ),
              ],

              // Empty state when no result
              if (_checkResult == null && !_isLoading) ...[
                const SizedBox(height: 48),
                Icon(
                  Icons.search,
                  size: 64,
                  color: AppColors.secondary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Enter a license plate to check parking status',
                  style: AppTextStyles.bodySmall,
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

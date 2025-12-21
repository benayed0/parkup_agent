import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart' as models;
import '../../../../shared/widgets/widgets.dart';
import '../../data/repositories/ticket_repository.dart';

/// Create ticket page
/// Form for issuing a new parking ticket
class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isGettingLocation = false;
  models.TicketReason? _selectedReason;
  models.Position? _currentPosition;
  String _currentPlate = '';
  PlateType _currentPlateType = PlateType.tunis;
  String? _initialPlate;

  void _onPlateChanged(String plate) {
    setState(() {
      _currentPlate = plate;
    });
  }

  void _onPlateTypeChanged(PlateType type) {
    setState(() {
      _currentPlateType = type;
    });
  }

  bool get _isPlateValid {
    if (_currentPlate.isEmpty) return false;
    final parsed = parseLicensePlate(_currentPlate, _currentPlateType);
    if (parsed.type.hasRightLabel) {
      return parsed.leftNumber.isNotEmpty;
    }
    return parsed.leftNumber.isNotEmpty && parsed.rightNumber.isNotEmpty;
  }

  // Fine amounts based on reason
  static const Map<models.TicketReason, double> _fineAmounts = {
    models.TicketReason.noSession: 50.0,
    models.TicketReason.expiredSession: 35.0,
    models.TicketReason.overstayed: 25.0,
    models.TicketReason.wrongZone: 40.0,
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill license plate if passed from check vehicle
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _initialPlate == null) {
      _initialPlate = args;
      _currentPlate = args;
      // Detect plate type from the initial value
      final parsed = parseLicensePlate(args);
      _currentPlateType = parsed.type;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permissions are denied'),
                backgroundColor: AppColors.warning,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = models.Position(
            longitude: position.longitude,
            latitude: position.latitude,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get current location'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  void _onLocationChanged(double latitude, double longitude) {
    setState(() {
      _currentPosition = models.Position(
        latitude: latitude,
        longitude: longitude,
      );
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isPlateValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid license plate'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location is required. Please enable location services.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ticket = await ticketRepository.createTicket(
        licensePlate: _currentPlate,
        position: _currentPosition!,
        reason: _selectedReason!,
        fineAmount: _fineAmounts[_selectedReason!] ?? 50.0,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket ${ticket.ticketNumber} created successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate back to home
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create ticket. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Ticket'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Location section
                _buildLocationSection(),

                const SizedBox(height: 24),

                // Section: Vehicle Information
                Text('Vehicle Information', style: AppTextStyles.h3),
                const SizedBox(height: 16),

                // License plate (required)
                LicensePlateInput(
                  initialValue: _initialPlate,
                  initialType: _currentPlateType,
                  onChanged: _onPlateChanged,
                  onTypeChanged: _onPlateTypeChanged,
                ),

                const SizedBox(height: 32),

                // Section: Violation Details
                Text('Violation Details', style: AppTextStyles.h3),
                const SizedBox(height: 16),

                // Violation reason (required)
                DropdownButtonFormField<models.TicketReason>(
                  initialValue: _selectedReason,
                  decoration: const InputDecoration(
                    labelText: 'Violation Reason *',
                    prefixIcon: Icon(Icons.warning_amber),
                  ),
                  items: models.TicketReason.values.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedReason = value);
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a violation reason';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Fine amount display
                if (_selectedReason != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fine Amount'),
                        Text(
                          '\$${_fineAmounts[_selectedReason]?.toStringAsFixed(2) ?? '0.00'}',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Notes (optional)
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Additional details...',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                ),

                const SizedBox(height: 32),

                // Submit button
                PrimaryButton(
                  text: 'Create Ticket',
                  onPressed: _handleSubmit,
                  isLoading: _isLoading,
                  icon: Icons.receipt_long,
                ),

                const SizedBox(height: 16),

                // Cancel button
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    if (_isGettingLocation) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Getting current location...',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    if (_currentPosition != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with coordinates
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                  style: AppTextStyles.bodySmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.my_location, size: 20),
                onPressed: _getCurrentLocation,
                tooltip: 'Get current location',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Map picker
          MapLocationPicker(
            initialLatitude: _currentPosition!.latitude,
            initialLongitude: _currentPosition!.longitude,
            onLocationChanged: _onLocationChanged,
            height: 250,
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Location not available',
              style: AppTextStyles.bodySmall,
            ),
          ),
          TextButton(
            onPressed: _getCurrentLocation,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

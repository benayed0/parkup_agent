import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart' as models;
import '../../data/repositories/ticket_repository.dart';

/// Quick ticket page - Optimized for speed
/// Minimal UI for ultra-fast ticket creation
class QuickTicketPage extends StatefulWidget {
  const QuickTicketPage({super.key});

  @override
  State<QuickTicketPage> createState() => _QuickTicketPageState();
}

class _QuickTicketPageState extends State<QuickTicketPage> {
  final _leftController = TextEditingController();
  final _rightController = TextEditingController();
  final _leftFocus = FocusNode();
  final _rightFocus = FocusNode();

  bool _isSubmitting = false;
  models.Position? _position;
  PlateType _plateType = PlateType.tunis;
  String? _initialPlate;

  // Fine amounts
  static const Map<models.TicketReason, double> _fines = {
    models.TicketReason.noSession: 50.0,
    models.TicketReason.expiredSession: 35.0,
    models.TicketReason.overstayed: 25.0,
    models.TicketReason.wrongZone: 40.0,
  };

  @override
  void initState() {
    super.initState();
    _initLocation();
    // Auto-focus plate input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _leftFocus.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-fill license plate if passed
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _initialPlate == null) {
      _initialPlate = args;
      final parsed = parseLicensePlate(args);
      _plateType = parsed.type;
      _leftController.text = parsed.leftNumber;
      _rightController.text = parsed.rightNumber;
    }
  }

  void _initLocation() {
    // Use pre-cached location for instant availability
    _position = locationService.cachedPosition;
    if (_position == null) {
      locationService.getCurrentPosition().then((pos) {
        if (mounted && pos != null) {
          setState(() => _position = pos);
        }
      });
    }
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    _leftFocus.dispose();
    _rightFocus.dispose();
    super.dispose();
  }

  String get _plateFormatted {
    final left = _leftController.text.trim();
    final right = _rightController.text.trim();

    if (_plateType.hasRightLabel || _plateType.isEu ||
        _plateType.isLibya || _plateType.isAlgeria || _plateType.isOther) {
      return left.isEmpty ? '' : '$left ${_plateType.displayLabel}';
    }

    if (left.isEmpty && right.isEmpty) return '';
    if (left.isEmpty) return '${_plateType.displayLabel} $right';
    if (right.isEmpty) return '$left ${_plateType.displayLabel}';
    return '$left ${_plateType.displayLabel} $right';
  }

  bool get _isPlateValid {
    final left = _leftController.text.trim();
    final right = _rightController.text.trim();

    if (_plateType.hasRightLabel || _plateType.isEu ||
        _plateType.isLibya || _plateType.isAlgeria || _plateType.isOther) {
      return left.isNotEmpty;
    }
    return left.isNotEmpty && right.isNotEmpty;
  }

  bool get _usesSingleField {
    return _plateType.hasRightLabel || _plateType.isEu ||
           _plateType.isLibya || _plateType.isAlgeria || _plateType.isOther;
  }

  Future<void> _submitTicket(models.TicketReason reason) async {
    if (!_isPlateValid) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter license plate first'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 1),
        ),
      );
      _leftFocus.requestFocus();
      return;
    }

    if (_position == null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waiting for GPS...'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final ticket = await ticketRepository.createTicket(
        licensePlate: _plateFormatted,
        position: _position!,
        reason: reason,
        fineAmount: _fines[reason] ?? 50.0,
      );

      if (!mounted) return;

      HapticFeedback.heavyImpact();

      // Show success and pop
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Ticket ${ticket.ticketNumber} created'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop(true);
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
          content: Text('Failed. Try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quick Ticket'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // GPS indicator
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              _position != null ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: _position != null ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Plate input section
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.surface,
              child: Column(
                children: [
                  // Quick plate type selector
                  _buildPlateTypeRow(),
                  const SizedBox(height: 12),
                  // Plate input
                  _buildPlateInput(),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Violation reason buttons - Main action area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'SELECT VIOLATION',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _buildReasonButtons(),
                    ),
                  ],
                ),
              ),
            ),

            // Detailed ticket option
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(
                      AppRoutes.createTicket,
                      arguments: _plateFormatted,
                    );
                  },
                  child: Text(
                    'Need more options? Use detailed form',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlateTypeRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildTypeChip(PlateType.tunis),
          _buildTypeChip(PlateType.rs),
          _buildTypeChip(PlateType.government),
          _buildTypeChip(PlateType.libya),
          _buildTypeChip(PlateType.algeria),
          _buildTypeChip(PlateType.eu),
          _buildTypeChip(PlateType.other),
        ],
      ),
    );
  }

  Widget _buildTypeChip(PlateType type) {
    final isSelected = type == _plateType;
    final style = PlateStyle.forCategory(type.category);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _plateType = type;
            // Clear inputs on type change
            _leftController.clear();
            _rightController.clear();
          });
          _leftFocus.requestFocus();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? style.backgroundColor : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? style.borderColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            type.latinLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? style.textColor : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlateInput() {
    final style = PlateStyle.forCategory(_plateType.category);

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: style.borderColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left field
          Expanded(
            flex: _usesSingleField ? 1 : 3,
            child: _buildNumberField(
              controller: _leftController,
              focusNode: _leftFocus,
              style: style,
              onSubmitted: _usesSingleField ? null : () => _rightFocus.requestFocus(),
              isAlphanumeric: _plateType.usesAlphanumeric,
            ),
          ),

          // Center label (for two-field types)
          if (!_usesSingleField) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _plateType.isGovernment
                  ? Container(
                      width: 16,
                      height: 4,
                      decoration: BoxDecoration(
                        color: style.accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  : Text(
                      _plateType.displayLabel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: style.accentColor,
                      ),
                    ),
            ),

            // Right field
            Expanded(
              flex: 4,
              child: _buildNumberField(
                controller: _rightController,
                focusNode: _rightFocus,
                style: style,
              ),
            ),
          ] else ...[
            // Label for single-field types
            if (_plateType.hasRightLabel || _plateType.isLibya)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  _plateType.displayLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: style.textColor,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required PlateStyle style,
    VoidCallback? onSubmitted,
    bool isAlphanumeric = false,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textAlign: TextAlign.center,
      keyboardType: isAlphanumeric ? TextInputType.text : TextInputType.number,
      textCapitalization: TextCapitalization.characters,
      cursorColor: style.textColor,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: style.textColor,
        letterSpacing: 3,
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        hintText: isAlphanumeric ? 'ABC-123' : '000',
        hintStyle: TextStyle(
          color: style.textColor.withValues(alpha: 0.3),
          fontSize: 24,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
          fontFamily: 'monospace',
        ),
        filled: true,
        fillColor: style.backgroundColor,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      ),
      inputFormatters: [
        if (isAlphanumeric)
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]'))
        else
          FilteringTextInputFormatter.digitsOnly,
        UpperCaseTextFormatter(),
      ],
      onSubmitted: (_) => onSubmitted?.call(),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildReasonButtons() {
    if (_isSubmitting) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 16),
            Text('Creating ticket...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildReasonButton(
                  reason: models.TicketReason.noSession,
                  icon: Icons.cancel_outlined,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReasonButton(
                  reason: models.TicketReason.expiredSession,
                  icon: Icons.timer_off_outlined,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _buildReasonButton(
                  reason: models.TicketReason.overstayed,
                  icon: Icons.access_time,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReasonButton(
                  reason: models.TicketReason.wrongZone,
                  icon: Icons.wrong_location_outlined,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReasonButton({
    required models.TicketReason reason,
    required IconData icon,
    required Color color,
  }) {
    final fine = _fines[reason] ?? 50.0;

    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _submitTicket(reason),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                reason.label,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '\$${fine.toStringAsFixed(0)}',
                style: AppTextStyles.h3.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

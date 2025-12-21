import 'package:flutter/material.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';

/// CheckResultCard widget
/// Displays the result of a vehicle check
class CheckResultCard extends StatelessWidget {
  final VehicleCheckResult result;
  final VoidCallback? onCreateTicket;

  const CheckResultCard({
    super.key,
    required this.result,
    this.onCreateTicket,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _statusIcon,
                    color: _statusColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LicensePlateDisplay.fromString(
                        result.licensePlate,
                        scale: 0.85,
                      ),
                      const SizedBox(height: 8),
                      StatusBadge(
                        text: result.statusText,
                        type: _badgeType,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Message
            Text(
              result.message,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),

            // Session details if available
            if (result.activeSession != null) ...[
              if (result.activeSession!.zoneName.isNotEmpty)
                _buildDetailRow('Zone', result.activeSession!.zoneName),
              _buildDetailRow(
                result.isValid ? 'Expires at' : 'Expired at',
                _formatDateTime(result.activeSession!.endTime),
              ),
              if (result.remainingTime != null)
                _buildDetailRow('Remaining', result.remainingTime!),
              _buildDetailRow(
                'Amount',
                '${result.activeSession!.amount.toStringAsFixed(2)} TND',
              ),
            ],

            _buildDetailRow(
              'Checked at',
              _formatTime(result.checkedAt),
            ),

            // Create ticket button (only for issues)
            if (result.hasIssue && onCreateTicket != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCreateTicket,
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Create Ticket'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  IconData get _statusIcon {
    switch (result.status) {
      case VehicleStatus.valid:
        return Icons.check_circle;
      case VehicleStatus.expired:
        return Icons.timer_off;
      case VehicleStatus.notFound:
        return Icons.help_outline;
      case VehicleStatus.hasTickets:
        return Icons.warning;
    }
  }

  Color get _statusColor {
    switch (result.status) {
      case VehicleStatus.valid:
        return AppColors.success;
      case VehicleStatus.expired:
        return AppColors.warning;
      case VehicleStatus.notFound:
        return AppColors.secondary;
      case VehicleStatus.hasTickets:
        return AppColors.error;
    }
  }

  StatusBadgeType get _badgeType {
    switch (result.status) {
      case VehicleStatus.valid:
        return StatusBadgeType.success;
      case VehicleStatus.expired:
        return StatusBadgeType.warning;
      case VehicleStatus.notFound:
        return StatusBadgeType.neutral;
      case VehicleStatus.hasTickets:
        return StatusBadgeType.error;
    }
  }
}

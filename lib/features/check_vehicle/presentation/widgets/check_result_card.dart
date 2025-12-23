import 'package:flutter/material.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';

/// CheckResultCard widget
/// Displays the result of a vehicle check
class CheckResultCard extends StatelessWidget {
  final VehicleCheckResult result;

  const CheckResultCard({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Status icon
          Icon(
            _statusIcon,
            color: _statusColor,
            size: 48,
          ),
          const SizedBox(width: 16),
          // Status info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  result.statusText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.message,
                  style: const TextStyle(fontSize: 14),
                ),
                // Show time info if session exists
                if (result.activeSession != null && !result.isValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Expired: ${_formatDateTime(result.activeSession!.endTime)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Check time
          Text(
            _formatTime(result.checkedAt),
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
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
}

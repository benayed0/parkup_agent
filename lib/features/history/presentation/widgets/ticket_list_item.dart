import 'package:flutter/material.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';

/// TicketListItem widget
/// Displays a single ticket in the history list
class TicketListItem extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onTap;
  final VoidCallback? onGoToLocation;
  final VoidCallback? onPrint;

  const TicketListItem({
    super.key,
    required this.ticket,
    this.onTap,
    this.onGoToLocation,
    this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon with status color
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: _getStatusColor(),
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // License plate and time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LicensePlateDisplay.fromString(
                          ticket.licensePlate,
                          scale: 0.7,
                          mini: true,
                        ),
                        Text(
                          _formatDateTime(ticket.issuedAt),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Reason and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ticket.reasonLabel,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ticket.statusLabel,
                            style: AppTextStyles.caption.copyWith(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Fine amount and ticket number
                    Row(
                      children: [
                        Text(
                          '${ticket.fineAmount.toStringAsFixed(2)} TND',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          ticket.ticketNumber,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onGoToLocation,
                            icon: const Icon(Icons.location_on, size: 18),
                            label: const Text('Go to Location'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onPrint,
                            icon: const Icon(Icons.print, size: 18),
                            label: const Text('Print'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
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

  // Convenience method to get location coordinates
  (double lat, double lng) get coordinates =>
      (ticket.position.latitude, ticket.position.longitude);

  Color _getStatusColor() {
    switch (ticket.status) {
      case TicketStatus.pending:
        return AppColors.warning;
      case TicketStatus.paid:
        return AppColors.success;
      case TicketStatus.removed:
        return AppColors.primary;
      case TicketStatus.appealed:
        return AppColors.info;
      case TicketStatus.dismissed:
        return AppColors.secondary;
      case TicketStatus.overdue:
        return AppColors.error;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      return '$day/$month';
    }
  }
}

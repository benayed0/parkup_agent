import 'package:flutter/material.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';

/// TicketDetailSheet widget
/// Bottom sheet showing full ticket details
class TicketDetailSheet extends StatelessWidget {
  final Ticket ticket;

  const TicketDetailSheet({
    super.key,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: _getStatusColor(),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LicensePlateDisplay.fromString(
                      ticket.licensePlate,
                      scale: 0.9,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ticket.ticketNumber,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Status badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _getStatusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticket.statusLabel,
                style: AppTextStyles.label.copyWith(
                  color: _getStatusColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Details
          _buildDetailRow('Violation Reason', ticket.reasonLabel),
          _buildDetailRow('Fine Amount', '${ticket.fineAmount.toStringAsFixed(2)} TND'),
          _buildDetailRow('Date', _formatDate(ticket.issuedAt)),
          _buildDetailRow('Time', _formatTime(ticket.issuedAt)),
          _buildDetailRow('Due Date', _formatDate(ticket.dueDate)),

          if (ticket.address != null)
            _buildDetailRow('Address', ticket.address!),

          // Location coordinates
          _buildDetailRow(
            'Location',
            '${ticket.position.latitude.toStringAsFixed(5)}, ${ticket.position.longitude.toStringAsFixed(5)}',
          ),

          if (ticket.paidAt != null)
            _buildDetailRow('Paid At', _formatDate(ticket.paidAt!)),

          if (ticket.appealReason != null) ...[
            const SizedBox(height: 16),
            Text('Appeal Reason', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticket.appealReason!,
                style: AppTextStyles.body,
              ),
            ),
          ],

          if (ticket.notes != null) ...[
            const SizedBox(height: 16),
            Text('Notes', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ticket.notes!,
                style: AppTextStyles.body,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Close button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (ticket.status) {
      case TicketStatus.pending:
        return AppColors.warning;
      case TicketStatus.paid:
        return AppColors.success;
      case TicketStatus.appealed:
        return AppColors.info;
      case TicketStatus.dismissed:
        return AppColors.secondary;
      case TicketStatus.overdue:
        return AppColors.error;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$day/$month/$year';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

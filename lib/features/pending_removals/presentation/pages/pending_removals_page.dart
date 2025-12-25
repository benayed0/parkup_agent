import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';
import '../../../create_ticket/data/repositories/ticket_repository.dart';
import '../../../history/data/repositories/history_repository.dart';

/// Pending Removals page
/// Displays paid car_sabot tickets that need physical removal
class PendingRemovalsPage extends StatefulWidget {
  const PendingRemovalsPage({super.key});

  @override
  State<PendingRemovalsPage> createState() => _PendingRemovalsPageState();
}

class _PendingRemovalsPageState extends State<PendingRemovalsPage> {
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPendingRemovals();
  }

  Future<void> _loadPendingRemovals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allTickets = await historyRepository.getTickets();

      // Filter: only car_sabot tickets that are paid
      final pendingRemovals = allTickets
          .where((t) =>
              t.reason == TicketReason.carSabot && t.status == TicketStatus.paid)
          .toList();

      // Sort by paid date (most recent first)
      pendingRemovals.sort((a, b) {
        final aPaid = a.paidAt ?? a.issuedAt;
        final bPaid = b.paidAt ?? b.issuedAt;
        return bPaid.compareTo(aPaid);
      });

      if (!mounted) return;

      setState(() {
        _tickets = pendingRemovals;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load pending removals';
        _isLoading = false;
      });
    }
  }

  Future<void> _openInMaps(Ticket ticket) async {
    final lat = ticket.position.latitude;
    final lng = ticket.position.longitude;
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _markAsRemoved(Ticket ticket) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Removal'),
        content: Text(
          'Mark sabot for ${ticket.licensePlate} as removed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ticketRepository.markAsRemoved(ticket.id);

      if (!mounted) return;

      // Remove from list
      setState(() {
        _tickets.removeWhere((t) => t.id == ticket.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sabot marked as removed'),
          backgroundColor: AppColors.success,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Removals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadPendingRemovals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _tickets.isEmpty
                  ? _buildEmptyState()
                  : _buildList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text('Error', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadPendingRemovals,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.success.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text('All clear!', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'No sabots pending removal',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadPendingRemovals,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tickets.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${_tickets.length} sabot${_tickets.length == 1 ? '' : 's'} to remove',
                style: AppTextStyles.bodySmall,
              ),
            );
          }

          final ticket = _tickets[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RemovalCard(
              ticket: ticket,
              onNavigate: () => _openInMaps(ticket),
              onMarkRemoved: () => _markAsRemoved(ticket),
            ),
          );
        },
      ),
    );
  }
}

class _RemovalCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onNavigate;
  final VoidCallback onMarkRemoved;

  const _RemovalCard({
    required this.ticket,
    required this.onNavigate,
    required this.onMarkRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: License plate and paid time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LicensePlateDisplay.fromString(
                  ticket.licensePlate,
                  scale: 0.8,
                  mini: true,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PAID',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Location info
            if (ticket.address != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ticket.address!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Paid time
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Paid ${_formatPaidTime(ticket.paidAt ?? ticket.issuedAt)}',
                  style: AppTextStyles.caption,
                ),
                const Spacer(),
                Text(
                  ticket.ticketNumber,
                  style: AppTextStyles.caption,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                // Navigate button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNavigate,
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Navigate'),
                  ),
                ),
                const SizedBox(width: 12),
                // Mark as removed button
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onMarkRemoved,
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Removed'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatPaidTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      return '$day/$month';
    }
  }
}

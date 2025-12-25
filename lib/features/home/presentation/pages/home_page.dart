import 'package:flutter/material.dart';
import '../../../../core/core.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../history/data/repositories/history_repository.dart';

/// Home page
/// Central hub with main navigation actions
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pendingRemovalsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingRemovalsCount();
  }

  Future<void> _loadPendingRemovalsCount() async {
    try {
      final tickets = await historyRepository.getTickets();
      final count = tickets
          .where((t) =>
              t.reason == TicketReason.carSabot &&
              t.status == TicketStatus.paid)
          .length;

      if (mounted) {
        setState(() => _pendingRemovalsCount = count);
      }
    } catch (_) {
      // Silently fail - badge just won't show
    }
  }

  @override
  Widget build(BuildContext context) {
    final agent = authRepository.currentAgent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ParkUp Agent'),
        automaticallyImplyLeading: false,
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message with agent name
              Text(
                'Welcome, ${agent?.name ?? 'Agent'}',
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: 4),
              Text(
                'What would you like to do?',
                style: AppTextStyles.bodySmall,
              ),

              const SizedBox(height: 24),

              // Action cards
              Expanded(
                child: Column(
                  children: [
                    // Check vehicle action
                    ActionCard(
                      icon: Icons.search,
                      title: 'Check Vehicle',
                      subtitle: 'Check status & create tickets',
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      iconColor: AppColors.primary,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.checkVehicle,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Pending removals action
                    ActionCard(
                      icon: Icons.build_circle,
                      title: 'Remove Sabots',
                      subtitle: 'Paid sabots to remove',
                      backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                      iconColor: AppColors.warning,
                      badgeCount: _pendingRemovalsCount,
                      onTap: () async {
                        await Navigator.of(context).pushNamed(
                          AppRoutes.pendingRemovals,
                        );
                        // Refresh count when returning
                        _loadPendingRemovalsCount();
                      },
                    ),

                    const SizedBox(height: 12),

                    // History action
                    ActionCard(
                      icon: Icons.history,
                      title: 'History',
                      subtitle: 'View past tickets',
                      backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                      iconColor: AppColors.secondary,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.history,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Agent info bar at bottom
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: agent?.isActive == true
                            ? AppColors.success
                            : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      agent?.isActive == true ? 'Active' : 'Inactive',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '@${agent?.username ?? 'N/A'}',
                      style: AppTextStyles.caption,
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

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();

              // Clear auth data
              await authRepository.logout();

              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

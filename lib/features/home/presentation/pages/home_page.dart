import 'package:flutter/material.dart';
import '../../../../core/core.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/data/repositories/auth_repository.dart';

/// Home page
/// Central hub with main navigation actions
class HomePage extends StatelessWidget {
  const HomePage({super.key});

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

              const SizedBox(height: 32),

              // Action cards
              Expanded(
                child: Column(
                  children: [
                    // Check vehicle action
                    ActionCard(
                      icon: Icons.search,
                      title: 'Check Vehicle',
                      subtitle: 'Verify parking status',
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      iconColor: AppColors.primary,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.checkVehicle,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Create ticket action
                    ActionCard(
                      icon: Icons.receipt_long,
                      title: 'Create Ticket',
                      subtitle: 'Issue a new parking ticket',
                      backgroundColor: AppColors.warning.withValues(alpha: 0.1),
                      iconColor: AppColors.warning,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.createTicket,
                      ),
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
                      'Badge: ${agent?.agentCode ?? 'N/A'}',
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

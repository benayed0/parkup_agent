import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
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
    printerService.addListener(_onPrinterChanged);
  }

  @override
  void dispose() {
    printerService.removeListener(_onPrinterChanged);
    super.dispose();
  }

  void _onPrinterChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadPendingRemovalsCount() async {
    try {
      final tickets = await historyRepository.getTickets();
      final count = tickets
          .where(
            (t) =>
                t.reason == TicketReason.carSabot &&
                t.status == TicketStatus.paid,
          )
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset('assets/icons/parkup-logo.png', height: 32),
            ),
            const SizedBox(width: 10),
            Text(l10n.appName),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          // Printer status indicator
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.print),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: printerService.isConnected
                          ? AppColors.success
                          : AppColors.textSecondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            tooltip: printerService.isConnected
                ? l10n.printerConnected
                : l10n.noPrinterConnected,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.printerScan),
          ),
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
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
                l10n.welcomeUser(agent?.name ?? 'Agent'),
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: 4),
              Text(l10n.whatWouldYouLikeToDo, style: AppTextStyles.bodySmall),

              const SizedBox(height: 24),

              // Action cards - scrollable for smaller screens
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Check vehicle action
                      ActionCard(
                        icon: Icons.search,
                        title: l10n.checkVehicle,
                        subtitle: l10n.checkStatusCreateTickets,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        iconColor: AppColors.primary,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.checkVehicle),
                      ),

                      const SizedBox(height: 12),

                      // Pending removals action
                      ActionCard(
                        icon: Icons.build_circle,
                        title: l10n.removeSabots,
                        subtitle: l10n.paidSabotsToRemove,
                        backgroundColor: AppColors.warning.withValues(
                          alpha: 0.1,
                        ),
                        iconColor: AppColors.warning,
                        badgeCount: _pendingRemovalsCount,
                        onTap: () async {
                          await Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.pendingRemovals);
                          // Refresh count when returning
                          _loadPendingRemovalsCount();
                        },
                      ),

                      const SizedBox(height: 12),

                      // Active sessions map action
                      ActionCard(
                        icon: Icons.map,
                        title: 'Sessions Map',
                        subtitle: 'View active sessions on map',
                        backgroundColor: AppColors.success.withValues(
                          alpha: 0.1,
                        ),
                        iconColor: AppColors.success,
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.activeSessionsMap),
                      ),

                      const SizedBox(height: 12),

                      // History action
                      ActionCard(
                        icon: Icons.history,
                        title: l10n.history,
                        subtitle: l10n.viewPastTickets,
                        backgroundColor: AppColors.secondary.withValues(
                          alpha: 0.1,
                        ),
                        iconColor: AppColors.secondary,
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.history),
                      ),
                    ],
                  ),
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
                      agent?.isActive == true ? l10n.active : l10n.inactive,
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
}

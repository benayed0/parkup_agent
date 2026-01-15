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
              child: Image.asset(
                'assets/icons/parkup-logo.png',
                height: 32,
              ),
            ),
            const SizedBox(width: 10),
            Text(l10n.appName),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          // Language selector button
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: l10n.language,
            onPressed: () => _showLanguageDialog(context),
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.logout,
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
                l10n.welcomeUser(agent?.name ?? 'Agent'),
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.whatWouldYouLikeToDo,
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
                      title: l10n.checkVehicle,
                      subtitle: l10n.checkStatusCreateTickets,
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
                      title: l10n.removeSabots,
                      subtitle: l10n.paidSabotsToRemove,
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

                    // Active sessions map action
                    ActionCard(
                      icon: Icons.map,
                      title: l10n.sessionsMap,
                      subtitle: l10n.viewActiveSessionsOnMap,
                      backgroundColor: AppColors.success.withValues(alpha: 0.1),
                      iconColor: AppColors.success,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.activeSessionsMap,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // History action
                    ActionCard(
                      icon: Icons.history,
                      title: l10n.history,
                      subtitle: l10n.viewPastTickets,
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

  void _showLanguageDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: LocaleService.supportedLocales.map((locale) {
            final isSelected =
                localeService.currentLocale?.languageCode == locale.languageCode;
            return ListTile(
              leading: Text(
                LocaleService.getLocaleFlag(locale),
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(LocaleService.getLocaleName(locale)),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              selected: isSelected,
              onTap: () {
                localeService.setLocale(locale);
                Navigator.of(dialogContext).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
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
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
  }
}

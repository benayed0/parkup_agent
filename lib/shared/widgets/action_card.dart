import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// ActionCard widget
/// Large, tappable card for main actions on home screen
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: backgroundColor ?? AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: iconColor ?? AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h3,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow indicator
              const Icon(
                Icons.chevron_right,
                color: AppColors.secondary,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

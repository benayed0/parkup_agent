import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

/// StatusBadge widget
/// Displays a colored badge indicating status
class StatusBadge extends StatelessWidget {
  final String text;
  final StatusBadgeType type;

  const StatusBadge({
    super.key,
    required this.text,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: _textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color get _backgroundColor {
    switch (type) {
      case StatusBadgeType.success:
        return AppColors.success.withValues(alpha: 0.15);
      case StatusBadgeType.warning:
        return AppColors.warning.withValues(alpha: 0.15);
      case StatusBadgeType.error:
        return AppColors.error.withValues(alpha: 0.15);
      case StatusBadgeType.neutral:
        return AppColors.secondary.withValues(alpha: 0.15);
    }
  }

  Color get _textColor {
    switch (type) {
      case StatusBadgeType.success:
        return AppColors.successDark;
      case StatusBadgeType.warning:
        return AppColors.warning;
      case StatusBadgeType.error:
        return AppColors.error;
      case StatusBadgeType.neutral:
        return AppColors.secondary;
    }
  }
}

enum StatusBadgeType {
  success,
  warning,
  error,
  neutral,
}

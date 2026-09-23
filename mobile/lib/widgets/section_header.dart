import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(title, style: AppTextStyles.titleLarge),
          ),
          if (trailing != null) trailing!,
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_left_rounded,
                      size: 18, color: AppColors.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

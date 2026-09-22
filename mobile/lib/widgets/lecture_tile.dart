import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_text_styles.dart';

class LectureTile extends StatelessWidget {
  final int index;
  final String title;
  final String type;
  final bool isPublished;
  final VoidCallback? onTap;
  final Widget? trailing;

  const LectureTile({
    super.key,
    required this.index,
    required this.title,
    required this.type,
    this.isPublished = true,
    this.onTap,
    this.trailing,
  });

  String get _typeIcon {
    switch (type) {
      case 'VIDEO': return '🎬';
      case 'PDF': return '📄';
      case 'TEXT': return '📝';
      default: return '📎';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(_typeIcon, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(type, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (!isPublished)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('غير منشورة', style: TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
              ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

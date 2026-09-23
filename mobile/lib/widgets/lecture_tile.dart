import 'package:flutter/material.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_shadows.dart';
import '../app/theme/app_text_styles.dart';

class LectureTile extends StatelessWidget {
  final int index;
  final String title;
  final String type;
  final bool isPublished;
  final bool isNew;
  final VoidCallback? onTap;
  final Widget? trailing;

  const LectureTile({
    super.key,
    required this.index,
    required this.title,
    required this.type,
    this.isPublished = true,
    this.isNew = false,
    this.onTap,
    this.trailing,
  });

  (IconData, Color) get _typeStyle {
    switch (type) {
      case 'VIDEO':
        return (Icons.play_circle_fill_rounded, const Color(0xFFE53935));
      case 'PDF':
        return (Icons.picture_as_pdf_rounded, const Color(0xFFEF6C00));
      case 'TEXT':
        return (Icons.article_rounded, const Color(0xFF1565C0));
      default:
        return (Icons.attach_file_rounded, AppColors.primary);
    }
  }

  String get _typeLabel {
    switch (type) {
      case 'VIDEO':
        return 'فيديو';
      case 'PDF':
        return 'ملف PDF';
      case 'TEXT':
        return 'نص';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final (typeIcon, typeColor) = _typeStyle;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text('$index',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(typeIcon, color: typeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(_typeLabel, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (isNew)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('جديد',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            if (!isPublished)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('غير منشورة',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600)),
              ),
            const Icon(Icons.chevron_left_rounded,
                size: 22, color: AppColors.textHint),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

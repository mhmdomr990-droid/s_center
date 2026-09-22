import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_text_styles.dart';

class CourseCard extends StatelessWidget {
  final String name;
  final String? teacherName;
  final String price;
  final String specialization;
  final int year;
  final int? lecturesCount;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CourseCard({
    super.key,
    required this.name,
    this.teacherName,
    required this.price,
    this.specialization = '',
    this.year = 0,
    this.lecturesCount,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (teacherName != null) ...[
                        Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(teacherName!, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(width: 8),
                      ],
                      Icon(Icons.book_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text('$specialization - السنة $year', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$price SYP', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
                if (lecturesCount != null)
                  Text('$lecturesCount محاضرة', style: AppTextStyles.caption),
              ],
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

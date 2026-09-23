import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_shadows.dart';
import '../app/theme/app_text_styles.dart';
import '../utils/format.dart';

class CourseCard extends StatelessWidget {
  final int? courseId;
  final String name;
  final String? teacherName;
  final String price;
  final String specialization;
  final int specializationId;
  final int year;
  final int? lecturesCount;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CourseCard({
    super.key,
    this.courseId,
    required this.name,
    this.teacherName,
    required this.price,
    this.specialization = '',
    this.specializationId = 0,
    this.year = 0,
    this.lecturesCount,
    this.onTap,
    this.trailing,
  });

  Color get _accent => AppColors.specializationColor(specializationId);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.courseCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: 'course-icon-${courseId ?? name}',
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.school_rounded,
                              color: _accent, size: 26),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: 'course-title-${courseId ?? name}',
                              child: Material(
                                type: MaterialType.transparency,
                                child: Text(name,
                                    style: AppTextStyles.titleMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ),
                            if (teacherName != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_outline_rounded,
                                      size: 14,
                                      color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(teacherName!,
                                        style: AppTextStyles.caption,
                                        softWrap: true),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Hero(
                              tag: 'course-price-${courseId ?? name}',
                              child: Material(
                                type: MaterialType.transparency,
                                child: Text(formatAmount(price),
                                    style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ),
                            Text('SYP',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600)),
                            if (lecturesCount != null)
                              Text('$lecturesCount محاضرة',
                                  style: AppTextStyles.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing!,
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.book_outlined, size: 14, color: _accent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('$specialization - السنة $year',
                            style: AppTextStyles.caption,
                            softWrap: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme/app_colors.dart';
import '../app/version.dart';

/// نافذة «عن التطبيق»: اسم التطبيق + الإصدار + المطورون.
/// الإصدار يقرأ من `appVersion` (يُزامَن مع build.gradle.kts عند كل تسليم).
Future<void> showAboutAppDialog() async {
  if (Get.context == null) return;

  await Get.dialog<void>(
    AlertDialog(
      backgroundColor: AppColors.courseCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Text(
            'NCS',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإصدار $appVersion',
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'المطورون',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _developerRow('Fadi Debow'),
          const SizedBox(height: 6),
          _developerRow('Mohammad Omar'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back<void>(),
          child: Text(
            'إغلاق',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _developerRow(String name) {
  return Row(
    children: [
      const Icon(Icons.code_rounded, size: 16, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(
        name,
        style: GoogleFonts.cairo(
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
    ],
  );
}

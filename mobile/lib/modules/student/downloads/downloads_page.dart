import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/lecture_model.dart';
import '../../../data/services/download_manager.dart';
import '../../../utils/format.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/gradient_app_bar.dart';
import '../../../widgets/loading_shimmer.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  static String _sizeLabel(int? bytes) {
    if (bytes == null || bytes <= 0) return '—';
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  void _open(DownloadRecord rec) {
    if (rec.isExpired) return;
    final model = LectureModel(
      id: rec.lectureId,
      courseId: 0,
      title: rec.title ?? 'محاضرة #${rec.lectureId}',
      type: rec.lectureType ?? 'VIDEO',
      isPublished: true,
      sortOrder: 0,
    );
    Get.toNamed(AppRoutes.lectureView, arguments: {
      'lecture': model,
      'lectures': [model],
      'currentIndex': 0,
    });
  }

  Future<void> _confirmDelete(
      BuildContext context, DownloadManager dm, DownloadRecord rec) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف التنزيل'),
        content: Text(
            'هل تريد حذف "${rec.title ?? 'محاضرة #${rec.lectureId}'}" من الجهاز؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await dm.removeDownload(rec.lectureId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dm = Get.find<DownloadManager>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GradientAppBar(title: 'تنزيلاتي'),
      body: Obx(() {
        if (!dm.ready.value) return const LoadingListShimmer();
        final recs = dm.records.values.toList()
          ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
        if (recs.isEmpty) {
          return const EmptyState(
            icon: Icons.download_rounded,
            title: 'لا توجد ملفات محمّلة',
            subtitle: 'حمّل الفيديو وملفات PDF من صفحات المحاضرات لمشاهدتها بدون اتصال',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: recs.length,
          itemBuilder: (context, index) {
            final rec = recs[index];
            final isPdf = rec.lectureType == 'PDF';
            final daysLeft = rec.expiresAt.difference(DateTime.now()).inDays;
            final expiringSoon = daysLeft <= 7;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.courseCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: ListTile(
                onTap: () => _open(rec),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isPdf ? AppColors.error : AppColors.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPdf ? Icons.picture_as_pdf : Icons.play_circle_outline,
                    color: isPdf ? AppColors.error : AppColors.primary,
                    size: 24,
                  ),
                ),
                title: Text(
                  rec.title ?? 'محاضرة #${rec.lectureId}',
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (rec.courseName != null && rec.courseName!.isNotEmpty)
                      Text(rec.courseName!,
                          style: AppTextStyles.caption, maxLines: 1),
                    const SizedBox(height: 2),
                    Text(
                      '${_sizeLabel(rec.sizeBytes)} • حُفظ ${formatArabicDate(rec.downloadedAt)} • '
                      '${expiringSoon ? 'ينتهي خلال $daysLeft يوماً' : 'الصلاحية حتى ${formatArabicDate(rec.expiresAt)}'}',
                      style: AppTextStyles.caption.copyWith(
                        color: expiringSoon ? AppColors.warning : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: IconButton(
                  tooltip: 'حذف من الجهاز',
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 22),
                  onPressed: () => _confirmDelete(context, dm, rec),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

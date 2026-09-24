import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/theme/app_colors.dart';
import '../data/services/download_manager.dart';

class DownloadLectureButton extends StatefulWidget {
  final int lectureId;
  final bool enabled;

  const DownloadLectureButton({
    super.key,
    required this.lectureId,
    this.enabled = true,
  });

  @override
  State<DownloadLectureButton> createState() => _DownloadLectureButtonState();
}

class _DownloadLectureButtonState extends State<DownloadLectureButton> {
  bool _busy = false;

  DownloadManager get _dm => Get.find<DownloadManager>();

  Future<void> _onTap() async {
    if (!widget.enabled || _busy || kIsWeb) return;
    if (_dm.downloadingIds.contains(widget.lectureId)) return;

    if (_dm.isDownloaded(widget.lectureId)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('حذف التنزيل'),
          content: const Text('هل تريد حذف النسخة المحفوظة على الجهاز؟'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('حذف', style: TextStyle(color: AppColors.error))),
          ],
        ),
      );
      if (confirmed == true) {
        await _dm.removeDownload(widget.lectureId);
        if (mounted) setState(() {});
      }
      return;
    }

    setState(() => _busy = true);
    try {
      await _dm.downloadLecture(widget.lectureId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ المحاضرة — متاحة بدون اتصال لمدة 90 يوماً'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل التحميل: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetX<DownloadManager>(
      builder: (dm) {
        final downloading = dm.downloadingIds.contains(widget.lectureId);
        final p = dm.progress[widget.lectureId];
        final downloaded = dm.isDownloaded(widget.lectureId);

        if (downloading) {
          return SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    value: p,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                if (p != null && p < 1)
                  Text(
                    '${(p * 100).toInt()}',
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
              ],
            ),
          );
        }

        return IconButton(
          onPressed: widget.enabled && !kIsWeb ? _onTap : null,
          tooltip: kIsWeb
              ? 'التحميل متاح على تطبيق أندرويد'
              : downloaded
                  ? 'محفوظة — اضغط للحذف'
                  : 'تحميل للمشاهدة دون اتصال',
          icon: downloaded
              ? const Icon(Icons.download_done, color: AppColors.success, size: 26)
              : Icon(
                  Icons.download_rounded,
                  color: widget.enabled && !kIsWeb
                      ? AppColors.primary
                      : AppColors.textHint,
                  size: 26,
                ),
        );
      },
    );
  }
}

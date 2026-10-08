import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/upload_manager.dart';

/// شريط تقدم عائم يبقى مرئياً بعد الخروج من صفحة الإضافة
/// (يُخفي نفسه تلقائياً عندما تكون صفحة الإضافة مفتوحة —
/// لأنها تعرض تقدمها بنفسها)
class UploadOverlay extends StatelessWidget {
  const UploadOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final um = Get.find<UploadManager>();
    final textPrimary = Theme.of(context).textTheme.bodyMedium?.color;
    return Obx(() {
      final phase = um.phase.value;
      final active = !um.overlaySuppressed.value &&
          (phase == UploadPhase.compressing ||
              phase == UploadPhase.uploading);
      if (!active) return const SizedBox.shrink();

      final isCompress = phase == UploadPhase.compressing;
      final pctValue =
          isCompress ? um.compressProgress.value : um.progress.value;
      final value = pctValue > 0 ? pctValue : null;
      final eta = um.compressEta.value;
      final title = isCompress ? 'جارٍ ضغط الفيديو…' : 'جارٍ رفع المحاضرة…';

      return Positioned(
        left: 16,
        right: 16,
        bottom: 24,
        child: Material(
          color: Theme.of(context).cardColor,
          elevation: 8,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isCompress ? Icons.compress : Icons.cloud_upload,
                  color: const Color(0xFF43A047),
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$title ${um.taskTitle.value}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 5,
                          color: const Color(0xFF43A047),
                          backgroundColor:
                              Theme.of(context).dividerColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isCompress
                      ? (eta > 0
                          ? 'متبقٍ ${eta >= 60 ? '${(eta / 60).round()} د' : '$eta ث'}'
                          : '…')
                      : '${(pctValue * 100).floor()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

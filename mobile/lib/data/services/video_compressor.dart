import 'dart:io';

import 'package:video_compress/video_compress.dart';

class VideoCompressor {
  VideoCompressor._();

  static const int skipBelowBytes = 50 * 1024 * 1024;

  static Future<String?> compressForUpload(
    String path, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final origin = File(path);
      if (!await origin.exists()) return null;
      final originalSize = await origin.length();
      if (originalSize < skipBelowBytes) return null;

      await deleteCache();

      final sub = VideoCompress.compressProgress$.subscribe((event) {
        onProgress?.call((event / 100).clamp(0.0, 1.0));
      });
      MediaInfo? info;
      try {
        info = await VideoCompress.compressVideo(
          path,
          quality: VideoQuality.Res1920x1080Quality,
        );
      } finally {
        sub.unsubscribe();
      }

      final out = info?.file;
      if (out == null || out.path == path) return null;
      if (!await out.exists()) return null;

      final compressedSize = await out.length();
      if (compressedSize <= 0 || compressedSize >= originalSize * 0.9) {
        return null;
      }
      return out.path;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteCache() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (_) {
      // التنظيف اختياري أبداً لا يعطّل الرفع
    }
  }
}

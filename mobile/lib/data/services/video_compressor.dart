import 'dart:io';
import 'dart:math';

import 'package:video_compress/video_compress.dart';

class VideoCompressor {
  VideoCompressor._();

  static const int skipBelowBytes = 50 * 1024 * 1024;

  // تخطٍّ ذكي: إن كان الفيديو منخفض الدقة/البت‑ريت فالضغط يُنتج ≈ نفس الحجم
  // (فحص قبل بدء الترميز — لا يُهدر وقت الترميز بلا فائدة)
  static Future<bool> _isAlreadyWebFriendly(String path, int fileSize) async {
    try {
      final info = await VideoCompress.getMediaInfo(path);
      final width = info.width ?? 0;
      final height = info.height ?? 0;
      final durationMs = info.duration ?? 0;
      if (width <= 0 || height <= 0 || durationMs <= 0) return false;
      final maxSide = max(width, height);
      final bitrate = fileSize * 8 / (durationMs / 1000); // bit/s
      if (maxSide <= 1280 && bitrate <= 4 * 1000000) return true;
      if (maxSide <= 1920 && bitrate <= 6 * 1000000) return true;
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> compressForUpload(
    String path, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final origin = File(path);
      if (!await origin.exists()) return null;
      final originalSize = await origin.length();
      if (originalSize < skipBelowBytes) return null;
      if (await _isAlreadyWebFriendly(path, originalSize)) return null;

      await deleteCache();

      final sub = VideoCompress.compressProgress$.subscribe((event) {
        onProgress?.call((event / 100).clamp(0.0, 1.0));
      });
      MediaInfo? info;
      try {
        info = await VideoCompress.compressVideo(
          path,
          quality: VideoQuality.Res1280x720Quality,
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

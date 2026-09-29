import 'dart:io';

import 'package:video_compress/video_compress.dart';

class VideoCompressor {
  VideoCompressor._();

  static Future<CompressOutcome> compressForUpload(
    String path, {
    void Function(double progress)? onProgress,
    void Function(int etaSeconds)? onEta,
  }) async {
    var sourceSize = 0;
    try {
      final origin = File(path);
      if (!await origin.exists()) {
        return CompressOutcome(
          reason: 'failed',
          sourceSize: 0,
          error: 'file not found',
        );
      }
      sourceSize = await origin.length();

      await deleteCache();

      final startedAt = DateTime.now();
      final sub = VideoCompress.compressProgress$.subscribe((event) {
        final p = (event / 100).clamp(0.0, 1.0);
        onProgress?.call(p);
        // ETA خطي: elapsed / نسبة × المتبقي (الترميز بسرعة ثابتة تقريباً)
        if (p > 0.02 && onEta != null) {
          final elapsed = DateTime.now().difference(startedAt);
          final remaining = elapsed * ((1.0 - p) / p);
          final sec = remaining.inSeconds;
          onEta(sec > 0 ? sec : 0);
        }
      });
      MediaInfo? info;
      try {
        info = await VideoCompress.compressVideo(
          path,
          quality: VideoQuality.Res960x540Quality,
          frameRate: 15,
        );
      } finally {
        sub.unsubscribe();
      }

      final out = info?.file;
      if (out == null || out.path == path || !await out.exists()) {
        return CompressOutcome(
          reason: 'failed',
          sourceSize: sourceSize,
          error: 'no output',
        );
      }

      final compressedSize = await out.length();
      if (compressedSize <= 0 || compressedSize >= sourceSize * 0.9) {
        return CompressOutcome(
          reason: 'noGain',
          sourceSize: sourceSize,
          outputSize: compressedSize > 0 ? compressedSize : null,
        );
      }
      return CompressOutcome(
        path: out.path,
        reason: 'compressed',
        sourceSize: sourceSize,
        outputSize: compressedSize,
      );
    } catch (e) {
      return CompressOutcome(
        reason: 'failed',
        sourceSize: sourceSize,
        error: e.toString(),
      );
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

class CompressOutcome {
  const CompressOutcome({
    this.path,
    required this.reason,
    required this.sourceSize,
    this.outputSize,
    this.error,
  });

  // compressed | noGain | failed
  final String reason;
  final String? path;
  final int sourceSize;
  final int? outputSize;
  final String? error;

  static String _mb(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';

  String get summary {
    switch (reason) {
      case 'compressed':
        return 'تم الضغط ${_mb(sourceSize)} ← ${_mb(outputSize ?? sourceSize)}';
      case 'noGain':
        return 'بدون ضغط (النتيجة لم تكن أصغر)';
      default:
        return 'تعذر الضغط — رُفع الأصلي';
    }
  }
}

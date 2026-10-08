import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';

import '../providers/api_exception.dart';
import '../providers/teacher_provider.dart';
import 'video_compressor.dart';

enum UploadPhase { idle, compressing, uploading, success, failed }

/// مهمة رفع محاضرة واحدة — تعيش خارج دورة حياة الصفحات
/// فتستمر بعد الخروج من صفحة الإضافة أو تصغير التطبيق
class UploadTask {
  const UploadTask({
    required this.courseId,
    required this.title,
    required this.type,
    required this.successMessage,
    required this.failMessage,
    this.isEdit = false,
    this.lectureId,
    this.url,
    this.content,
    this.sortOrder,
    this.videoFilePath,
    this.fileBytes,
    this.fileName,
    this.compress = true,
  });

  final bool isEdit;
  final int? lectureId;
  final int courseId;
  final String title;
  final String type;
  final String? url;
  final String? content;
  final int? sortOrder;
  final String? videoFilePath;
  final Uint8List? fileBytes;
  final String? fileName;
  final bool compress;
  final String successMessage;
  final String failMessage;
}

/// منسّق الرفع الدائم (permanent): ضغط ثم رفع ثم إشعار إنجاز.
/// مسؤول عن مهلة الخدمة أمامية (FGS) حتى يستمر الرفع في الخلفية.
class UploadManager extends GetxController {
  UploadManager(this._provider);

  final TeacherProvider _provider;

  final phase = UploadPhase.idle.obs;
  final progress = 0.0.obs;
  final compressing = false.obs;
  final compressProgress = 0.0.obs;
  final compressEta = 0.obs;
  final taskTitle = ''.obs;

  /// صفحة الإضافة تُخفي الشريط العائم ( تعرض تقدمها بنفسها )
  final overlaySuppressed = false.obs;

  static bool _permissionAsked = false;
  DateTime _lastNotifiedAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _lastNotifiedPct = -1;

  bool get isBusy =>
      phase.value == UploadPhase.compressing ||
      phase.value == UploadPhase.uploading;

  Future<bool> run(UploadTask task) async {
    if (isBusy) {
      Get.snackbar('تنبيه', 'يوجد رفع جارٍ — انتظر اكتماله',
          backgroundColor: const Color(0xFFFB8C00),
          colorText: const Color(0xFFFFFFFF));
      return false;
    }

    taskTitle.value = task.title;
    progress.value = 0;
    compressProgress.value = 0;
    compressEta.value = 0;
    _lastNotifiedPct = -1;
    _lastNotifiedAt = DateTime.fromMillisecondsSinceEpoch(0);

    final willCompress = task.compress &&
        task.videoFilePath != null &&
        task.type == 'VIDEO' &&
        !kIsWeb;
    phase.value =
        willCompress ? UploadPhase.compressing : UploadPhase.uploading;
    compressing.value = willCompress;

    await _ensureNotificationPermission();
    await _startService(
        title: willCompress ? 'جارٍ ضغط الفيديو…' : 'جارٍ الرفع…',
        text: task.title);

    try {
      var uploadPath = task.videoFilePath;
      String? compressSummary;

      if (willCompress) {
        final outcome = await VideoCompressor.compressForUpload(
          uploadPath!,
          onProgress: (p) => compressProgress.value = p,
          onEta: (s) => compressEta.value = s,
        );
        uploadPath = outcome.path ?? task.videoFilePath;
        compressSummary = outcome.summary;
        debugPrint(
            'compress: ${outcome.reason} ${outcome.sourceSize} -> ${outcome.outputSize ?? '-'} ${outcome.error ?? ''}');
      }

      phase.value = UploadPhase.uploading;
      compressing.value = false;
      compressProgress.value = 0;
      compressEta.value = 0;
      await _updateNotification('جارٍ رفع المحاضرة… 0%', task.title);

      final onSend = task.videoFilePath == null
          ? null
          : (int sent, int total) => _onSendProgress(task, sent, total);

      if (task.isEdit) {
        await _provider.updateLecture(
          task.lectureId!,
          title: task.title,
          type: task.type,
          url: task.url,
          content: task.content,
          sortOrder: task.sortOrder,
          videoFilePath: uploadPath,
          fileBytes: task.fileBytes,
          fileName: task.fileName,
          onSendProgress: onSend,
        );
      } else {
        await _provider.createLecture(
          task.courseId,
          title: task.title,
          type: task.type,
          url: task.url,
          content: task.content,
          sortOrder: task.sortOrder,
          videoFilePath: uploadPath,
          fileBytes: task.fileBytes,
          fileName: task.fileName,
          onSendProgress: onSend,
        );
      }

      phase.value = UploadPhase.success;
      progress.value = 1;
      final successText =
          '${task.successMessage}${compressSummary == null ? '' : '\n$compressSummary'}';
      Get.snackbar('نجاح', successText,
          backgroundColor: const Color(0xFF43A047),
          colorText: const Color(0xFFFFFFFF));
      unawaited(_finishService(ok: true, text: successText));
      unawaited(_resetSoon());
      return true;
    } catch (e) {
      final message = apiErrorMessage(e, fallback: task.failMessage);
      phase.value = UploadPhase.failed;
      Get.snackbar('خطأ', message,
          backgroundColor: const Color(0xFFE53935),
          colorText: const Color(0xFFFFFFFF));
      unawaited(_finishService(ok: false, text: message));
      unawaited(_resetSoon());
      return false;
    } finally {
      compressing.value = false;
      compressProgress.value = 0;
      compressEta.value = 0;
      if (task.videoFilePath != null) await VideoCompressor.deleteCache();
    }
  }

  void _onSendProgress(UploadTask task, int sent, int total) {
    if (total <= 0) return;
    final p = (sent / total).clamp(0.0, 1.0);
    progress.value = p;

    // إشعار الخدمة يتغيّر عند تغيّر النسبة وليست كل بايت (تخفيف الحمل)
    final pct = (p * 100).floor();
    if (pct == _lastNotifiedPct) return;
    final now = DateTime.now();
    if (pct < 100 &&
        now.difference(_lastNotifiedAt).inMilliseconds < 800) {
      return;
    }
    _lastNotifiedPct = pct;
    _lastNotifiedAt = now;
    unawaited(_updateNotification('جارٍ رفع المحاضرة… $pct%', task.title));
  }

  // ---------- الخدمة أمامية (استمرار الرفع في الخلفية + الإشعار) ----------

  Future<void> _ensureNotificationPermission() async {
    if (_permissionAsked) return;
    _permissionAsked = true;
    try {
      final p = await FlutterForegroundTask.checkNotificationPermission();
      if (p != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    } catch (_) {}
  }

  Future<void> _startService(
      {required String title, required String text}) async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
            notificationTitle: title, notificationText: text);
      } else {
        final r = await FlutterForegroundTask.startService(
            notificationTitle: title, notificationText: text);
        if (r is ServiceRequestFailure) {
          debugPrint('FGS start failed: ${r.error}');
        }
      }
    } catch (e) {
      debugPrint('FGS: $e');
    }
  }

  Future<void> _updateNotification(String title, String text) async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
            notificationTitle: title, notificationText: text);
      }
    } catch (_) {}
  }

  Future<void> _finishService(
      {required bool ok, required String text}) async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        final clean = text.length > 120 ? text.substring(0, 120) : text;
        await FlutterForegroundTask.updateService(
          notificationTitle: ok ? 'اكتمل رفع المحاضرة ✓' : 'فشل رفع المحاضرة ✗',
          notificationText: clean.replaceAll('\n', ' '),
        );
        await Future.delayed(const Duration(seconds: 5));
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {}
  }

  Future<void> _resetSoon() async {
    await Future.delayed(const Duration(seconds: 5));
    if (phase.value == UploadPhase.success ||
        phase.value == UploadPhase.failed) {
      phase.value = UploadPhase.idle;
      progress.value = 0;
      taskTitle.value = '';
    }
  }
}

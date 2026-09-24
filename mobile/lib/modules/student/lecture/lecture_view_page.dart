import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/lecture_model.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/providers/media_provider.dart';
import '../../../data/services/download_manager.dart';
import '../../../data/services/screen_guard.dart';
import '../../../widgets/gradient_app_bar.dart';

class LectureController extends GetxController {
  final currentIndex = 0.obs;
  late List<LectureModel> lectures;

  final isLoadingPlayer = false.obs;
  final playerError = Rxn<String>();
  final isOffline = false.obs;
  final isPlaying = false.obs;
  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;

  VideoPlayerController? videoController;
  DownloadManager get _downloads => Get.find<DownloadManager>();
  MediaProvider get _media => MediaProvider(Get.find<ApiClient>());

  int _tempPlayLectureId = -1;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>;
    lectures = args['lectures'] as List<LectureModel>;
    currentIndex.value = args['currentIndex'] as int;
    unawaited(ScreenGuard.instance.protect());
    ever<int>(currentIndex, (_) => unawaited(_loadPlayer()));
    unawaited(_loadPlayer());
  }

  @override
  void onClose() {
    unawaited(_disposePlayer());
    super.onClose();
  }

  LectureModel get currentLecture => lectures[currentIndex.value];
  bool get hasPrevious => currentIndex.value > 0;
  bool get hasNext => currentIndex.value < lectures.length - 1;

  void previousLecture() {
    if (hasPrevious) currentIndex.value--;
  }

  void nextLecture() {
    if (hasNext) currentIndex.value++;
  }

  Future<void> openPdf(String? url) async {
    if (url == null || url.isEmpty) {
      Get.snackbar('خطأ', 'رابط الملف غير متاح',
          backgroundColor: AppColors.error, colorText: Colors.white);
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _disposePlayer() async {
    final c = videoController;
    videoController = null;
    isPlaying.value = false;
    if (c != null) {
      await c.pause();
      await c.dispose();
    }
    if (_tempPlayLectureId != -1) {
      await _downloads.deleteTempPlayFile(_tempPlayLectureId);
      _tempPlayLectureId = -1;
    }
  }

  Future<void> _loadPlayer() async {
    await _disposePlayer();
    playerError.value = null;
    isOffline.value = false;

    final lecture = currentLecture;
    if (!lecture.isVideo) return;

    isLoadingPlayer.value = true;
    try {
      if (_downloads.isDownloaded(lecture.id)) {
        final file = await _downloads.decryptToTemp(lecture.id);
        _tempPlayLectureId = lecture.id;
        isOffline.value = true;
        await _initController(VideoPlayerController.file(file));
        return;
      }

      final resp = await _media.getStreamUrl(lecture.id);
      final path = resp.data['data']['url'] as String;
      final url = MediaProvider.absolute(path);
      await _initController(VideoPlayerController.networkUrl(Uri.parse(url)));
    } catch (e) {
      playerError.value = apiErrorMessage(e, fallback: 'تعذر تشغيل الفيديو');
      if (lecture.url != null && lecture.url!.isNotEmpty) {
        // Legacy external link fallback shown in UI.
      }
    } finally {
      isLoadingPlayer.value = false;
    }
  }

  Future<void> _initController(VideoPlayerController controller) async {
    videoController = controller;
    await controller.initialize();
    controller.addListener(() {
      if (videoController != controller) return;
      position.value = controller.value.position;
      duration.value = controller.value.duration;
      isPlaying.value = controller.value.isPlaying;
      if (controller.value.hasError) {
        playerError.value = 'خطأ في تشغيل الفيديو';
      }
    });
    update();
  }

  Future<void> togglePlay() async {
    final c = videoController;
    if (c == null) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
  }

  Future<void> seekTo(Duration d) async {
    await videoController?.seekTo(d);
  }

  Future<void> retry() => _loadPlayer();

  Future<void> openExternal() async {
    final lecture = currentLecture;
    if (lecture.url == null || lecture.url!.isEmpty) return;
    final uri = Uri.parse(lecture.url!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }
}

class LectureViewPage extends StatelessWidget {
  const LectureViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LectureController>(
      init: LectureController(),
      builder: (ctrl) {
        final lecture = ctrl.currentLecture;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: GradientAppBar(title: lecture.title),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.courseCard,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(lecture.type,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ),
                        if (ctrl.isOffline.value) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('بدون اتصال',
                                style: TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ),
                        ],
                        const Spacer(),
                        Text(
                            '${ctrl.currentIndex.value + 1} / ${ctrl.lectures.length}',
                            style: AppTextStyles.caption),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(lecture.title, style: AppTextStyles.headlineMedium),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (lecture.isVideo) _VideoSection(ctrl: ctrl),
              if (!lecture.isVideo && lecture.isPdf)
                GestureDetector(
                  onTap: () => ctrl.openPdf(lecture.url),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.courseCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.picture_as_pdf,
                            size: 64, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text('اضغط لفتح ملف PDF',
                            style: AppTextStyles.bodyLarge
                                .copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                )
              else if (!lecture.isVideo && lecture.isText && lecture.content != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.courseCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(lecture.content!,
                      style: AppTextStyles.bodyLarge.copyWith(height: 1.8)),
                )
              else if (!lecture.isVideo)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.courseCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.article,
                          size: 48, color: AppColors.textHint),
                      const SizedBox(height: 8),
                      Text('محتوى المحاضرة غير متاح',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: ctrl.hasPrevious ? ctrl.previousLecture : null,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text('السابق', style: GoogleFonts.cairo()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.divider,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: ctrl.hasNext ? ctrl.nextLecture : null,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: Text('التالي', style: GoogleFonts.cairo()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.divider,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VideoSection extends StatelessWidget {
  final LectureController ctrl;

  const _VideoSection({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final lecture = ctrl.currentLecture;

      if (ctrl.isLoadingPlayer.value) {
        return Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      }

      if (ctrl.playerError.value != null) {
        return Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.white70, size: 48),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(ctrl.playerError.value!,
                      style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: ctrl.retry,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary),
                    ),
                    if (lecture.url != null && lecture.url!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: ctrl.openExternal,
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text('رابط خارجي', style: GoogleFonts.cairo()),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }

      final controller = ctrl.videoController;
      if (controller == null || !controller.value.isInitialized) {
        return Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_outline,
                    color: Colors.white, size: 64),
                const SizedBox(height: 12),
                Text('اضغط لتشغيل الفيديو',
                    style: GoogleFonts.cairo(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: ctrl.retry,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text('تشغيل', style: GoogleFonts.cairo()),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio == 0
                  ? 16 / 9
                  : controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(controller),
                  if (!ctrl.isPlaying.value)
                    GestureDetector(
                      onTap: ctrl.togglePlay,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow,
                            color: Colors.white, size: 48),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                children: [
                  VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: AppColors.primary,
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: ctrl.togglePlay,
                        icon: Icon(
                          ctrl.isPlaying.value
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      Text(
                        '${ctrl.formatDuration(ctrl.position.value)} / ${ctrl.formatDuration(ctrl.duration.value)}',
                        style: GoogleFonts.cairo(color: Colors.white70, fontSize: 12),
                      ),
                      const Spacer(),
                      if (ctrl.isOffline.value)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.cloud_off,
                              color: AppColors.accent, size: 18),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

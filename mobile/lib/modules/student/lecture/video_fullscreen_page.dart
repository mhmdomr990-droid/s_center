import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';
import 'lecture_view_page.dart';

class VideoFullscreenPage extends StatefulWidget {
  final LectureController ctrl;

  const VideoFullscreenPage({super.key, required this.ctrl});

  @override
  State<VideoFullscreenPage> createState() => _VideoFullscreenPageState();
}

class _VideoFullscreenPageState extends State<VideoFullscreenPage> {
  bool _showControls = true;

  // Pinch-to-zoom: تكبير 1×..5× + تحريك داخل الحجم المكبَّر
  double _scale = 1.0;
  double _baseScale = 1.0;
  Offset _pan = Offset.zero;
  bool _showZoomHud = false;

  @override
  void initState() {
    super.initState();
    unawaited(widget.ctrl.enterFullscreen());
  }

  @override
  void dispose() {
    // استعادة الاتجاه فقط — الإيقاف يتم في _exit قبل الإغلاق
    unawaited(widget.ctrl.exitFullscreen());
    super.dispose();
  }

  /// خروج ذرّي: إيقاف التشغيل ثم إغلاق ملء الشاشة + صفحة المحاضرة
  /// معاً (بلا ظهور صفحة المحاضرة) ⇐ العودة لشاشة الإطلاق مباشرة.
  void _exit() {
    if (widget.ctrl.isPlaying.value) {
      unawaited(widget.ctrl.togglePlay());
    }
    if (Get.previousRoute == AppRoutes.lectureView) {
      Get.close(2);
    } else {
      // احتياطي: صفحة المحاضرة ليست تحتنا — اغلق مسار واحد
      Get.close(1);
    }
  }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  void _onScaleStart(ScaleStartDetails d) {
    _baseScale = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      _scale = (_baseScale * d.scale).clamp(1.0, 5.0).toDouble();
      if (_scale <= 1.001) {
        // عودة إلى الحجم الطبيعي ⇐ تصفير الإزاحة
        _scale = 1.0;
        _pan = Offset.zero;
      } else {
        _pan += d.focalPointDelta;
      }
      _showZoomHud = _scale > 1.05;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Obx(() {
          if (ctrl.isLoadingPlayer.value) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final error = ctrl.playerError.value;
          if (error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white70,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      error,
                      style: GoogleFonts.cairo(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: ctrl.retry,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }

          final controller = ctrl.videoController;
          if (controller == null || !controller.value.isInitialized) {
            return Center(
              child: ElevatedButton.icon(
                onPressed: ctrl.retry,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: Text('تشغيل', style: GoogleFonts.cairo()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            );
          }

          final aspect = controller.value.aspectRatio == 0
              ? 16 / 9
              : controller.value.aspectRatio;

          // حدود تحريك الفيديو المكبَّر: لا يخرج عن حدود الشاشة
          final screen = MediaQuery.sizeOf(context);
          double vw = screen.width;
          double vh = screen.width / aspect;
          if (vh > screen.height) {
            vh = screen.height;
            vw = screen.height * aspect;
          }
          double maxX = (vw * _scale - screen.width) / 2;
          double maxY = (vh * _scale - screen.height) / 2;
          if (maxX < 0) maxX = 0;
          if (maxY < 0) maxY = 0;
          final pan = Offset(
            _pan.dx.clamp(-maxX, maxX).toDouble(),
            _pan.dy.clamp(-maxY, maxY).toDouble(),
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                onScaleStart: _onScaleStart,
                onScaleUpdate: _onScaleUpdate,
                child: Center(
                  child: Transform.translate(
                    offset: pan,
                    child: Transform.scale(
                      scale: _scale,
                      child: AspectRatio(
                        aspectRatio: aspect,
                        child: VideoPlayer(controller),
                      ),
                    ),
                  ),
                ),
              ),
              if (!ctrl.isPlaying.value)
                Center(
                  child: GestureDetector(
                    onTap: ctrl.togglePlay,
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              if (_showControls)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleControls,
                    onScaleStart: _onScaleStart,
                    onScaleUpdate: _onScaleUpdate,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: _exit,
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  ctrl.currentLecture.title,
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (ctrl.isOffline.value)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(
                                    Icons.cloud_off,
                                    color: AppColors.accent,
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VideoSeekBar(ctrl: ctrl),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: ctrl.togglePlay,
                                    icon: Icon(
                                      ctrl.isPlaying.value
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      color: Colors.white,
                                      size: 34,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      '${ctrl.formatDuration(ctrl.isScrubbing.value ? ctrl.scrubPosition.value : ctrl.position.value)} / ${ctrl.formatDuration(ctrl.duration.value)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: _exit,
                                    icon: const Icon(
                                      Icons.fullscreen_exit,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                    tooltip: 'تصغير',
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_showZoomHud)
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '×${_scale.toStringAsFixed(1)}',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class VideoSeekBar extends StatelessWidget {
  final LectureController ctrl;

  const VideoSeekBar({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final maxMs = ctrl.duration.value.inMilliseconds;
    final shownMs =
        (ctrl.isScrubbing.value
                ? ctrl.scrubPosition.value
                : ctrl.position.value)
            .inMilliseconds;
    final value = maxMs > 0 ? shownMs.clamp(0, maxMs).toDouble() : 0.0;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: Colors.white24,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.25),
      ),
      child: Slider(
        value: value,
        max: maxMs > 0 ? maxMs.toDouble() : 1,
        onChanged: maxMs > 0
            ? (v) => ctrl.updateScrub(Duration(milliseconds: v.round()))
            : null,
        onChangeStart: maxMs > 0 ? (_) => ctrl.beginScrub() : null,
        onChangeEnd: maxMs > 0
            ? (v) => ctrl.endScrub(Duration(milliseconds: v.round()))
            : null,
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/routes/app_routes.dart';
import '../../data/services/app_status.dart';
import '../../data/services/device_guard.dart';
import '../../data/services/storage_service.dart';
import '../auth/auth_controller.dart';
import '../maintenance/maintenance_dialog.dart';
import '../security/emulator_blocked_dialog.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _content;
  late final AnimationController _sheen;
  Timer? _navTimer;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _content = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    )..repeat();

    // كشف المحاكي فوراً (محلي، بلا شبكة) — قبل أي فحص سيرفر أو تنقّل.
    // إن كان محاكياً: نافذة حظر دائمة + إلغاء كل ما يلي.
    unawaited(_guardEmulator());

    _navTimer = Timer(const Duration(milliseconds: 2800), () async {
      if (!mounted || _blocked) return;
      // فحص حالة السيرفر لحظة الفتح: صيانة ⇐ نافذة دائمة
      // (الأدمن يتجاوز دائماً — الباك يستثني مساراته)
      final status = await AppStatusService.fetch();
      if (!mounted || _blocked) return;
      if (status != null && status.maintenance) {
        final cached = await Get.find<StorageService>().getUser();
        if (cached?.isAdmin != true) {
          await showMaintenanceDialog(message: status.message);
        }
      }
      if (!mounted || _blocked) return;
      await Get.find<AuthController>().checkAuth();
      if (mounted && !_blocked && Get.currentRoute == AppRoutes.splash) {
        Get.offAllNamed(AppRoutes.login);
      }
    });
  }

  Future<void> _guardEmulator() async {
    final emulator = await DeviceGuard.isEmulator();
    if (!emulator || !mounted) return;
    _blocked = true;
    await showEmulatorBlockedDialog();
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _content.dispose();
    _sheen.dispose();
    super.dispose();
  }

  Animation<double> _interval(double begin, double end, {Curve curve = Curves.easeOutCubic}) {
    return CurvedAnimation(parent: _content, curve: Interval(begin, end, curve: curve));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0D2747), Color(0xFF14538A), Color(0xFF1E88E5)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _sheen,
                  builder: (_, _) => CustomPaint(painter: _SheenPainter(_sheen.value)),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أيقونة داخل دائرة زجاجية بتوهّج
                    FadeTransition(
                      opacity: _interval(0.0, 0.45),
                      child: ScaleTransition(
                        scale: _interval(0.0, 0.5, curve: Curves.easeOutBack),
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.13),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.30), width: 1.4),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E88E5)
                                    .withValues(alpha: 0.55),
                                blurRadius: 46,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.school_rounded,
                              size: 52, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    // اسم المركز
                    FadeTransition(
                      opacity: _interval(0.22, 0.62),
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.35),
                          end: Offset.zero,
                        ).animate(_interval(0.22, 0.62)),
                        child: Text(
                          'المركز الوطني للعلوم',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // خط فاصل متدرّج يتمدد من المركز
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 104),
                      duration: const Duration(milliseconds: 550),
                      curve: Curves.easeOutCubic,
                      builder: (context, width, _) => AnimatedBuilder(
                        animation: _content,
                        builder: (context, _) {
                          final p = _interval(0.45, 0.78).value;
                          return Opacity(
                            opacity: p,
                            child: Center(
                              child: Container(
                                width: width * p,
                                height: 2.5,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white,
                                      Color(0xFF64B5F6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    // العبارة التوضيحية
                    FadeTransition(
                      opacity: _interval(0.6, 1.0),
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(_interval(0.6, 1.0)),
                        child: Text(
                          'نرفع جاهزية طلاب الهندسات والاختصاصات العلمية عبر تدريب معرفي وتطبيقي متوازن',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.78),
                            height: 1.9,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // مؤشر تحميل خفيف أسفل الشاشة
            Positioned(
              bottom: 56,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _interval(0.75, 1.0),
                child: Center(
                  child: SizedBox(
                    width: 96,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const LinearProgressIndicator(
                        minHeight: 2.5,
                        backgroundColor: Color(0x33FFFFFF),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheenPainter extends CustomPainter {
  final double t;
  _SheenPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = (t / 0.62).clamp(0.0, 1.0);
    if (p >= 1.0) return;

    final sheenW = size.width * 0.55;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.55);
    canvas.translate(-size.width / 2, -size.height / 2);

    final startX = -sheenW - size.width * 0.25;
    final endX = size.width + size.width * 0.25;
    final x = startX + p * (endX - startX);
    final rect = Rect.fromLTWH(x, -size.height, sheenW, size.height * 3);

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.055),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SheenPainter old) => old.t != t;
}

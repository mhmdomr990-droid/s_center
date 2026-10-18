import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../data/services/app_status.dart';

bool _dialogVisible = false;
Future<void>? _active;

/// نافذة الصيانة الدائمة — تبقى ظاهرة طالما السيرفر في وضع الصيانة:
/// • الضغط خارجها لا يغلقها، وزر الرجوع يُغلق التطبيق كاملاً.
/// • إعادة الفحص تتم عند عودة التطبيق للواجهة أو بزر «إعادة الفحص»،
///   وتُغلق تلقائياً فقط عند تأكيد انتهاء الصيانة.
Future<void> showMaintenanceDialog({String? message}) {
  if (_dialogVisible) return _active ?? Future<void>.value();
  _dialogVisible = true;
  _active = _run(message);
  return _active!;
}

Future<void> _run(String? message) async {
  await Get.dialog<void>(
    _MaintenanceDialog(initialMessage: message),
    barrierDismissible: false,
  );
  _dialogVisible = false;
}

class _MaintenanceDialog extends StatefulWidget {
  final String? initialMessage;
  const _MaintenanceDialog({this.initialMessage});

  @override
  State<_MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends State<_MaintenanceDialog>
    with WidgetsBindingObserver {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // عودة المستخدم للتطبيق ⇐ إعادة فحص (المستخدم قد يُغلق التطبيق ويعيد فتحه)
    if (state == AppLifecycleState.resumed) unawaited(_recheck());
  }

  Future<void> _recheck() async {
    if (_checking || !mounted) return;
    setState(() => _checking = true);
    try {
      final status = await AppStatusService.fetch();
      // إغلاق فقط عند تأكيد انتهاء الصيانة — فشل الشبكة يُبقي النافذة
      if (mounted && status != null && !status.maintenance) {
        Get.back<void>();
        Get.snackbar('تم', 'عاد الخادم للعمل',
            backgroundColor: Colors.green, colorText: Colors.white);
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = (widget.initialMessage ?? '').trim().isEmpty
        ? 'التطبيق قيد الصيانة حاليًا'
        : widget.initialMessage!.trim();
    return PopScope(
      // زر الرجوع لا يُغلق النافذة — يُغلق التطبيق كاملاً (سيناريو إعادة الفتح)
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: AppColors.courseCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                'السيرفر مشغول حالياً',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.7),
              ),
              const SizedBox(height: 14),
              Text(
                'سيُستأنف العمل تلقائياً عند انتهاء الصيانة —\nأعد فتح التطبيق أو اضغط «إعادة الفحص».',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    height: 1.7),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _checking ? null : _recheck,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _checking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh, color: Colors.white, size: 18),
                  label: Text(
                    _checking ? 'جاري الفحص...' : 'إعادة الفحص',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

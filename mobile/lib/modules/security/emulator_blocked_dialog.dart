import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../widgets/custom_button.dart';

bool _dialogVisible = false;

/// نافذة حظر المحاكي الدائمة — تظهر فوراً عند الإقلاع على محاكي:
/// • الضغط خارجها لا يغلقها، وزر الرجوع يُغلق التطبيق كاملاً.
/// • لا إعادة فحص — حالة المحاكي لا تتغير.
Future<void> showEmulatorBlockedDialog() {
  if (_dialogVisible) return Future<void>.value();
  _dialogVisible = true;
  return Get.dialog<void>(
    const _EmulatorBlockedDialog(),
    barrierDismissible: false,
  ).whenComplete(() => _dialogVisible = false);
}

class _EmulatorBlockedDialog extends StatelessWidget {
  const _EmulatorBlockedDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // زر الرجوع لا يُغلق النافذة — يُغلق التطبيق كاملاً
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
                child: const Icon(Icons.phonelink_lock_rounded,
                    color: AppColors.error, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                'جهاز غير مدعوم',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Text(
                'يعمل هذا التطبيق على الأجهزة الحقيقية فقط.\nيرجى استخدام هاتفك مباشرة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.7),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'خروج',
                icon: Icons.exit_to_app_rounded,
                onPressed: () => SystemNavigator.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

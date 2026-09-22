import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_text_styles.dart';

class BalanceCard extends StatelessWidget {
  final String balance;
  final VoidCallback? onTopup;

  const BalanceCard({super.key, required this.balance, this.onTopup});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('محفظتك', style: AppTextStyles.balanceLabel),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(balance, style: AppTextStyles.balanceLarge),
              const SizedBox(width: 8),
              Text('SYP', style: AppTextStyles.balanceLabel),
            ],
          ),
          const SizedBox(height: 16),
          if (onTopup != null)
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: onTopup,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'شحن رصيد المحفظة',
                        style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

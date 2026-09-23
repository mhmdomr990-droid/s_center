import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/app_shadows.dart';
import '../app/theme/app_text_styles.dart';
import '../utils/format.dart';

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
        boxShadow: AppShadows.colored,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: _circle(140, 0.08),
          ),
          Positioned(
            left: -20,
            bottom: -50,
            child: _circle(110, 0.06),
          ),
          Positioned(
            right: 70,
            bottom: -20,
            child: _circle(60, 0.07),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text('محفظتك', style: AppTextStyles.balanceLabel),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(formatAmount(balance), style: AppTextStyles.balanceLarge),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_circle_outline,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'شحن رصيد المحفظة',
                            style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

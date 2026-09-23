import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app/theme/app_colors.dart';

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const GradientAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = true,
  }) : assert(title != null || titleWidget != null);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ??
          Text(
            title!,
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600, fontSize: 18),
          ),
      centerTitle: centerTitle,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: leading,
      actions: actions,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: _glow(120),
            ),
            Positioned(
              left: -30,
              bottom: -60,
              child: _glow(90),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glow(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.07),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

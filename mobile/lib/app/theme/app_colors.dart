import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color accent = Color(0xFF90CAF9);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);

  static Color background = const Color(0xFFEEF3F8);
  static Color sectionStrip = const Color(0xFFF7F9FC);
  static Color surface = const Color(0xFFFFFFFF);
  static Color card = const Color(0xFFFFFFFF);
  static Color courseCard = const Color(0xFFEFF6FF);
  static Color cardBorder = const Color(0xFFCFE3F7);
  static Color textPrimary = const Color(0xFF212121);
  static Color textSecondary = const Color(0xFF757575);
  static Color textHint = const Color(0xFFBDBDBD);
  static Color divider = const Color(0xFFE0E0E0);
  static Color shimmerBase = const Color(0xFFDFE6EF);
  static Color shimmerHighlight = const Color(0xFFF2F6FB);
  static Color bottomNavBg = const Color(0xFFEFF6FF);
  static Color bottomNavSelected = const Color(0xFF1976D2);
  static Color bottomNavUnselected = const Color(0xFFBDBDBD);

  static void setDarkMode(bool dark) {
    if (dark) {
      background = const Color(0xFF10161F);
      sectionStrip = const Color(0xFF171E2A);
      surface = const Color(0xFF18202C);
      card = const Color(0xFF18202C);
      courseCard = const Color(0xFF17222E);
      cardBorder = const Color(0xFF2A3644);
      textPrimary = const Color(0xFFECEFF4);
      textSecondary = const Color(0xFFA7B0BD);
      textHint = const Color(0xFF6E7680);
      divider = const Color(0xFF2A3342);
      shimmerBase = const Color(0xFF232A38);
      shimmerHighlight = const Color(0xFF2F3748);
      bottomNavBg = const Color(0xFF18202C);
      bottomNavSelected = const Color(0xFF64B5F6);
      bottomNavUnselected = const Color(0xFF6E7680);
      primaryGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A1F3D), Color(0xFF103452), Color(0xFF1565C0)],
      );
      cardGradient = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF0D2747), Color(0xFF14538A), Color(0xFF1E88E5)],
      );
    } else {
      background = const Color(0xFFEEF3F8);
      sectionStrip = const Color(0xFFF7F9FC);
      surface = const Color(0xFFFFFFFF);
      card = const Color(0xFFFFFFFF);
      courseCard = const Color(0xFFEFF6FF);
      cardBorder = const Color(0xFFCFE3F7);
      textPrimary = const Color(0xFF212121);
      textSecondary = const Color(0xFF757575);
      textHint = const Color(0xFFBDBDBD);
      divider = const Color(0xFFE0E0E0);
      shimmerBase = const Color(0xFFDFE6EF);
      shimmerHighlight = const Color(0xFFF2F6FB);
      bottomNavBg = const Color(0xFFEFF6FF);
      bottomNavSelected = const Color(0xFF1976D2);
      bottomNavUnselected = const Color(0xFFBDBDBD);
      primaryGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
      );
      cardGradient = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF64B5F6)],
      );
    }
  }

  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D47A1), Color(0xFF1976D2), Color(0xFF42A5F5)],
  );

  static LinearGradient cardGradient = const LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF64B5F6)],
  );

  static const List<Color> specPalette = [
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFFEF6C00),
    Color(0xFF00838F),
    Color(0xFFC62828),
  ];

  static Color specializationColor(int id) =>
      id <= 0 ? primary : specPalette[id % specPalette.length];
}

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

  static Color background = const Color(0xFFCADEF7);
  static Color sectionStrip = const Color(0xFFB6D2F2);
  static Color surface = const Color(0xFFF5F9FD);
  static Color card = const Color(0xFFC2DAF5);
  static Color courseCard = const Color(0xFFC2DAF5);
  static Color cardBorder = const Color(0xFF9FC4EB);
  static Color textPrimary = const Color(0xFF212121);
  static Color textSecondary = const Color(0xFF757575);
  static Color textHint = const Color(0xFFBDBDBD);
  static Color divider = const Color(0xFFD3E2F1);
  static Color shimmerBase = const Color(0xFFB9D3F1);
  static Color shimmerHighlight = const Color(0xFFE3EEFC);
  static Color bottomNavBg = const Color(0xFFC2DAF5);
  static Color bottomNavSelected = const Color(0xFF1976D2);
  static Color bottomNavUnselected = const Color(0xFFBDBDBD);

  static void setDarkMode(bool dark) {
    if (dark) {
      background = const Color(0xFF0E1520);
      sectionStrip = const Color(0xFF161E2C);
      surface = const Color(0xFF1A2637);
      card = const Color(0xFF1A2637);
      courseCard = const Color(0xFF182841);
      cardBorder = const Color(0xFF2E3E55);
      textPrimary = const Color(0xFFECEFF4);
      textSecondary = const Color(0xFFA7B0BD);
      textHint = const Color(0xFF6E7680);
      divider = const Color(0xFF2E3A4C);
      shimmerBase = const Color(0xFF232E42);
      shimmerHighlight = const Color(0xFF2F3B54);
      bottomNavBg = const Color(0xFF182841);
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
      background = const Color(0xFFCADEF7);
      sectionStrip = const Color(0xFFB6D2F2);
      surface = const Color(0xFFF5F9FD);
      card = const Color(0xFFC2DAF5);
      courseCard = const Color(0xFFC2DAF5);
      cardBorder = const Color(0xFF9FC4EB);
      textPrimary = const Color(0xFF212121);
      textSecondary = const Color(0xFF757575);
      textHint = const Color(0xFFBDBDBD);
      divider = const Color(0xFFD3E2F1);
      shimmerBase = const Color(0xFFB9D3F1);
      shimmerHighlight = const Color(0xFFE3EEFC);
      bottomNavBg = const Color(0xFFC2DAF5);
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

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color accent = Color(0xFF81C784);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);

  static Color background = const Color(0xFFEDF1EE);
  static Color sectionStrip = const Color(0xFFF7F9F8);
  static Color surface = const Color(0xFFFFFFFF);
  static Color card = const Color(0xFFFFFFFF);
  static Color courseCard = const Color(0xFFEFF7F1);
  static Color textPrimary = const Color(0xFF212121);
  static Color textSecondary = const Color(0xFF757575);
  static Color textHint = const Color(0xFFBDBDBD);
  static Color divider = const Color(0xFFE0E0E0);
  static Color shimmerBase = const Color(0xFFE0E0E0);
  static Color shimmerHighlight = const Color(0xFFF5F5F5);
  static Color bottomNavBg = const Color(0xFFFFFFFF);
  static Color bottomNavSelected = const Color(0xFF2E7D32);
  static Color bottomNavUnselected = const Color(0xFFBDBDBD);

  static void setDarkMode(bool dark) {
    if (dark) {
      background = const Color(0xFF121514);
      sectionStrip = const Color(0xFF1A1E1C);
      surface = const Color(0xFF1C211E);
      card = const Color(0xFF1C211E);
      courseCard = const Color(0xFF1A2A1F);
      textPrimary = const Color(0xFFECEFE9);
      textSecondary = const Color(0xFFA5AEA6);
      textHint = const Color(0xFF6E766F);
      divider = const Color(0xFF2C322E);
      shimmerBase = const Color(0xFF2A2E2C);
      shimmerHighlight = const Color(0xFF3A3F3C);
      bottomNavBg = const Color(0xFF1C211E);
      bottomNavSelected = const Color(0xFF66BB6A);
      bottomNavUnselected = const Color(0xFF6E766F);
      primaryGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A1F14), Color(0xFF103424), Color(0xFF1B5E20)],
      );
      cardGradient = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF0D2B1A), Color(0xFF14532D), Color(0xFF1B7338)],
      );
    } else {
      background = const Color(0xFFEDF1EE);
      sectionStrip = const Color(0xFFF7F9F8);
      surface = const Color(0xFFFFFFFF);
      card = const Color(0xFFFFFFFF);
      courseCard = const Color(0xFFEFF7F1);
      textPrimary = const Color(0xFF212121);
      textSecondary = const Color(0xFF757575);
      textHint = const Color(0xFFBDBDBD);
      divider = const Color(0xFFE0E0E0);
      shimmerBase = const Color(0xFFE0E0E0);
      shimmerHighlight = const Color(0xFFF5F5F5);
      bottomNavBg = const Color(0xFFFFFFFF);
      bottomNavSelected = const Color(0xFF2E7D32);
      bottomNavUnselected = const Color(0xFFBDBDBD);
      primaryGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
      );
      cardGradient = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFF14532D), Color(0xFF1B7338), Color(0xFF2E9E4F)],
      );
    }
  }

  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
  );

  static LinearGradient cardGradient = const LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF14532D), Color(0xFF1B7338), Color(0xFF2E9E4F)],
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

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color accent = Color(0xFF81C784);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color bottomNavBg = Color(0xFFFFFFFF);
  static const Color bottomNavSelected = Color(0xFF2E7D32);
  static const Color bottomNavUnselected = Color(0xFFBDBDBD);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, primaryLight],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF2E7D32), Color(0xFF43A047), Color(0xFF66BB6A)],
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

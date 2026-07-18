import 'package:flutter/material.dart';

/// Central place for colors and the signature dark gradient used across the app.
class AppTheme {
  AppTheme._();

  // Core palette.
  static const Color bgTop = Color(0xFF0F0C29);
  static const Color bgMid = Color(0xFF302B63);
  static const Color bgBottom = Color(0xFF24243E);

  static const Color accent = Color(0xFF7C5CFF); // violet
  static const Color accentGlow = Color(0xFF00E0FF); // cyan glow
  static const Color silver = Color(0xFFE6E8EF);
  static const Color silverDim = Color(0xFFB4B8C5);

  /// The full-screen dark gradient background.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgTop, bgMid, bgBottom],
    stops: [0.0, 0.55, 1.0],
  );

  /// Gradient used on the "Platinum" payment card face.
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3A3A52),
      Color(0xFF23233A),
      Color(0xFF15151F),
    ],
  );

  /// Translucent "glass" fill for cards and buttons.
  static Color glassFill([double opacity = 0.10]) =>
      Colors.white.withValues(alpha: opacity);

  static Color glassBorder([double opacity = 0.22]) =>
      Colors.white.withValues(alpha: opacity);
}

import 'package:flutter/material.dart';
import '../models/app_settings.dart';

class AppTheme {
  // ── Table Green (default) ─────────────────────────────
  static const Color tableGreen = Color(0xFF1B5E20);
  static const Color tableFelt = Color(0xFF2E7D32);
  static const Color cardWhite = Color(0xFFFFFDE7);
  static const Color cardRed = Color(0xFFD32F2F);
  static const Color cardBlack = Color(0xFF212121);
  static const Color accent = Color(0xFFFFD600);
  static const Color accentDark = Color(0xFFF9A825);
  static const Color surface = Color(0xFF1A237E);
  static const Color textLight = Color(0xFFFFFDE7);
  static const Color textDim = Color(0xFFB0BEC5);

  // ── Theme selector ────────────────────────────────────
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.tableGreen:
        return _tableGreenTheme;
      case AppThemeMode.dark:
        return _darkTheme;
      case AppThemeMode.light:
        return _lightTheme;
    }
  }

  static ThemeData get theme => _tableGreenTheme;

  static final _tableGreenTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: accent,
      secondary: accentDark,
      surface: surface,
    ),
    scaffoldBackgroundColor: tableGreen,
    fontFamily: 'Georgia',
    elevatedButtonTheme: _buttonTheme(accent, cardBlack),
  );

  static final _darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF90CAF9),
      secondary: const Color(0xFF64B5F6),
      surface: const Color(0xFF1E1E2E),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    fontFamily: 'Georgia',
    elevatedButtonTheme: _buttonTheme(const Color(0xFF90CAF9), Colors.black),
  );

  static final _lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF1565C0),
      secondary: const Color(0xFF42A5F5),
      surface: const Color(0xFFE3F2FD),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    fontFamily: 'Georgia',
    elevatedButtonTheme: _buttonTheme(const Color(0xFF1565C0), Colors.white),
  );

  static ElevatedButtonThemeData _buttonTheme(Color bg, Color fg) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      );
}

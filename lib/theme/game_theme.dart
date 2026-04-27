import 'package:flutter/material.dart';

class GameTheme {
  static const Color bg = Color(0xFF080A10);
  static const Color panel = Color(0xFF111522);
  static const Color panelSoft = Color(0xFF171C2B);
  static const Color stroke = Color(0xFF2A3145);

  static const Color accent = Color(0xFFE11D48);
  static const Color accentAlt = Color(0xFFF97316);
  static const Color ok = Color(0xFF22C55E);
  static const Color warn = Color(0xFFFACC15);

  static ThemeData buildTheme() {
    const scheme = ColorScheme.dark(
      primary: accent,
      secondary: accentAlt,
      surface: panel,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFE5E7EB),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      fontFamily: 'Verdana',
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: stroke),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        titleMedium: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: TextStyle(color: Color(0xFFC7CEDB)),
        bodySmall: TextStyle(color: Color(0xFF9AA4B4)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: stroke),
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: panelSoft,
        selectedColor: const Color(0xFF2B3550),
        disabledColor: const Color(0xFF1A1F2D),
        side: const BorderSide(color: stroke),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 1.4),
        ),
        hintStyle: const TextStyle(color: Color(0xFF8B95A7)),
      ),
    );
  }
}

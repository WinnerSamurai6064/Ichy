import 'package:flutter/material.dart';

class IEChilliTheme {
  // Brand Colors
  static const Color chilliRed = Color(0xFFE53935);
  static const Color chilliDark = Color(0xFFC62828);
  static const Color chilliGlow = Color(0xFFFF5252);

  // Dark Background Palette
  static const Color bgPrimary = Color(0xFF0A0A0A);
  static const Color bgSecondary = Color(0xFF111111);
  static const Color bgCard = Color(0xFF1A1A1A);
  static const Color bgElevated = Color(0xFF222222);
  static const Color bgInput = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textMuted = Color(0xFF616161);
  static const Color textChilli = Color(0xFFFF5252);

  // Message Bubbles
  static const Color bubbleSent = Color(0xFFB71C1C);
  static const Color bubbleReceived = Color(0xFF1F1F1F);
  static const Color bubbleSentDark = Color(0xFF8B0000);

  // Status / Ticks
  static const Color tickRead = Color(0xFF4FC3F7);
  static const Color tickSent = Color(0xFF9E9E9E);

  // Divider / Border
  static const Color border = Color(0xFF2A2A2A);
  static const Color divider = Color(0xFF1F1F1F);

  // Online indicator
  static const Color online = Color(0xFF4CAF50);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: chilliRed,
        secondary: chilliGlow,
        surface: bgSecondary,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgSecondary,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgSecondary,
        selectedItemColor: chilliRed,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 28,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 17,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: textMuted,
          fontSize: 12,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 0.5,
      ),
    );
  }
}

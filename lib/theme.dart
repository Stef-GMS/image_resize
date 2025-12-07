import 'package:flutter/material.dart';

/// Defines the theme data for the application.
class AppTheme {
  /// The primary color used throughout the application.
  static const _primaryColor = Color(0xFF6366F1);

  /// The background color for the light theme.
  static const _backgroundColorLight = Color(0xFFF8F7FA);

  /// The background color for the dark theme.
  static const _backgroundColorDark = Color(0xFF121212);

  /// The card color for the light theme.
  static const _cardColorLight = Color(0xFFFFFFFF);

  /// The text field color for the light theme.
  static const _textFieldColorLight = Color(0xFFEDEDED);

  /// The card color for the dark theme.
  static const _cardColorDark = Color(0xFF1E1E1E);

  /// The light theme data.
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.light,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _backgroundColorLight,
    cardColor: _cardColorLight,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: _backgroundColorLight,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: _primaryColor,
        backgroundColor: _primaryColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: _textFieldColorLight,
      filled: true,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
    ),
  );

  /// The dark theme data.
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: false,
    brightness: Brightness.dark,
    primaryColor: _primaryColor,
    scaffoldBackgroundColor: _backgroundColorDark,
    cardColor: _cardColorDark,
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: _backgroundColorDark,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _primaryColor.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';

class AppTheme {
  static const _primaryColor = Color(0xFF6366F1);
  static const _backgroundColorLight = Color(0xFFF8F7FA);
  static const _backgroundColorDark = Color(0xFF121212);
  static const _cardColorLight = Color(0xFFFFFFFF);
  static const _cardColorDark = Color(0xFF1E1E1E);

  static final ThemeData lightTheme = ThemeData(
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
        backgroundColor: _primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
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
        backgroundColor: _primaryColor.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),
  );
}
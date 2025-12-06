import 'package:flutter/material.dart';
import 'package:image_resize/screens/image_resize_screen.dart';
import 'package:image_resize/theme.dart';

/// Main entry point of the application.
void main() {
  runApp(const MainApp());
}

/// The root widget of the application.
class MainApp extends StatefulWidget {
  /// Creates a [MainApp] widget.
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

/// The state for the [MainApp] widget.
class _MainAppState extends State<MainApp> {
  /// The current theme mode of the application.
  ThemeMode _themeMode = ThemeMode.system;

  /// Changes the theme mode of the application.
  void changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Image Resizer',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: ImageResizeScreen(
        handleThemeChange: changeTheme,
        themeMode: _themeMode,
      ),
    );
  }
}

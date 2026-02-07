import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_resize/screens/image_resize_screen.dart';
import 'package:image_resize/theme.dart';
import 'package:window_manager/window_manager.dart';

/// Main entry point of the application.
void main() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

    await windowManager.setMinimumSize(const Size(409, 800));
    await windowManager.setMaximumSize(const Size(618, 2200));
    await windowManager.setSize(const Size(409, 800));
    // await windowManager.setAspectRatio(0.54);
    await windowManager.setMaximizable(false);

    // await windowManager.setMinimumSize(const Size(800, 800));
    // await windowManager.setMaximumSize(const Size(618, 1200));
    // await windowManager.setSize(const Size(800, 800));
    // await windowManager.setAspectRatio(0.54);
    // await windowManager.setMaximizable(false);

    await windowManager.setTitle('Image Resize'); //Window title
  }
  // final repository = SqliteRepository();
  // await repository.init();

  runApp(const ProviderScope(child: MainApp()));
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

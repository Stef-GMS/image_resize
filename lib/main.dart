import 'package:flutter/material.dart';
import 'package:image_resize/screens/image_resize_screen.dart';
import 'package:image_resize/theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Resizer',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const ImageResizeScreen(),
    );
  }
}
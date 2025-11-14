import 'package:flutter/material.dart';
import 'package:image_resize/screens/image_resize_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Image Resizer'),
        ),
        body: const ImageResizeScreen(),
      ),
    );
  }
}
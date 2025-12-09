import 'package:flutter/material.dart';
import 'package:image_resize/screens/settings_screen.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({
    super.key,
    required this.isDarkMode,
    required this.handleThemeChange,
    required this.themeMode,
  });

  final bool isDarkMode;
  final void Function(ThemeMode) handleThemeChange;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Image Resize',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    handleThemeChange: handleThemeChange,
                    themeMode: themeMode,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

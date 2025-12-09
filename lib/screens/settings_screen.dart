import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A screen where the user can change the app settings, now including image source preferences.
class SettingsScreen extends ConsumerWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key, required this.handleThemeChange, required this.themeMode});

  /// A callback to handle theme changes.
  final void Function(ThemeMode) handleThemeChange;

  /// The current theme mode.
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Theme Settings ---
            Text(
              'Theme',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            RadioGroup<ThemeMode>(
              // Reintroduced RadioGroup here
              groupValue: themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  handleThemeChange(value);
                }
              },
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('System'),
                    value: ThemeMode.system,
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Light'),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark'),
                    value: ThemeMode.dark,
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
          ],
        ),
      ),
    );
  }
}

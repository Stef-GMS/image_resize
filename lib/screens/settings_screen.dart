import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCloudDrive = 'icloud';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cloud Drive',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            RadioListTile<String>(
              title: const Text('iCloud'),
              value: 'icloud',
              groupValue: _selectedCloudDrive,
              onChanged: (String? value) {
                setState(() {
                  _selectedCloudDrive = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Google Drive'),
              value: 'google_drive',
              groupValue: _selectedCloudDrive,
              onChanged: (String? value) {
                setState(() {
                  _selectedCloudDrive = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

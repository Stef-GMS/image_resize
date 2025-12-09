import 'package:image_resize/widgets/dropdown_entry.dart';

/// Defines the supported cloud storage providers.
enum CloudStorageProvider implements DropdownLabel {
  googleDrive('Google Drive'),
  dropbox('Dropbox'),
  iCloudDrive('iCloud Drive');

  const CloudStorageProvider(this.label);

  @override
  final String label;
}

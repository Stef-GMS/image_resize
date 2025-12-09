import 'package:image_resize/widgets/dropdown_entry.dart';

/// Defines the source for the "Device" button image picker.
enum DevicePickerSource implements DropdownLabel {
  /// Uses `image_picker` to select from the device's native photo gallery.
  gallery('Photo Gallery'),

  /// Uses `file_picker` to select from the device's general file system.
  fileSystem('File System');

  const DevicePickerSource(this.label);

  @override
  final String label;
}
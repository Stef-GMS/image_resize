import 'package:image_resize/widgets/dropdown_entry.dart';

/// Enum for the save destination options.
enum SaveDestination implements DropdownLabel {
  devicePhotos('Device Photos'),
  cloud('Cloud'),
  deviceFileSystem('Device File System');

  const SaveDestination(this.label);

  @override
  final String label;
}


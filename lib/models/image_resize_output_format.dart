import 'package:image_resize/widgets/dropdown_entry.dart';

/// Enum for the output format of the resized image.
enum ImageResizeOutputFormat implements DropdownLabel {
  sameAsOriginal('Same as Original'),
  jpg('JPG'),
  png('PNG');

  const ImageResizeOutputFormat(this.label);

  @override
  final String label;
}

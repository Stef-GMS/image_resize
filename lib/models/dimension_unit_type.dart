import 'package:image_resize/widgets/dropdown_entry.dart';

enum DimensionUnitType implements DropdownLabel {
  pixels('px'),
  percent('%'),
  cm('cm'),
  mm('mm'),
  inches('in');

  const DimensionUnitType(this.label);

  @override
  final String label;
}

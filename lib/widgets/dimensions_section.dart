import 'package:flutter/material.dart';
import 'package:image_resize/models/dimension_unit_type.dart';
import 'package:image_resize/widgets/dropdown_entry.dart';
import 'package:image_resize/widgets/text_field_entry.dart';

/// A widget that displays the dimensions section of the screen.
class DimensionsSection extends StatelessWidget {
  /// Creates a [DimensionsSection] widget.
  const DimensionsSection({
    super.key,
    required this.theme,
    required this.maintainAspectRatio,
    required this.onAspectRatioChanged,
    required this.dimensionType,
    required this.onUnitChanged,
    required this.widthController,
    required this.heightController,
    required this.resolutionController,
    this.onWidthChanged,
    this.onHeightChanged,
    this.onResolutionChanged,
  });

  /// The theme data.
  final ThemeData theme;

  /// Whether to maintain the aspect ratio of the image.
  final bool maintainAspectRatio;

  /// A callback to handle aspect ratio changes.
  final ValueChanged<bool?> onAspectRatioChanged;

  /// The type of dimension to use for resizing.
  final DimensionUnitType dimensionType;

  /// A callback to handle unit changes.
  final ValueChanged<DimensionUnitType> onUnitChanged;

  /// The controller for the width text field.
  final TextEditingController widthController;

  /// The controller for the height text field.
  final TextEditingController heightController;

  /// The controller for the resolution text field.
  final TextEditingController resolutionController;

  /// A callback to handle width text changes.
  final ValueChanged<String>? onWidthChanged;

  /// A callback to handle height text changes.
  final ValueChanged<String>? onHeightChanged;

  /// A callback to handle resolution text changes.
  final ValueChanged<String>? onResolutionChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// Dimensions section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dimensions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Lock Aspect Ratio',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: Checkbox(
                        value: maintainAspectRatio,
                        onChanged: onAspectRatioChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                IntrinsicWidth(
                  child: DropdownEntry(
                    theme: theme,
                    label: 'Units',
                    value: dimensionType,
                    items: DimensionUnitType.values,
                    onChanged: onUnitChanged,
                  ),
                ),
                IntrinsicWidth(
                  child: TextFieldEntry(
                    theme: theme,
                    label: 'Width',
                    controller: widthController,
                    unit: dimensionType.label,
                    onChanged: onWidthChanged,
                  ),
                ),
                IntrinsicWidth(
                  child: TextFieldEntry(
                    theme: theme,
                    label: 'Height',
                    controller: heightController,
                    unit: dimensionType.label,
                    onChanged: onHeightChanged,
                  ),
                ),
                IntrinsicWidth(
                  child: TextFieldEntry(
                    theme: theme,
                    label: 'Res',
                    unit: 'dpi',
                    controller: resolutionController,
                    onChanged: onResolutionChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

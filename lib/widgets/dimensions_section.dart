import 'package:flutter/material.dart';
import 'package:image_resize/widgets/dropdown_row.dart';
import 'package:image_resize/widgets/text_field_row.dart';

/// A widget that displays the dimensions section of the screen.
class DimensionsSection extends StatelessWidget {
  /// The theme data.
  final ThemeData theme;

  /// Whether to maintain the aspect ratio of the image.
  final bool maintainAspectRatio;

  /// A callback to handle aspect ratio changes.
  final ValueChanged<bool?> onAspectRatioChanged;

  /// The type of dimension to use for resizing.
  final String dimensionType;

  /// A callback to handle unit changes.
  final ValueChanged<String?> onUnitChanged;

  /// The controller for the width text field.
  final TextEditingController widthController;

  /// The focus node for the width text field.
  final FocusNode widthFocusNode;

  /// The controller for the height text field.
  final TextEditingController heightController;

  /// The focus node for the height text field.
  final FocusNode heightFocusNode;

  /// A map of dimension units.
  final Map<String, String> unitMap;

  /// The controller for the resolution text field.
  final TextEditingController resolutionController;

  /// The unit for the resolution.
  final String resolutionUnit;

  /// A callback to handle resolution unit changes.
  final ValueChanged<String?> onResolutionUnitChanged;

  /// Creates a [DimensionsSection] widget.
  const DimensionsSection({
    super.key,
    required this.theme,
    required this.maintainAspectRatio,
    required this.onAspectRatioChanged,
    required this.dimensionType,
    required this.onUnitChanged,
    required this.widthController,
    required this.widthFocusNode,
    required this.heightController,
    required this.heightFocusNode,
    required this.unitMap,
    required this.resolutionController,
    required this.resolutionUnit,
    required this.onResolutionUnitChanged,
  });

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            DropdownRow(
              theme: theme,
              label: 'Units',
              value: dimensionType,
              items: unitMap.keys.toList(),
              onChanged: onUnitChanged,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFieldRow(
                    theme: theme,
                    label: 'Width',
                    controller: widthController,
                    focusNode: widthFocusNode,
                    unit: unitMap[dimensionType]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFieldRow(
                    theme: theme,
                    label: 'Height',
                    controller: heightController,
                    focusNode: heightFocusNode,
                    unit: unitMap[dimensionType]!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFieldRow(
                    theme: theme,
                    label: 'Resolution',
                    controller: resolutionController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownRow(
                    theme: theme,
                    label: 'Resolution Unit',
                    value: resolutionUnit,
                    items: const ['pixels/inch', 'pixels/cm'],
                    onChanged: onResolutionUnitChanged,
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

import 'package:flutter/material.dart';
import 'package:image_resize/widgets/dropdown_row.dart';
import 'package:image_resize/widgets/text_field_row.dart';

class DimensionsSection extends StatelessWidget {
  final ThemeData theme;
  final bool maintainAspectRatio;
  final ValueChanged<bool?> onAspectRatioChanged;
  final String dimensionType;
  final ValueChanged<String?> onUnitChanged;
  final TextEditingController widthController;
  final FocusNode widthFocusNode;
  final TextEditingController heightController;
  final FocusNode heightFocusNode;
  final Map<String, String> unitMap;

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
            _buildTextFieldRow(
              theme: theme,
              label: 'Height',
              controller: heightController,
              focusNode: heightFocusNode,
              unit: unitMap[dimensionType]!,
            ),
          ],
        ),
      ),
    );
  }
}

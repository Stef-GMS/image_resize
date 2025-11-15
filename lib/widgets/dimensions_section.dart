import 'package:flutter/material.dart';

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
            _buildDropdownRow(
              theme,
              'Units',
              dimensionType,
              unitMap.keys.toList(),
              onUnitChanged,
            ),
            const SizedBox(height: 16),
            _buildTextFieldRow(
              theme: theme,
              label: 'Width',
              controller: widthController,
              focusNode: widthFocusNode,
              unit: unitMap[dimensionType]!,
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

  Widget _buildDropdownRow(ThemeData theme, String label, String value,
      List<String> items, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldRow({
    required ThemeData theme,
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    String? placeholder,
    String? unit,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: placeholder,
              isDense: true,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (unit != null) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              unit,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
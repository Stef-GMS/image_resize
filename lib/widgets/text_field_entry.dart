import 'package:flutter/material.dart';

/// A widget that displays a text field row with a label.
class TextFieldEntry extends StatelessWidget {
  /// Creates a [TextFieldEntry] widget.
  const TextFieldEntry({
    super.key,
    required this.theme,
    required this.label,
    required this.controller,
    this.placeholder,
    this.unit,
    this.onChanged,
  });

  /// The theme data.
  final ThemeData theme;

  /// The label for the text field.
  final String label;

  /// The controller for the text field.
  final TextEditingController controller;

  /// The placeholder text for the text field.
  final String? placeholder;

  /// The unit to display next to the text field.
  final String? unit;

  /// A callback to handle text changes.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
            if (unit != null) ...[
              const SizedBox(width: 8),
              Text(
                unit!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ],
        ),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: placeholder,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

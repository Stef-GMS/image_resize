import 'package:flutter/material.dart';

/// A widget that displays a text field row with a label.
class TextFieldRow extends StatelessWidget {
  /// The theme data.
  final ThemeData theme;

  /// The label for the text field.
  final String label;

  /// The controller for the text field.
  final TextEditingController controller;

  /// The focus node for the text field.
  final FocusNode? focusNode;

  /// The placeholder text for the text field.
  final String? placeholder;

  /// The unit to display next to the text field.
  final String? unit;

  /// Creates a [TextFieldRow] widget.
  const TextFieldRow({
    super.key,
    required this.theme,
    required this.label,
    required this.controller,
    this.focusNode,
    this.placeholder,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 50,
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
              unit!,
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

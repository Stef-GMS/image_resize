import 'package:flutter/material.dart';

class TextFieldRow extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? placeholder;
  final String? unit;

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

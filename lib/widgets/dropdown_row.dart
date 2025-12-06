import 'package:flutter/material.dart';

/// A widget that displays a dropdown row with a label.
class DropdownRow<T> extends StatelessWidget {
  /// The theme data.
  final ThemeData theme;

  /// The label for the dropdown.
  final String label;

  /// The currently selected value.
  final T value;

  /// The list of items to display in the dropdown.
  final List<T> items;

  /// A callback to handle value changes.
  final ValueChanged<T?> onChanged;

  /// Creates a [DropdownRow] widget.
  const DropdownRow({
    super.key,
    required this.theme,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                items: items.map<DropdownMenuItem<T>>((T value) {
                  return DropdownMenuItem<T>(
                    value: value,
                    child: Text(value is Enum ? value.name : value.toString()),
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
}

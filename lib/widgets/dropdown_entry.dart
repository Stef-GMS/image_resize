import 'package:flutter/material.dart';

abstract class DropdownLabel {
  String get label;
}

/// A widget that displays a dropdown row with a label.
class DropdownEntry<T> extends StatelessWidget {
  /// Creates a [DropdownEntry] widget.
  const DropdownEntry({
    super.key,
    required this.theme,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
  });

  /// The theme data.
  final ThemeData theme;

  /// The currently selected value.
  final T value;

  /// The list of items to display in the dropdown.
  final List<T> items;

  /// A callback to handle value changes.
  final ValueChanged<T> onChanged;

  /// The label for the dropdown.
  final String? label;

  @override
  Widget build(BuildContext context) {
    String labelForItem(T item) {
      if (item is DropdownLabel) {
        return item.label;
      }
      return item.toString();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(width: 16.0),
        ],
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 51.0,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                onChanged: (T? item) {
                  if (item != null) {
                    onChanged(item);
                  }
                },
                value: value,
                selectedItemBuilder: (BuildContext context) {
                  return [
                    for (final item in items) //
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Center(
                          child: Text(
                            labelForItem(item),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                  ];
                },
                items: [
                  for (final item in items) //
                    DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        labelForItem(item),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

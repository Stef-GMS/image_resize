import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_resize/models/image_resize_output_format.dart';
import 'package:image_resize/viewmodels/image_resize_viewmodel.dart';
import 'package:image_resize/widgets/dropdown_entry.dart';
import 'package:image_resize/widgets/section_card.dart';
import 'package:image_resize/widgets/text_field_entry.dart';

class OutputSection extends ConsumerWidget {
  const OutputSection({
    super.key,
    required this.theme,
    required this.suffixController,
    required this.baseFilenameController,
  });

  final ThemeData theme;
  final TextEditingController suffixController;
  final TextEditingController baseFilenameController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageResizeViewModelProvider);
    final notifier = ref.read(imageResizeViewModelProvider.notifier);

    return SectionCard(
      title: 'Output',
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          IntrinsicWidth(
            child: DropdownEntry<ImageResizeOutputFormat>(
              theme: theme,
              label: 'Output Format',
              value: state.outputFormat,
              items: ImageResizeOutputFormat.values,
              onChanged: (value) => notifier.setOutputFormat(value),
            ),
          ),
          IntrinsicWidth(
            child: TextFieldEntry(
              theme: theme,
              label: 'Base Filename',
              controller: baseFilenameController,
              placeholder: 'e.g., MyPhoto',
              onChanged: (value) => notifier.setBaseFilename(value),
            ),
          ),
          IntrinsicWidth(
            child: TextFieldEntry(
              theme: theme,
              label: 'File Suffix',
              controller: suffixController,
              placeholder: 'e.g., _resized',
              onChanged: (value) => notifier.setSuffix(value),
            ),
          ),
        ],
      ),
    );
  }
}

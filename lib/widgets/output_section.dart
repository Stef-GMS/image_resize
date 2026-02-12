import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_resize/models/image_resize_output_format.dart';
import 'package:image_resize/viewmodels/image_resize_viewmodel.dart';
import 'package:image_resize/widgets/section_card.dart';
import 'package:image_resize/widgets/dropdown_entry.dart';
import 'package:image_resize/widgets/text_field_entry.dart';

class OutputSection extends ConsumerWidget {
  const OutputSection({
    super.key,
    required this.theme,
    required this.suffixController,
  });

  final ThemeData theme;
  final TextEditingController suffixController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageResizeViewModelProvider);
    final notifier = ref.read(imageResizeViewModelProvider.notifier);

    return SectionCard(
      title: 'Output',
      child: Column(
        children: [
          TextFieldEntry(
            theme: theme,
            label: 'File Suffix',
            controller: suffixController,
            placeholder: 'e.g., _resized',
            onChanged: (value) => notifier.setSuffix(value),
          ),
          const SizedBox(height: 16),
          DropdownEntry<ImageResizeOutputFormat>(
            theme: theme,
            label: 'Output Format',
            value: state.outputFormat,
            items: ImageResizeOutputFormat.values,
            onChanged: (value) => notifier.setOutputFormat(value),
          ),
        ],
      ),
    );
  }
}
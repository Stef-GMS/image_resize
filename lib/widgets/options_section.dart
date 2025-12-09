import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_resize/viewmodels/image_resize_viewmodel.dart';
import 'package:image_resize/widgets/checkbox_row.dart';
import 'package:image_resize/widgets/section_card.dart';

class OptionsSection extends ConsumerWidget {
  const OptionsSection({
    super.key,
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageResizeViewModelProvider);
    final notifier = ref.read(imageResizeViewModelProvider.notifier);

    return SectionCard(
      title: 'Options',
      child: Column(
        children: [
          CheckboxRow(
            label: 'Scale Proportionally',
            value: state.scaleProportionally,
            onChanged: (value) => notifier.setScaleProportionally(value!),
          ),
          const Divider(),
          CheckboxRow(
            label: 'Resample Image',
            value: state.resampleImage,
            onChanged: (value) => notifier.setResampleImage(value!),
          ),
          const Divider(),
          CheckboxRow(
            label: 'Include metadata (EXIF)',
            value: state.includeExif,
            onChanged: (value) => notifier.setIncludeExif(value!),
          ),
        ],
      ),
    );
  }
}

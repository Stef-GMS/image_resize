import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_resize/viewmodels/image_resize_viewmodel.dart';
import 'package:image_resize/widgets/custom_icon_button.dart';
import 'package:image_resize/widgets/section_card.dart';

class SourceSection extends ConsumerWidget {
  const SourceSection({
    super.key,
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageResizeViewModelProvider);
    final notifier = ref.read(imageResizeViewModelProvider.notifier);

    return SectionCard(
      title: 'Source',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CustomIconButton(
                  theme: theme,
                  icon: Icons.photo_library_outlined,
                  label: 'Device',
                  onPressed: notifier.pickImages,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomIconButton(
                  theme: theme,
                  icon: Icons.cloud_upload_outlined,
                  label: 'Cloud',
                  onPressed: notifier.pickFromCloud,
                ),
              ),
            ],
          ),
          if (state.selectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.selectedImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        state.selectedImages[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: state.resetOptionsOnClear,
                  onChanged: (value) => notifier.setResetOptionsOnClear(value ?? true),
                ),
                GestureDetector(
                  onTap: () => notifier.setResetOptionsOnClear(!state.resetOptionsOnClear),
                  child: Text(
                    'Reset Options',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: notifier.clearImageSelections,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      backgroundColor: theme.colorScheme.error.withAlpha(25),
                    ),
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_resize/models/cloud_storage_provider.dart';
import 'package:image_resize/models/device_picker_source.dart';
import 'package:image_resize/viewmodels/image_resize_viewmodel.dart';
import 'package:image_resize/widgets/custom_icon_button.dart';
import 'package:image_resize/widgets/dropdown_entry.dart';
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
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device Picker Source',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownEntry<DevicePickerSource>(
                    theme: theme,
                    value: state.devicePickerSource,
                    items: DevicePickerSource.values,
                    onChanged: (value) => notifier.setDevicePickerSource(value),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cloud Storage Provider',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownEntry<CloudStorageProvider>(
                    theme: theme,
                    value: state.cloudStorageProvider,
                    items: CloudStorageProvider.values,
                    onChanged: (value) => notifier.setCloudStorageProvider(value),
                  ),
                  // TODO: Add UI for multi_cloud_storage configuration if needed by the package
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomIconButton(
                  theme: theme,
                  icon: Icons.photo_library_outlined,
                  label: 'Select',
                  onPressed: notifier.pickFromDevice,
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
                    // TODO: Add a clear/remove button for individual images
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: notifier.clearImageSelections,
                style: ElevatedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  backgroundColor: theme.colorScheme.error.withAlpha(25),
                ),
                child: const Text('Clear All Selections'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_resize/models/save_destination.dart';
import 'package:image_resize/viewmodels/image_resize_viewmodel.dart';
import 'package:image_resize/widgets/dropdown_entry.dart';
import 'package:image_resize/widgets/section_card.dart';

class SaveLocationSection extends ConsumerWidget {
  const SaveLocationSection({
    super.key,
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageResizeViewModelProvider);
    final notifier = ref.read(imageResizeViewModelProvider.notifier);

    // On macOS, exclude Device Photos option - both gal and photo_manager crash
    final availableDestinations = Platform.isMacOS
        ? SaveDestination.values.where((d) => d != SaveDestination.devicePhotos).toList()
        : SaveDestination.values;

    // Ensure the current value is in the available destinations
    final currentDestination = availableDestinations.contains(state.saveDestination)
        ? state.saveDestination
        : SaveDestination.deviceFileSystem;

    return SectionCard(
      title: 'Save Location',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownEntry<SaveDestination>(
            theme: theme,
            label: 'Save To',
            value: currentDestination,
            items: availableDestinations,
            onChanged: (value) => notifier.setSaveDestination(value),
          ),
          const SizedBox(height: 12),
          if (state.saveDestination == SaveDestination.devicePhotos)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                'Images will be saved to your Photo Library',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: notifier.selectSaveDirectory,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: const Text('Choose Folder'),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Text(
                state.saveDirectory ?? 'No directory selected',
                style: theme.textTheme.bodyMedium,
                softWrap: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

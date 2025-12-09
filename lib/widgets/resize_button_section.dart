import 'dart:io'; // Import for Platform checks

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_resize/viewmodels/image_resize_viewmodel.dart';

class ResizeButtonSection extends ConsumerWidget {
  const ResizeButtonSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageResizeViewModelProvider);
    final notifier = ref.read(imageResizeViewModelProvider.notifier);

    if (state.hasResized) {
      return Column(
        children: [
          // Display "Save to Photos" only on iOS and Android
          if (Platform.isIOS || Platform.isAndroid)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: !state.isResizing ? notifier.saveToGallery : null,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: const Text('Save to Photos'),
              ),
            ),
          if (Platform.isIOS || Platform.isAndroid) const SizedBox(height: 16), // Add spacing if the above button is present
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: !state.isResizing ? notifier.saveToFolder : null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: const Text('Save to Folder...'),
            ),
          ),
        ],
      );
    } else {
      return ElevatedButton(
        onPressed: state.selectedImages.isNotEmpty && !state.isResizing
            ? notifier.resizeImages
            : null,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Theme.of(context).primaryColor,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: const Text('Resize'),
      );
    }
  }
}

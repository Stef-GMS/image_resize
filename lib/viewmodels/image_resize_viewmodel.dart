import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:image_resize/models/dimension_unit_type.dart';
import 'package:image_resize/models/image_resize_output_format.dart';
import 'package:image_resize/models/image_resize_state.dart';
import 'package:image_resize/services/file_system_service.dart';
import 'package:image_resize/services/image_processing_service.dart';
import 'package:image_resize/services/permission_service.dart';

final tagXResolution = img.exifTagNameToID['XResolution']!;
final tagYResolution = img.exifTagNameToID['YResolution']!;

final permissionServiceProvider = Provider((ref) => PermissionService());
final fileSystemServiceProvider = Provider((ref) => FileSystemService());

/// Provider to make the ImageResizeViewModel available to the UI.
final imageResizeViewModelProvider = NotifierProvider<ImageResizeViewModel, ImageResizeState>(
  ImageResizeViewModel.new,
);

/// The ViewModel (the Notifier) for the Image Resize screen.
///
/// This class manages the state ([ImageResizeState]) and business logic
/// for the screen. It interacts with services (like [ImageProcessingService])
/// and updates the state, which the UI then observes.
class ImageResizeViewModel extends Notifier<ImageResizeState> {
  @override
  ImageResizeState build() {
    return ImageResizeState.initial();
  }

  // region State Update Methods
  void setDimensionType(DimensionUnitType type) {
    state = state.copyWith(dimensionType: type);
    _updateSuffix();
  }

  void setMaintainAspectRatio(bool value) {
    state = state.copyWith(maintainAspectRatio: value);
  }

  void setWidth(String value) {
    state = state.copyWith(width: value);
    if (state.maintainAspectRatio && state.aspectRatio != null && value.isNotEmpty) {
      final width = double.tryParse(value);
      if (width != null) {
        final height = (width / state.aspectRatio!).round();
        state = state.copyWith(height: height.toString());
      }
    }
    _updateSuffix();
  }

  void setHeight(String value) {
    state = state.copyWith(height: value);
    if (state.maintainAspectRatio && state.aspectRatio != null && value.isNotEmpty) {
      final height = double.tryParse(value);
      if (height != null) {
        final width = (height * state.aspectRatio!).round();
        state = state.copyWith(width: width.toString());
      }
    }
    _updateSuffix();
  }

  void setResolution(String value) {
    state = state.copyWith(resolution: value);
    _updateSuffix();
  }

  void setSuffix(String value) {
    state = state.copyWith(suffix: value, userEditedSuffix: true);
  }

  void setScaleProportionally(bool value) {
    state = state.copyWith(scaleProportionally: value);
  }

  void setResampleImage(bool value) {
    state = state.copyWith(resampleImage: value);
  }

  void setIncludeExif(bool value) {
    state = state.copyWith(includeExif: value);
  }

  void setOutputFormat(ImageResizeOutputFormat format) {
    state = state.copyWith(outputFormat: format);
  }

  void dismissSnackbar() {
    state = state.copyWith(snackbarMessage: null);
  }
  // endregion

  // region Image Picking Logic
  Future<void> pickImages() async {
    final imagePicker = ImagePicker();
    final pickedFiles = await imagePicker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      await _processPickedFiles(pickedFiles.map((f) => f.path).toList());
    }
  }

  Future<void> pickFromCloud() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      //initialDirectory: imageFile.path,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'bmp',
        'webp',
      ],
    );
    if (result != null && result.files.isNotEmpty) {
      await _processPickedFiles(result.paths.where((p) => p != null).cast<String>().toList());
    }
  }

  Future<void> _processPickedFiles(List<String> paths) async {
    final firstImageFile = File(paths.first);
    final fileBytes = await firstImageFile.readAsBytes();
    final image = img.decodeImage(fileBytes);

    if (image != null) {
      final exifData = image.exif;
      final xResolution = exifData.getTag(tagXResolution);
      final resolution = xResolution?.toInt().toString() ?? '72';

      state = state.copyWith(
        firstImage: image,
        aspectRatio: image.width / image.height,
        width: image.width.toString(),
        height: image.height.toString(),
        resolution: resolution,
        userEditedSuffix: false,
      );
      _updateSuffix();
    }

    state = state.copyWith(
      selectedImages: [...state.selectedImages, ...paths.map((p) => File(p))],
      saveDirectory: File(paths.first).parent.path,
    );
  }

  void clearImageSelections() {
    state = state.copyWith(
      selectedImages: [],
      saveDirectory: null,
      aspectRatio: null,
      firstImage: null,
      width: '',
      height: '',
      suffix: '',
      userEditedSuffix: false,
      resizedImagesData: null,
      hasResized: false,
    );
  }
  // endregion

  // region Image Resizing and Saving Logic
  Future<void> resizeImages() async {
    final imageProcessingService = ref.read(imageProcessingServiceProvider);
    final permissionService = ref.read(permissionServiceProvider);
    final fileSystemService = ref.read(fileSystemServiceProvider);

    if (state.selectedImages.isEmpty) {
      state = state.copyWith(snackbarMessage: 'Please select at least one image.');
      return;
    }

    if (state.width.isEmpty || state.height.isEmpty) {
      state = state.copyWith(snackbarMessage: 'Please enter width and height.');
      return;
    }

    final widthInput = double.tryParse(state.width);
    final heightInput = double.tryParse(state.height);

    if (widthInput == null || heightInput == null) {
      state = state.copyWith(snackbarMessage: 'Invalid width or height.');
      return;
    }

    String? savePath = state.saveDirectory;
    //print('Save path from state: $savePath');

    // If no save directory is set, try to get a default one
    if (savePath == null || savePath.isEmpty) {
      final defaultDownloads = await fileSystemService.getDownloadsDirectoryPath();
      if (defaultDownloads != null) {
        savePath = defaultDownloads;
        // Update state with the default directory
        state = state.copyWith(saveDirectory: savePath);
      } else {
        final selectedPath = await selectSaveDirectory();
        savePath = selectedPath;
        if (savePath == null) {
          state = state.copyWith(snackbarMessage: 'Please select a save directory.');
          return;
        }
      }
    }

    // Verify the directory exists and is writable
    final saveDir = Directory(savePath);
    if (!await saveDir.exists()) {
      try {
        await saveDir.create(recursive: true);
      } catch (e) {
        state = state.copyWith(snackbarMessage: 'Error: Cannot access save directory: $e');
        return;
      }
    }

    // Test if we can write to this directory (important for sandboxed apps and iCloud)
    try {
      final testFile = File('$savePath/.test_write_${DateTime.now().millisecondsSinceEpoch}');
      await testFile.writeAsString('test');
      await testFile.delete();
      //print('Save directory is writable: $savePath');
    } catch (e) {
      //print('Cannot write to directory: $savePath, error: $e');
      // Ask user to select a writable directory
      state = state.copyWith(
        snackbarMessage: 'Cannot save to this location. Please choose a save folder.',
      );
      final selectedPath = await selectSaveDirectory();
      if (selectedPath == null) {
        state = state.copyWith(
          snackbarMessage: 'Please select a save directory.',
          isResizing: false,
        );
        return;
      }
      savePath = selectedPath;
    }

    if (await permissionService.requestStoragePermission()) {
      state = state.copyWith(isResizing: true, overwriteAll: false); // Reset overwriteAll
      //print('inside if (await permissionService.requestStoragePermission()) ');

      for (final imageFile in state.selectedImages) {
        final newFileName = fileSystemService.getNewFileName(
          imageFile.path,
          widthInput.round(),
          heightInput.round(),
          state.suffix,
          state.outputFormat,
        );
        final newPath = '$savePath/$newFileName';

        final parentDir = File(newPath).parent;
        if (!await parentDir.exists()) {
          try {
            await parentDir.create(recursive: true);
          } catch (e) {
            state = state.copyWith(snackbarMessage: 'Error: Could not create save directory: $e');
            continue; // Skip this image if directory can't be created
          }
        }

        // Overwrite logic - for now, if file exists and not overwriteAll, then skip.
        // Dialog handling is in UI.
        if (!state.overwriteAll && await File(newPath).exists()) {
          state = state.copyWith(snackbarMessage: 'File $newFileName already exists. Skipping.');
          continue;
        }

        // To handle overwrite, explicitly delete if we decide to overwrite.
        if (state.overwriteAll && await File(newPath).exists()) {
          try {
            await File(newPath).delete();
          } catch (e) {
            state = state.copyWith(
              snackbarMessage: 'Error: Could not delete existing file for overwrite: $e',
            );
            continue; // Skip this image if deletion fails
          }
        }

        final image = img.decodeImage(await imageFile.readAsBytes());
        if (image == null) {
          state = state.copyWith(snackbarMessage: 'Error decoding image: ${imageFile.path}');
          continue;
        }

        final (width, height) = _calculatePixelDimensions();

        final originalBytes = await imageFile.readAsBytes(); // Re-read for service

        final resizedBytes = await imageProcessingService.resizeImage(
          imageData: originalBytes,
          newWidth: width,
          newHeight: height,
          newResolution: int.tryParse(state.resolution) ?? 72,
        );

        final resizedImage = img.decodeImage(resizedBytes);
        if (resizedImage == null) {
          state = state.copyWith(
            snackbarMessage: 'Error decoding resized image: ${imageFile.path}',
          );
          continue;
        }

        final resolution = int.tryParse(state.resolution) ?? 72;

        final exif = image.exif;
        exif.imageIfd[tagXResolution] = img.IfdValueRational(resolution, 1);
        exif.imageIfd[tagYResolution] = img.IfdValueRational(resolution, 1);
        resizedImage.exif = exif;

        List<int> encodedImage;
        final outputFormat = switch (state.outputFormat) {
          ImageResizeOutputFormat.sameAsOriginal =>
            imageFile.path.split('.').last.toLowerCase() == 'png' ? 'png' : 'jpg',
          _ => state.outputFormat.name,
        };
        if (outputFormat == 'jpg') {
          encodedImage = img.encodeJpg(resizedImage);
        } else {
          encodedImage = img.PngEncoder(
            filter: img.PngFilter.paeth,
            level: 6,
            pixelDimensions: img.PngPhysicalPixelDimensions.dpi(resolution),
          ).encode(resizedImage); // Use resizedImage here
        }

        await File(newPath).writeAsBytes(encodedImage);
      }
      state = state.copyWith(
        isResizing: false,
        hasResized: false, // Reset hasResized after saving
        resizedImagesData: null,
        snackbarMessage: 'Images resized and saved to $savePath',
      );
    }
  }

  // Helper for selectSaveDirectory
  Future<String?> selectSaveDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath(
      initialDirectory: state.saveDirectory,
    );
    //print(result);
    if (result != null) {
      state = state.copyWith(saveDirectory: result);
      return result;
    }
    return null;
  }

  // endregion
  (int, int) _calculatePixelDimensions() {
    if (state.firstImage == null) return (0, 0);

    final widthInput = double.tryParse(state.width) ?? 0;
    final heightInput = double.tryParse(state.height) ?? 0;
    var resolution = double.tryParse(state.resolution) ?? 72.0;

    switch (state.dimensionType) {
      case DimensionUnitType.percent:
        return (
          (state.firstImage!.width * widthInput / 100).round(),
          (state.firstImage!.height * heightInput / 100).round(),
        );
      case DimensionUnitType.inches:
        return ((widthInput * resolution).round(), (heightInput * resolution).round());
      case DimensionUnitType.cm:
        return (
          (widthInput * resolution / 2.54).round(),
          (heightInput * resolution / 2.54).round(),
        );
      case DimensionUnitType.mm:
        return (
          (widthInput * resolution / 25.4).round(),
          (heightInput * resolution / 25.4).round(),
        );
      case DimensionUnitType.pixels:
        return (widthInput.round(), heightInput.round());
    }
  }

  void _updateSuffix() {
    if (!state.userEditedSuffix) {
      final (width, height) = _calculatePixelDimensions();
      final resolution = int.tryParse(state.resolution) ?? 72;

      if (width > 0 && height > 0) {
        state = state.copyWith(suffix: '_${width}x${height}_$resolution');
      } else {
        state = state.copyWith(suffix: '');
      }
    }
  }

  //endregion
}

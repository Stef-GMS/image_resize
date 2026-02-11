import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:image_resize/models/dimension_unit_type.dart';
import 'package:image_resize/models/image_resize_output_format.dart';
import 'package:image_resize/models/image_resize_state.dart';
import 'package:image_resize/models/save_destination.dart';
import 'package:image_resize/services/file_system_service.dart';
import 'package:image_resize/services/image_processing_service.dart';
import 'package:image_resize/services/permission_service.dart';
import 'package:path_provider/path_provider.dart';

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

    // When switching to percentage, set default to 100%
    if (type == DimensionUnitType.percent && state.firstImage != null) {
      state = state.copyWith(
        width: '100',
        height: '100',
      );
    }

    _updateSuffix();
  }

  void setMaintainAspectRatio(bool value) {
    state = state.copyWith(maintainAspectRatio: value);
  }

  void setWidth(String value) {
    state = state.copyWith(width: value);
    if (state.maintainAspectRatio && state.aspectRatio != null) {
      if (value.isNotEmpty) {
        final width = double.tryParse(value);
        if (width != null) {
          // For percentage, both width and height should be the same value
          // For other units, calculate based on aspect ratio
          final height = state.dimensionType == DimensionUnitType.percent
              ? width
              : (width / state.aspectRatio!);
          state = state.copyWith(height: height.round().toString());
        }
      } else {
        // Clear height when width is cleared
        state = state.copyWith(height: '');
      }
    }
    _updateSuffix();
  }

  void setHeight(String value) {
    state = state.copyWith(height: value);
    if (state.maintainAspectRatio && state.aspectRatio != null) {
      if (value.isNotEmpty) {
        final height = double.tryParse(value);
        if (height != null) {
          // For percentage, both width and height should be the same value
          // For other units, calculate based on aspect ratio
          final width = state.dimensionType == DimensionUnitType.percent
              ? height
              : (height * state.aspectRatio!);
          state = state.copyWith(width: width.round().toString());
        }
      } else {
        // Clear width when height is cleared
        state = state.copyWith(width: '');
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

  void setSaveDestination(SaveDestination destination) {
    state = state.copyWith(saveDestination: destination);
  }

  void setBaseFilename(String value) {
    state = state.copyWith(baseFilename: value);
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
      // Create a map of temp paths to simplified filenames
      // Since image_picker doesn't preserve original filenames on iOS,
      // we'll use a sequential naming pattern
      final originalNames = <String, String>{};
      int counter = 1;
      for (final file in pickedFiles) {
        // Extract the file extension from the temp file
        final extension = file.path.split('.').last;
        // Create a simple filename like IMG_0001.jpg, IMG_0002.jpg, etc.
        final simpleName = 'IMG_${counter.toString().padLeft(4, '0')}.$extension';
        originalNames[file.path] = simpleName;
        counter++;
      }
      await _processPickedFiles(
        pickedFiles.map((f) => f.path).toList(),
        originalNames,
      );
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
      // Create a map of paths to original filenames
      final originalNames = <String, String>{};
      for (final file in result.files) {
        if (file.path != null) {
          originalNames[file.path!] = file.name;
        }
      }
      await _processPickedFiles(
        result.paths.where((p) => p != null).cast<String>().toList(),
        originalNames,
      );
    }
  }

  Future<void> _processPickedFiles(List<String> paths, [Map<String, String>? originalNames]) async {
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
      originalFileNames: {...state.originalFileNames, ...?originalNames},
      saveDirectory: File(paths.first).parent.path,
      baseFilename: '', // Clear base filename when picking new images
    );
  }

  void clearImageSelections() {
    state = state.copyWith(
      selectedImages: [],
      originalFileNames: {},
      saveDirectory: null,
      saveDestination: SaveDestination.deviceFileSystem,
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

    final saveToPhotos = state.saveDestination == SaveDestination.devicePhotos;

    // On macOS, if trying to save to Photos, block it due to known crash issue
    if (Platform.isMacOS && saveToPhotos) {
      state = state.copyWith(
        snackbarMessage:
            'Saving to Photos app is not supported on macOS due to a Flutter limitation. Please choose "Device File System" or "Cloud" instead.',
      );
      return;
    }

    // For file system / cloud saving, resolve the save path
    String? savePath;
    if (!saveToPhotos) {
      savePath = state.saveDirectory;

      // If no save directory is set, try to get a default one
      if (savePath == null || savePath.isEmpty) {
        final defaultDownloads = await fileSystemService.getDownloadsDirectoryPath();
        if (defaultDownloads != null) {
          savePath = defaultDownloads;
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
      } catch (e) {
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
    }

    // Request appropriate permission based on save destination
    final hasPermission = saveToPhotos
        ? await permissionService.requestPhotoLibraryPermission()
        : await permissionService.requestStoragePermission();

    if (hasPermission) {
      state = state.copyWith(isResizing: true, overwriteAll: false);

      // Calculate actual pixel dimensions based on unit type
      final (pixelWidth, pixelHeight) = _calculatePixelDimensions();

      for (final imageFile in state.selectedImages) {
        // Get original filename if available (for images picked from device photos)
        final originalFileName = state.originalFileNames[imageFile.path];
        final newFileName = fileSystemService.getNewFileName(
          imageFile.path,
          originalFileName,
          state.baseFilename.isNotEmpty ? state.baseFilename : null,
          pixelWidth,
          pixelHeight,
          state.suffix,
          state.outputFormat,
        );

        // File system overwrite checks (only for non-photo-library saving)
        if (!saveToPhotos && savePath != null) {
          final newPath = '$savePath/$newFileName';

          final parentDir = File(newPath).parent;
          if (!await parentDir.exists()) {
            try {
              await parentDir.create(recursive: true);
            } catch (e) {
              state = state.copyWith(snackbarMessage: 'Error: Could not create save directory: $e');
              continue;
            }
          }

          if (!state.overwriteAll && await File(newPath).exists()) {
            state = state.copyWith(snackbarMessage: 'File $newFileName already exists. Skipping.');
            continue;
          }

          if (state.overwriteAll && await File(newPath).exists()) {
            try {
              await File(newPath).delete();
            } catch (e) {
              state = state.copyWith(
                snackbarMessage: 'Error: Could not delete existing file for overwrite: $e',
              );
              continue;
            }
          }
        }

        final image = img.decodeImage(await imageFile.readAsBytes());
        if (image == null) {
          state = state.copyWith(snackbarMessage: 'Error decoding image: ${imageFile.path}');
          continue;
        }

        final originalBytes = await imageFile.readAsBytes();

        final resizedBytes = await imageProcessingService.resizeImage(
          imageData: originalBytes,
          newWidth: pixelWidth,
          newHeight: pixelHeight,
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
          ).encode(resizedImage);
        }

        // Save based on destination
        if (saveToPhotos) {
          // gal requires a file path, so write to temp first
          final tempDir = await getTemporaryDirectory();
          final tempPath = '${tempDir.path}/$newFileName';
          await File(tempPath).writeAsBytes(encodedImage);

          try {
            await Gal.putImage(tempPath);
          } catch (e) {
            // On macOS, Flutter has a known issue loading Info.plist which can
            // cause gal to crash. Prompt user to choose a different save location.
            if (Platform.isMacOS) {
              // Clean up temp file
              try {
                await File(tempPath).delete();
              } catch (_) {}

              state = state.copyWith(
                isResizing: false,
                snackbarMessage:
                    'Unable to save to Photos app. Please choose a different save location.',
              );
              return;
            } else {
              rethrow;
            }
          }

          // Clean up temp file
          try {
            await File(tempPath).delete();
          } catch (_) {}
        } else {
          final newPath = '$savePath/$newFileName';
          await File(newPath).writeAsBytes(encodedImage);
        }
      }

      final successMessage = saveToPhotos
          ? 'Images resized and saved to Photo Library'
          : 'Images resized and saved to $savePath';

      state = state.copyWith(
        isResizing: false,
        hasResized: false,
        resizedImagesData: null,
        snackbarMessage: successMessage,
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

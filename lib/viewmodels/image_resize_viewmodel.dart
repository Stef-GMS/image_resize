import 'dart:io';

import 'package:exif/exif.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:image_resize/models/dimension_unit_type.dart';
import 'package:image_resize/models/file_conflict_info.dart';
import 'package:image_resize/models/file_conflict_state.dart';
import 'package:image_resize/models/image_resize_output_format.dart';
import 'package:image_resize/models/image_resize_state.dart';
import 'package:image_resize/models/save_destination.dart';
import 'package:image_resize/services/file_system_service.dart';
import 'package:image_resize/services/image_processing_service.dart';
import 'package:image_resize/services/permission_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

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
    final oldType = state.dimensionType;
    state = state.copyWith(dimensionType: type);

    // When switching dimension types, convert current values to new unit type
    if (state.firstImage != null && state.width.isNotEmpty && state.height.isNotEmpty) {
      final resolution = int.tryParse(state.resolution) ?? 72;

      // First, calculate the current pixel dimensions based on the OLD unit type
      final (currentPixelWidth, currentPixelHeight) = _calculatePixelDimensionsForType(
        oldType,
        double.tryParse(state.width) ?? 0,
        double.tryParse(state.height) ?? 0,
        resolution.toDouble(),
      );

      // Then convert those pixel dimensions to the NEW unit type
      switch (type) {
        case DimensionUnitType.percent:
          // Convert to percentage of original image
          final widthPercent = (currentPixelWidth / state.firstImage!.width * 100).toStringAsFixed(
            2,
          );
          final heightPercent = (currentPixelHeight / state.firstImage!.height * 100)
              .toStringAsFixed(2);
          state = state.copyWith(
            width: widthPercent,
            height: heightPercent,
          );
          break;
        case DimensionUnitType.pixels:
          // Already have pixel dimensions
          state = state.copyWith(
            width: currentPixelWidth.round().toString(),
            height: currentPixelHeight.round().toString(),
          );
          break;
        case DimensionUnitType.inches:
          // Convert pixels to inches
          final widthInches = (currentPixelWidth / resolution).toStringAsFixed(2);
          final heightInches = (currentPixelHeight / resolution).toStringAsFixed(2);
          state = state.copyWith(
            width: widthInches,
            height: heightInches,
          );
          break;
        case DimensionUnitType.cm:
          // Convert pixels to cm (1 inch = 2.54 cm)
          final widthCm = (currentPixelWidth / resolution * 2.54).toStringAsFixed(2);
          final heightCm = (currentPixelHeight / resolution * 2.54).toStringAsFixed(2);
          state = state.copyWith(
            width: widthCm,
            height: heightCm,
          );
          break;
        case DimensionUnitType.mm:
          // Convert pixels to mm (1 inch = 25.4 mm)
          final widthMm = (currentPixelWidth / resolution * 25.4).toStringAsFixed(2);
          final heightMm = (currentPixelHeight / resolution * 25.4).toStringAsFixed(2);
          state = state.copyWith(
            width: widthMm,
            height: heightMm,
          );
          break;
      }
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

  void setResetOptionsOnClear(bool value) {
    state = state.copyWith(resetOptionsOnClear: value);
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

  void setFileConflictResolved() {
    state = state.copyWith(
      fileConflictState: FileConflictState.none,
      conflictInfo: null,
    );
  }

  void setFileConflictOverwrite() {
    state = state.copyWith(fileConflictState: FileConflictState.overwrite);
  }

  void setFileConflictAddSequence() {
    state = state.copyWith(fileConflictState: FileConflictState.addSequence);
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

      for (var i = 0; i < pickedFiles.length; i++) {
        // Extract the file extension from the temp file
        final extension = pickedFiles[i].path.split('.').last;
        // Create a simple filename like IMG_0001.jpg, IMG_0002.jpg, etc.
        final simpleName = 'IMG_${(i + 1).toString().padLeft(4, '0')}.$extension';
        originalNames[pickedFiles[i].path] = simpleName;
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
      // For cloud/filesystem picks, don't pass originalNames
      // This will preserve the actual filename from the path
      await _processPickedFiles(
        result.paths.where((p) => p != null).cast<String>().toList(),
      );
    }
  }

  Future<void> _processPickedFiles(List<String> paths, [Map<String, String>? originalNames]) async {
    final firstImageFile = File(paths.first);
    final fileBytes = await firstImageFile.readAsBytes();

    // Read EXIF data using the exif package (more reliable than image package)
    String resolution = '72';
    String? exifFilename;

    try {
      final exifData = await readExifFromBytes(fileBytes);

      if (exifData.isNotEmpty) {
        print('DEBUG: EXIF data found with ${exifData.length} tags');

        // Try to extract original filename from EXIF
        final imageDescription = exifData['Image ImageDescription'];
        final documentName = exifData['Image DocumentName'];

        if (imageDescription != null) {
          exifFilename = imageDescription.printable;
          print('DEBUG: Found filename in ImageDescription: $exifFilename');
        } else if (documentName != null) {
          exifFilename = documentName.printable;
          print('DEBUG: Found filename in DocumentName: $exifFilename');
        }

        // Try different EXIF tags for resolution
        final xRes = exifData['EXIF XResolution'] ?? exifData['Image XResolution'];
        final yRes = exifData['EXIF YResolution'] ?? exifData['Image YResolution'];

        print('DEBUG: XResolution tag = $xRes');
        print('DEBUG: YResolution tag = $yRes');

        if (xRes != null) {
          // EXIF resolution is stored as "300/1" or similar
          final resString = xRes.printable;
          print('DEBUG: XResolution printable = $resString');

          if (resString.contains('/')) {
            final parts = resString.split('/');
            if (parts.length == 2) {
              final numerator = int.tryParse(parts[0].trim());
              final denominator = int.tryParse(parts[1].trim());
              if (numerator != null && denominator != null && denominator != 0) {
                resolution = (numerator / denominator).round().toString();
                print('DEBUG: Calculated DPI = $resolution');
              }
            }
          } else {
            // Try parsing as direct number
            final dpi = int.tryParse(resString);
            if (dpi != null) {
              resolution = dpi.toString();
              print('DEBUG: Direct DPI = $resolution');
            }
          }
        }
      } else {
        print('DEBUG: No EXIF data found in image');
      }
    } catch (e) {
      print('DEBUG: Error reading EXIF: $e');
    }

    // Decode the image
    final image = img.decodeImage(fileBytes);

    if (image != null) {
      // Only reset dimensions if resetOptionsOnClear is true
      // Otherwise, keep the user's current dimension values
      if (state.resetOptionsOnClear) {
        state = state.copyWith(
          firstImage: image,
          aspectRatio: image.width / image.height,
          width: image.width.toString(),
          height: image.height.toString(),
          resolution: resolution,
          userEditedSuffix: false,
        );
      } else {
        // Keep current width/height values, only update image and aspect ratio
        state = state.copyWith(
          firstImage: image,
          aspectRatio: image.width / image.height,
          resolution: resolution,
          userEditedSuffix: false,
        );
      }
      _updateSuffix();
    }

    // Determine the base filename to use
    String baseFilename = '';

    if (originalNames != null) {
      // Picking from device photos - try EXIF filename first
      if (exifFilename != null && exifFilename.isNotEmpty) {
        // Remove extension from EXIF filename if present
        if (exifFilename.contains('.')) {
          baseFilename = exifFilename.substring(0, exifFilename.lastIndexOf('.'));
        } else {
          baseFilename = exifFilename;
        }
        print('DEBUG: Setting base filename from EXIF: $baseFilename');
      }
      // If no EXIF filename, baseFilename stays empty and sequential naming (IMG_0001) will be used
    } else {
      // Picking from cloud/filesystem - use actual filename from path (ignore EXIF)
      print('DEBUG: Full path = ${paths.first}');
      final actualFilename = paths.first.split('/').last;
      print('DEBUG: Extracted filename = $actualFilename');
      if (actualFilename.contains('.')) {
        baseFilename = actualFilename.substring(0, actualFilename.lastIndexOf('.'));
      } else {
        baseFilename = actualFilename;
      }
      print('DEBUG: Setting base filename from file path: $baseFilename');
    }

    // Only set saveDirectory when picking from filesystem (not from Photos)
    // originalNames == null means filesystem pick
    final saveDir = originalNames == null ? File(paths.first).parent.path : null;

    state = state.copyWith(
      selectedImages: [...state.selectedImages, ...paths.map((p) => File(p))],
      originalFileNames: {...state.originalFileNames, ...?originalNames},
      baseFilename: baseFilename,
      saveDirectory: saveDir,
    );
  }

  void clearImageSelections() {
    if (state.resetOptionsOnClear) {
      // Reset everything to initial state
      state = ImageResizeState.initial();
    } else {
      // Only clear images and related fields, keep user settings (width, height, dimension type, etc.)
      // But always clear saveDirectory per user request
      state = state.copyWith(
        selectedImages: [],
        originalFileNames: {},
        aspectRatio: null,
        firstImage: null,
        baseFilename: '',
        resizedImagesData: null,
        hasResized: false,
        saveDirectory: null,
      );
    }
  }
  // endregion

  // region Image Resizing and Saving Logic

  /// Check if any files would be overwritten and return the list of conflicting filenames
  Future<List<String>> _checkFileConflicts(
    String savePath,
    FileSystemService fileSystemService,
  ) async {
    final conflicts = <String>[];

    for (final imageFile in state.selectedImages) {
      final originalFileName = state.originalFileNames[imageFile.path];
      final newFileName = fileSystemService.getNewFileName(
        imageFile.path,
        originalFileName,
        state.baseFilename.isNotEmpty ? state.baseFilename : null,
        state.suffix,
        state.outputFormat,
      );

      final newPath = '$savePath/$newFileName';
      if (await File(newPath).exists()) {
        conflicts.add(newFileName);
      }
    }

    return conflicts;
  }

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

    // For file system / cloud saving, resolve the save path
    String? savePath;
    if (!saveToPhotos) {
      savePath = state.saveDirectory;

      // If no save directory is set, prompt user to select one
      if (savePath == null || savePath.isEmpty) {
        state = state.copyWith(snackbarMessage: 'Please select a save directory.');
        return;
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
    print('DEBUG: Requesting permission for saveToPhotos=$saveToPhotos');
    bool hasPermission = false;
    try {
      hasPermission = saveToPhotos
          ? await permissionService.requestPhotoLibraryPermission()
          : await permissionService.requestStoragePermission();

      print('DEBUG: Permission granted: $hasPermission');

      if (!hasPermission) {
        state = state.copyWith(
          snackbarMessage: saveToPhotos
              ? 'Photo Library permission denied. Please grant permission in System Settings.'
              : 'Storage permission denied.',
        );
        return;
      }
    } catch (e, stackTrace) {
      print('ERROR: Permission request failed: $e');
      print('STACK TRACE: $stackTrace');
      state = state.copyWith(
        snackbarMessage: 'Permission request failed: ${e.toString()}',
      );
      return;
    }

    // Check for file conflicts before starting resize (only for file system saves)
    // Skip check if user has already made a choice
    if (!saveToPhotos && savePath != null && state.fileConflictState == FileConflictState.none) {
      final conflicts = await _checkFileConflicts(savePath, fileSystemService);
      if (conflicts.isNotEmpty) {
        // Set conflict state to pending and store conflict info
        state = state.copyWith(
          fileConflictState: FileConflictState.pending,
          conflictInfo: FileConflictInfo(
            filename: conflicts.length == 1 ? conflicts.first : '${conflicts.length} files',
            fullPath: savePath,
          ),
        );
        return; // Wait for user to resolve conflict
      }
    }

    if (hasPermission) {
      state = state.copyWith(isResizing: true);

      // Calculate actual pixel dimensions based on unit type
      final (pixelWidth, pixelHeight) = _calculatePixelDimensions();

      for (final imageFile in state.selectedImages) {
        // Get original filename if available (for images picked from device photos)
        final originalFileName = state.originalFileNames[imageFile.path];
        final newFileName = fileSystemService.getNewFileName(
          imageFile.path,
          originalFileName,
          state.baseFilename.isNotEmpty ? state.baseFilename : null,
          state.suffix,
          state.outputFormat,
        );

        // Ensure save directory exists (only for non-photo-library saving)
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
          // Write to temp file first
          final tempDir = await getTemporaryDirectory();
          final tempPath = '${tempDir.path}/$newFileName';
          await File(tempPath).writeAsBytes(encodedImage);

          try {
            if (Platform.isMacOS) {
              // Use photo_manager on macOS (uses PhotoKit)
              print('DEBUG: Attempting to save to macOS Photo Library: $tempPath');
              print('DEBUG: Filename: $newFileName');
              await PhotoManager.editor.saveImageWithPath(
                tempPath,
                title: newFileName,
              );
              print('DEBUG: Successfully saved to Photo Library');
            } else {
              // Use gal on iOS/Android
              await Gal.putImage(tempPath);
            }
          } catch (e, stackTrace) {
            // Clean up temp file
            try {
              await File(tempPath).delete();
            } catch (_) {}

            print('ERROR: Failed to save to Photos app: $e');
            print('STACK TRACE: $stackTrace');

            state = state.copyWith(
              isResizing: false,
              snackbarMessage: 'Unable to save to Photos app: ${e.toString()}',
            );
            return;
          }

          // Clean up temp file
          try {
            await File(tempPath).delete();
          } catch (_) {}
        } else {
          // Determine final filename (with sequence number if needed)
          String finalFileName = newFileName;
          if (state.fileConflictState == FileConflictState.addSequence) {
            finalFileName = await fileSystemService.getUniqueFileName(savePath!, newFileName);
          }

          final newPath = '$savePath/$finalFileName';

          // Delete existing file if overwrite mode is enabled
          if (state.fileConflictState == FileConflictState.overwrite &&
              await File(newPath).exists()) {
            try {
              await File(newPath).delete();
            } catch (e) {
              state = state.copyWith(
                snackbarMessage: 'Error: Could not delete existing file for overwrite: $e',
              );
              continue;
            }
          }

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
        fileConflictState: FileConflictState.none,
        conflictInfo: null,
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

  /// Helper method to calculate pixel dimensions for a specific dimension type
  /// Used when converting between dimension types
  (double, double) _calculatePixelDimensionsForType(
    DimensionUnitType type,
    double widthInput,
    double heightInput,
    double resolution,
  ) {
    if (state.firstImage == null) return (0, 0);

    switch (type) {
      case DimensionUnitType.percent:
        return (
          state.firstImage!.width * widthInput / 100,
          state.firstImage!.height * heightInput / 100,
        );
      case DimensionUnitType.inches:
        return (widthInput * resolution, heightInput * resolution);
      case DimensionUnitType.cm:
        return (
          widthInput * resolution / 2.54,
          heightInput * resolution / 2.54,
        );
      case DimensionUnitType.mm:
        return (
          widthInput * resolution / 25.4,
          heightInput * resolution / 25.4,
        );
      case DimensionUnitType.pixels:
        return (widthInput, heightInput);
    }
  }

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

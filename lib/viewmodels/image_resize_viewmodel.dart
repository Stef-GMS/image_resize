import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart'; // For saving to gallery
import 'package:image_resize/models/cloud_storage_provider.dart';
import 'package:image_resize/models/device_picker_source.dart';
import 'package:image_resize/models/dimension_unit_type.dart';
import 'package:image_resize/models/image_resize_output_format.dart';
import 'package:image_resize/models/image_resize_state.dart';
import 'package:image_resize/services/image_processing_service.dart';


final tagXResolution = img.exifTagNameToID['XResolution']!;
final tagYResolution = img.exifTagNameToID['YResolution']!;

/// Provider to make the ImageResizeViewModel available to the UI.
final imageResizeViewModelProvider =
    NotifierProvider<ImageResizeViewModel, ImageResizeState>(
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
  void setDevicePickerSource(DevicePickerSource source) {
    state = state.copyWith(devicePickerSource: source);
  }

  void setCloudStorageProvider(CloudStorageProvider provider) {
    state = state.copyWith(cloudStorageProvider: provider);
  }

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
  Future<void> pickFromDevice() async {
    switch (state.devicePickerSource) {
      case DevicePickerSource.gallery:
        await _pickFromGallery();
        break;
      case DevicePickerSource.fileSystem:
        await _pickFromFileSystem();
        break;
    }
  }

  Future<void> pickFromCloud() async {
    switch (state.cloudStorageProvider) {
      case CloudStorageProvider.iCloudDrive:
        await _pickFromFileSystem(); // FilePicker supports iCloud Drive on iOS
        break;
      case CloudStorageProvider.googleDrive:
        // TODO: Implement Google Drive picking using multi_cloud_storage
        state = state.copyWith(snackbarMessage: 'Google Drive picker not yet implemented.');
        break;
      case CloudStorageProvider.dropbox:
        // TODO: Implement Dropbox picking using multi_cloud_storage
        state = state.copyWith(snackbarMessage: 'Dropbox picker not yet implemented.');
        break;
    }
  }

  Future<void> _pickFromGallery() async {
    final imagePicker = ImagePicker();
    final pickedFiles = await imagePicker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      await _processPickedFiles(pickedFiles.map((f) => f.path).toList());
    }
  }

  Future<void> _pickFromFileSystem() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
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
    if (state.selectedImages.isEmpty) {
      state = state.copyWith(snackbarMessage: 'Please select at least one image.');
      return;
    }
    if (state.width.isEmpty || state.height.isEmpty) {
      state = state.copyWith(snackbarMessage: 'Please enter width and height.');
      return;
    }

    state = state.copyWith(isResizing: true);

    final imageProcessingService = ref.read(imageProcessingServiceProvider);
    final List<Uint8List> processedImages = [];

    for (final imageFile in state.selectedImages) {
      final (width, height) = _calculatePixelDimensions();
      final originalBytes = await imageFile.readAsBytes();

      final resizedBytes = await imageProcessingService.resizeImage(
        imageData: originalBytes,
        newWidth: width,
        newHeight: height,
      );
      processedImages.add(resizedBytes);
    }

    state = state.copyWith(
      isResizing: false,
      hasResized: true,
      resizedImagesData: processedImages,
      snackbarMessage: 'Images resized. Ready to save.',
    );
  }

  Future<void> saveToGallery() async {
    if (!state.hasResized || state.resizedImagesData == null) {
      state = state.copyWith(snackbarMessage: 'No images have been resized yet.');
      return;
    }
    state = state.copyWith(isResizing: true); // Re-using for save operation indication

    for (int i = 0; i < state.resizedImagesData!.length; i++) {
      final resizedBytes = state.resizedImagesData![i];
      final originalImagePath = state.selectedImages[i].path;
      final newFileName = _getNewFileName(originalImagePath, state.suffix);

      await ImageGallerySaver.saveImage(
        resizedBytes,
        name: newFileName,
        quality: 100, // Assuming full quality for saving
      );
    }

    state = state.copyWith(
      isResizing: false,
      snackbarMessage: 'Images saved to Photo Gallery.',
      hasResized: false,
      resizedImagesData: null,
    );
  }

  Future<void> saveToFolder() async {
    if (!state.hasResized || state.resizedImagesData == null) {
      state = state.copyWith(snackbarMessage: 'No images have been resized yet.');
      return;
    }

    String? savePath = state.saveDirectory;
    if (savePath == null) {
      await selectSaveDirectory();
      savePath = state.saveDirectory;
      if (savePath == null) {
        state = state.copyWith(
          snackbarMessage: 'Please select a save directory.',
        );
        return;
      }
    }

    state = state.copyWith(isResizing: true); // Re-using for save operation indication

    for (int i = 0; i < state.resizedImagesData!.length; i++) {
      final resizedBytes = state.resizedImagesData![i];
      final originalImagePath = state.selectedImages[i].path;
      final newFileName = _getNewFileName(originalImagePath, state.suffix);
      final newPath = '$savePath/$newFileName';

      final parentDir = File(newPath).parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
      await File(newPath).writeAsBytes(resizedBytes);
    }

    state = state.copyWith(
      isResizing: false,
      snackbarMessage: 'Images saved to $savePath.',
      hasResized: false,
      resizedImagesData: null,
    );
  }

  Future<void> selectSaveDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath(
      initialDirectory: state.saveDirectory,
    );
    if (result != null) {
      state = state.copyWith(saveDirectory: result);
    }
  }
  // endregion

  // region Private Helpers
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
        return ((widthInput * resolution / 2.54).round(), (heightInput * resolution / 2.54).round());
      case DimensionUnitType.mm:
        return ((widthInput * resolution / 25.4).round(), (heightInput * resolution / 25.4).round());
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

  String _getNewFileName(String oldPath, String suffix) {
    final oldFileName = oldPath.split('/').last;
    final oldExtension = oldFileName.split('.').last;
    final oldNameWithoutExtension = oldFileName.substring(
      0,
      oldFileName.length - oldExtension.length - 1,
    );

    String newExtension;
    if (state.outputFormat == ImageResizeOutputFormat.sameAsOriginal) {
      newExtension = oldExtension.toLowerCase();
    } else {
      newExtension = state.outputFormat.name;
    }
    return '$oldNameWithoutExtension$suffix.$newExtension';
  }
  //endregion
}

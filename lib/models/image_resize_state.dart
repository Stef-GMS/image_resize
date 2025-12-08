import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_resize/models/dimension_unit_type.dart';
import 'package:image_resize/models/image_resize_output_format.dart';

/// Represents the state of the ImageResizeScreen.
/// This is a standard immutable class, written manually.
@immutable
class ImageResizeState {
  final String width;
  final String height;
  final String resolution;
  final String suffix;
  final List<File> selectedImages;
  final double? aspectRatio;
  final img.Image? firstImage;
  final bool scaleProportionally;
  final bool resampleImage;
  final bool maintainAspectRatio;
  final bool includeExif;
  final bool userEditedSuffix;
  final ImageResizeOutputFormat outputFormat;
  final DimensionUnitType dimensionType;
  final String? saveDirectory;
  final bool isResizing;
  final bool overwriteAll;
  final String? snackbarMessage;

  const ImageResizeState({
    required this.width,
    required this.height,
    required this.resolution,
    required this.suffix,
    required this.selectedImages,
    this.aspectRatio,
    this.firstImage,
    required this.scaleProportionally,
    required this.resampleImage,
    required this.maintainAspectRatio,
    required this.includeExif,
    required this.userEditedSuffix,
    required this.outputFormat,
    required this.dimensionType,
    this.saveDirectory,
    required this.isResizing,
    required this.overwriteAll,
    this.snackbarMessage,
  });

  /// Creates the initial state for the image resize screen.
  factory ImageResizeState.initial() => const ImageResizeState(
        width: '',
        height: '',
        resolution: '72',
        suffix: '',
        selectedImages: [],
        aspectRatio: null,
        firstImage: null,
        scaleProportionally: true,
        resampleImage: true,
        maintainAspectRatio: true,
        includeExif: true,
        userEditedSuffix: false,
        outputFormat: ImageResizeOutputFormat.sameAsOriginal,
        dimensionType: DimensionUnitType.pixels,
        saveDirectory: null,
        isResizing: false,
        overwriteAll: false,
        snackbarMessage: null,
      );

  ImageResizeState copyWith({
    String? width,
    String? height,
    String? resolution,
    String? suffix,
    List<File>? selectedImages,
    double? aspectRatio,
    img.Image? firstImage,
    bool? scaleProportionally,
    bool? resampleImage,
    bool? maintainAspectRatio,
    bool? includeExif,
    bool? userEditedSuffix,
    ImageResizeOutputFormat? outputFormat,
    DimensionUnitType? dimensionType,
    String? saveDirectory,
    bool? isResizing,
    bool? overwriteAll,
    String? snackbarMessage,
  }) {
    return ImageResizeState(
      width: width ?? this.width,
      height: height ?? this.height,
      resolution: resolution ?? this.resolution,
      suffix: suffix ?? this.suffix,
      selectedImages: selectedImages ?? this.selectedImages,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      firstImage: firstImage ?? this.firstImage,
      scaleProportionally: scaleProportionally ?? this.scaleProportionally,
      resampleImage: resampleImage ?? this.resampleImage,
      maintainAspectRatio: maintainAspectRatio ?? this.maintainAspectRatio,
      includeExif: includeExif ?? this.includeExif,
      userEditedSuffix: userEditedSuffix ?? this.userEditedSuffix,
      outputFormat: outputFormat ?? this.outputFormat,
      dimensionType: dimensionType ?? this.dimensionType,
      saveDirectory: saveDirectory ?? this.saveDirectory,
      isResizing: isResizing ?? this.isResizing,
      overwriteAll: overwriteAll ?? this.overwriteAll,
      snackbarMessage: snackbarMessage ?? this.snackbarMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageResizeState &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height &&
          resolution == other.resolution &&
          suffix == other.suffix &&
          listEquals(selectedImages, other.selectedImages) &&
          aspectRatio == other.aspectRatio &&
          firstImage == other.firstImage &&
          scaleProportionally == other.scaleProportionally &&
          resampleImage == other.resampleImage &&
          maintainAspectRatio == other.maintainAspectRatio &&
          includeExif == other.includeExif &&
          userEditedSuffix == other.userEditedSuffix &&
          outputFormat == other.outputFormat &&
          dimensionType == other.dimensionType &&
          saveDirectory == other.saveDirectory &&
          isResizing == other.isResizing &&
          overwriteAll == other.overwriteAll &&
          snackbarMessage == other.snackbarMessage;

  @override
  int get hashCode =>
      width.hashCode ^
      height.hashCode ^
      resolution.hashCode ^
      suffix.hashCode ^
      selectedImages.hashCode ^
      aspectRatio.hashCode ^
      firstImage.hashCode ^
      scaleProportionally.hashCode ^
      resampleImage.hashCode ^
      maintainAspectRatio.hashCode ^
      includeExif.hashCode ^
      userEditedSuffix.hashCode ^
      outputFormat.hashCode ^
      dimensionType.hashCode ^
      saveDirectory.hashCode ^
      isResizing.hashCode ^
      overwriteAll.hashCode ^
      snackbarMessage.hashCode;
}

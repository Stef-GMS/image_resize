import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_resize/models/dimension_unit_type.dart';
import 'package:image_resize/models/file_conflict_info.dart';
import 'package:image_resize/models/file_conflict_state.dart';
import 'package:image_resize/models/image_resize_output_format.dart';
import 'package:image_resize/models/save_destination.dart';

/// Represents the state of the ImageResizeScreen.
/// This is a standard immutable class, written manually.
@immutable
class ImageResizeState {
  final String width;
  final String height;
  final String resolution;
  final String suffix;
  final String baseFilename;
  final List<File> selectedImages;
  final Map<String, String> originalFileNames; // Maps temp path to original filename
  final double? aspectRatio;
  final img.Image? firstImage;
  final bool scaleProportionally;
  final bool resampleImage;
  final bool maintainAspectRatio;
  final bool includeExif;
  final bool userEditedSuffix;
  final ImageResizeOutputFormat outputFormat;
  final DimensionUnitType dimensionType;
  final SaveDestination saveDestination;
  final String? saveDirectory;
  final bool isResizing;
  final bool resetOptionsOnClear;
  final String? snackbarMessage;
  final bool hasResized;
  final List<Uint8List>? resizedImagesData;
  final FileConflictState fileConflictState;
  final FileConflictInfo? conflictInfo;

  const ImageResizeState({
    required this.width,
    required this.height,
    required this.resolution,
    required this.suffix,
    required this.baseFilename,
    required this.selectedImages,
    required this.originalFileNames,
    this.aspectRatio,
    this.firstImage,
    required this.scaleProportionally,
    required this.resampleImage,
    required this.maintainAspectRatio,
    required this.includeExif,
    required this.userEditedSuffix,
    required this.outputFormat,
    required this.dimensionType,
    required this.saveDestination,
    this.saveDirectory,
    required this.isResizing,
    required this.resetOptionsOnClear,
    this.snackbarMessage,
    required this.hasResized,
    this.resizedImagesData,
    required this.fileConflictState,
    this.conflictInfo,
  });

  /// Creates the initial state for the image resize screen.
  factory ImageResizeState.initial() => const ImageResizeState(
    width: '',
    height: '',
    resolution: '72',
    suffix: '',
    baseFilename: '',
    selectedImages: [],
    originalFileNames: {},
    aspectRatio: null,
    firstImage: null,
    scaleProportionally: true,
    resampleImage: true,
    maintainAspectRatio: true,
    includeExif: true,
    userEditedSuffix: false,
    outputFormat: ImageResizeOutputFormat.sameAsOriginal,
    dimensionType: DimensionUnitType.pixels,
    saveDestination: SaveDestination.deviceFileSystem,
    saveDirectory: null,
    isResizing: false,
    resetOptionsOnClear: true,
    snackbarMessage: null,
    hasResized: false,
    resizedImagesData: null,
    fileConflictState: FileConflictState.none,
    conflictInfo: null,
  );

  ImageResizeState copyWith({
    String? width,
    String? height,
    String? resolution,
    String? suffix,
    String? baseFilename,
    List<File>? selectedImages,
    Map<String, String>? originalFileNames,
    double? aspectRatio,
    img.Image? firstImage,
    bool? scaleProportionally,
    bool? resampleImage,
    bool? maintainAspectRatio,
    bool? includeExif,
    bool? userEditedSuffix,
    ImageResizeOutputFormat? outputFormat,
    DimensionUnitType? dimensionType,
    SaveDestination? saveDestination,
    String? saveDirectory,
    bool? isResizing,
    bool? resetOptionsOnClear,
    String? snackbarMessage,
    bool? hasResized,
    List<Uint8List>? resizedImagesData,
    FileConflictState? fileConflictState,
    FileConflictInfo? conflictInfo,
  }) {
    return ImageResizeState(
      width: width ?? this.width,
      height: height ?? this.height,
      resolution: resolution ?? this.resolution,
      suffix: suffix ?? this.suffix,
      baseFilename: baseFilename ?? this.baseFilename,
      selectedImages: selectedImages ?? this.selectedImages,
      originalFileNames: originalFileNames ?? this.originalFileNames,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      firstImage: firstImage ?? this.firstImage,
      scaleProportionally: scaleProportionally ?? this.scaleProportionally,
      resampleImage: resampleImage ?? this.resampleImage,
      maintainAspectRatio: maintainAspectRatio ?? this.maintainAspectRatio,
      includeExif: includeExif ?? this.includeExif,
      userEditedSuffix: userEditedSuffix ?? this.userEditedSuffix,
      outputFormat: outputFormat ?? this.outputFormat,
      dimensionType: dimensionType ?? this.dimensionType,
      saveDestination: saveDestination ?? this.saveDestination,
      saveDirectory: saveDirectory ?? this.saveDirectory,
      isResizing: isResizing ?? this.isResizing,
      resetOptionsOnClear: resetOptionsOnClear ?? this.resetOptionsOnClear,
      snackbarMessage: snackbarMessage ?? this.snackbarMessage,
      hasResized: hasResized ?? this.hasResized,
      resizedImagesData: resizedImagesData ?? this.resizedImagesData,
      fileConflictState: fileConflictState ?? this.fileConflictState,
      conflictInfo: conflictInfo ?? this.conflictInfo,
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
          baseFilename == other.baseFilename &&
          listEquals(selectedImages, other.selectedImages) &&
          mapEquals(originalFileNames, other.originalFileNames) &&
          aspectRatio == other.aspectRatio &&
          firstImage == other.firstImage &&
          scaleProportionally == other.scaleProportionally &&
          resampleImage == other.resampleImage &&
          maintainAspectRatio == other.maintainAspectRatio &&
          includeExif == other.includeExif &&
          userEditedSuffix == other.userEditedSuffix &&
          outputFormat == other.outputFormat &&
          dimensionType == other.dimensionType &&
          saveDestination == other.saveDestination &&
          saveDirectory == other.saveDirectory &&
          isResizing == other.isResizing &&
          resetOptionsOnClear == other.resetOptionsOnClear &&
          snackbarMessage == other.snackbarMessage &&
          hasResized == other.hasResized &&
          listEquals(resizedImagesData, other.resizedImagesData) &&
          fileConflictState == other.fileConflictState &&
          conflictInfo == other.conflictInfo;

  @override
  int get hashCode =>
      width.hashCode ^
      height.hashCode ^
      resolution.hashCode ^
      suffix.hashCode ^
      baseFilename.hashCode ^
      selectedImages.hashCode ^
      originalFileNames.hashCode ^
      aspectRatio.hashCode ^
      firstImage.hashCode ^
      scaleProportionally.hashCode ^
      resampleImage.hashCode ^
      maintainAspectRatio.hashCode ^
      includeExif.hashCode ^
      userEditedSuffix.hashCode ^
      outputFormat.hashCode ^
      dimensionType.hashCode ^
      saveDestination.hashCode ^
      saveDirectory.hashCode ^
      isResizing.hashCode ^
      resetOptionsOnClear.hashCode ^
      snackbarMessage.hashCode ^
      hasResized.hashCode ^
      resizedImagesData.hashCode ^
      fileConflictState.hashCode ^
      conflictInfo.hashCode;
}

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

/// Provider to make the ImageProcessingService available to other providers.
final imageProcessingServiceProvider = Provider<ImageProcessingService>((ref) {
  return ImageProcessingService();
});

/// A service class responsible for handling image manipulation logic.
///
/// This class is abstracted from the UI layer (ViewModel/Notifier) to keep
/// business logic separated and independently testable.
class ImageProcessingService {
  /// Resizes the given image data to the specified width and height.
  ///
  /// [imageData] The raw data of the image to resize.
  /// [newWidth] The target width for the resized image.
  /// [newHeight] The target height for the resized image.
  /// [newResolution] The target resolution in DPI.
  ///
  /// Returns a [Future<Uint8List>] containing the data of the resized image.
  Future<Uint8List> resizeImage({
    required Uint8List imageData,
    required int newWidth,
    required int newHeight,
    required int newResolution,
  }) async {
    //print('--- Resizing image to ${newWidth}x$newHeight @ ${newResolution}dpi ---');

    // Decode the image
    final image = img.decodeImage(imageData);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize the image using the image package
    final resizedImage = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );

    // Determine the output format based on the original image
    // Try to detect the format from the original data
    Uint8List result;
    if (imageData.length > 4 && imageData[0] == 0x89 && imageData[1] == 0x50) {
      // PNG format
      result = Uint8List.fromList(
        img.PngEncoder(
          filter: img.PngFilter.paeth,
          level: 6,
          pixelDimensions: img.PngPhysicalPixelDimensions.dpi(newResolution),
        ).encode(resizedImage),
      );
    } else {
      // Default to JPEG
      result = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 95));
    }

    // print(
    //   '--- Image resized successfully from ${image.width}x${image.height} to ${resizedImage.width}x${resizedImage.height} ---',
    // );

    return result;
  }
}

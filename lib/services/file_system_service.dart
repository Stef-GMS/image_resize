import 'dart:io';

import 'package:image_resize/models/image_resize_output_format.dart';
import 'package:path_provider/path_provider.dart';

class FileSystemService {
  Future<String?> getDownloadsDirectoryPath() async {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download';
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } else if (Platform.isMacOS) {
      final directory = await getDownloadsDirectory();
      return directory?.path;
    }
    return null;
  }

  String getNewFileName(
    String oldPath,
    String? originalFileName,
    String? baseFilename,
    int width,
    int height,
    String suffix,
    ImageResizeOutputFormat outputFormat,
  ) {
    // Determine the source filename
    String sourceFileName;
    String oldNameWithoutExtension;
    String? oldExtension;

    if (baseFilename != null && baseFilename.isNotEmpty) {
      // User provided a custom base filename - use it as-is (no extension)
      oldNameWithoutExtension = baseFilename;
      // Get extension from the original file for determining output format
      final tempFileName = originalFileName ?? oldPath.split('/').last;
      oldExtension = tempFileName.contains('.') ? tempFileName.split('.').last : null;
    } else {
      // Use original filename or extract from path
      sourceFileName = originalFileName ?? oldPath.split('/').last;
      if (sourceFileName.contains('.')) {
        oldExtension = sourceFileName.split('.').last;
        oldNameWithoutExtension = sourceFileName.substring(
          0,
          sourceFileName.length - oldExtension.length - 1,
        );
      } else {
        oldExtension = null;
        oldNameWithoutExtension = sourceFileName;
      }
    }

    String newExtension;
    if (outputFormat == ImageResizeOutputFormat.sameAsOriginal) {
      newExtension = oldExtension?.toLowerCase() ?? 'jpg';
    } else {
      newExtension = outputFormat.name;
    }

    return '$oldNameWithoutExtension$suffix.$newExtension';
  }
}

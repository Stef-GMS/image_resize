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
    int width,
    int height,
    String suffix,
    ImageResizeOutputFormat outputFormat,
  ) {
    final oldFileName = oldPath.split('/').last;
    final oldExtension = oldFileName.split('.').last;
    final oldNameWithoutExtension = oldFileName.substring(
      0,
      oldFileName.length - oldExtension.length - 1,
    );

    String newExtension;
    if (outputFormat == ImageResizeOutputFormat.sameAsOriginal) {
      newExtension = oldExtension.toLowerCase();
    } else {
      newExtension = outputFormat.name;
    }
    // print("New filename: $oldNameWithoutExtension$suffix.$newExtension'");

    return '$oldNameWithoutExtension$suffix.$newExtension';
  }
}
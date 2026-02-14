import 'dart:io';

import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class PermissionService {
  /// Request permission to save to the device's Photo Library.
  /// Uses photo_manager on macOS and gal on iOS/Android.
  Future<bool> requestPhotoLibraryPermission() async {
    if (Platform.isMacOS) {
      // Use photo_manager on macOS
      try {
        print('DEBUG: Requesting macOS Photo Library permission via photo_manager');
        final PermissionState ps = await PhotoManager.requestPermissionExtend();
        print('DEBUG: Permission state: ${ps.name}, hasAccess: ${ps.hasAccess}');
        return ps.hasAccess;
      } catch (e, stackTrace) {
        // If permission request fails, return false
        print('ERROR: photo_manager permission request failed: $e');
        print('STACK TRACE: $stackTrace');
        return false;
      }
    } else {
      // Use gal on iOS/Android
      try {
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          await Gal.requestAccess();
          return await Gal.hasAccess();
        }
        return true;
      } catch (e) {
        rethrow;
      }
    }
  }

  /// Request permission to save to the file system.
  Future<bool> requestStoragePermission() async {
    if (Platform.isMacOS || Platform.isIOS) {
      // File system access on iOS is handled by the file picker's
      // security-scoped resources; no separate permission needed.
      return true;
    }
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    }
    // Default for other platforms
    return true;
  }
}

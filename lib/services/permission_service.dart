import 'dart:io';

import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

class PermissionService {
  /// Request permission to save to the device's Photo Library.
  /// Uses photo_manager on macOS, gal on iOS/Android.
  Future<bool> requestPhotoLibraryPermission() async {
    if (Platform.isMacOS) {
      // Use photo_manager on macOS
      try {
        print('DEBUG: Requesting macOS Photo Library permission via photo_manager');
        final permission = await PhotoManager.requestPermissionExtend();
        print('DEBUG: Permission state: ${permission.name}, isAuth: ${permission.isAuth}');

        if (!permission.isAuth) {
          print('DEBUG: Permission denied, opening settings');
          PhotoManager.openSetting();
          return false;
        }
        return true;
      } catch (e, stackTrace) {
        print('ERROR: photo_manager permission request failed: $e');
        print('STACK TRACE: $stackTrace');
        rethrow;
      }
    }

    // Use gal on iOS/Android
    try {
      print('DEBUG: Requesting Photo Library permission via gal');
      final hasAccess = await Gal.hasAccess();
      print('DEBUG: Current access: $hasAccess');
      if (!hasAccess) {
        print('DEBUG: Requesting access...');
        await Gal.requestAccess();
        final newAccess = await Gal.hasAccess();
        print('DEBUG: New access: $newAccess');
        return newAccess;
      }
      return true;
    } catch (e, stackTrace) {
      print('ERROR: gal permission request failed: $e');
      print('STACK TRACE: $stackTrace');
      rethrow;
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

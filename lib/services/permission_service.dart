import 'dart:io';

import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request permission to save to the device's Photo Library.
  /// Uses the gal package's built-in permission handling which works
  /// on iOS, Android, and macOS.
  Future<bool> requestPhotoLibraryPermission() async {
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
        return await Gal.hasAccess();
      }
      return true;
    } catch (e) {
      // On macOS, Flutter has a known issue loading Info.plist which can cause
      // gal to crash. If permission check fails, assume we have permission
      // (the entitlements should handle it).
      if (Platform.isMacOS) {
        return true;
      }
      // On other platforms, rethrow the error
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

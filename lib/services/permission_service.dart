import 'dart:io';

import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request permission to save to the device's Photo Library.
  /// Uses gal on all platforms (iOS, Android, macOS).
  Future<bool> requestPhotoLibraryPermission() async {
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
      // On macOS, gal might fail but the entitlements should handle permissions
      // Return true to allow the save attempt
      if (Platform.isMacOS) {
        print('DEBUG: Assuming permission granted on macOS due to entitlements');
        return true;
      }
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

import 'dart:io';

import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request permission to save to the device's Photo Library.
  /// Uses gal on iOS/Android. On macOS, relies on entitlements.
  Future<bool> requestPhotoLibraryPermission() async {
    // On macOS, skip permission check - entitlements handle it
    // Both gal and photo_manager crash when requesting permissions on macOS
    if (Platform.isMacOS) {
      print('DEBUG: Skipping permission check on macOS (using entitlements)');
      return true;
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

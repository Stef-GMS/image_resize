### **PRD: Multi-Destination Image Saving**

**Author:** Updated per user requirements
**Version:** 4.0
**Date:** February 13, 2026
**Status:** Implemented

---

#### **1. Background**

The application provides multiple save destination options with platform-specific capabilities. Users can choose to save resized images to their device's Photo Library (iOS/Android only), cloud storage, or local device file system.

A "Save To" dropdown in the Save Location section lets users select their preferred destination. When saving to the file system or cloud, users can choose a specific folder. When saving to Device Photos (iOS/Android), images are saved directly to the Photo Library.

**Platform-Specific Capabilities:**
- **macOS:** Can pick images from Photos app (via native PHPicker), but cannot save to Photos (no Flutter package supports this). Users must save to file system or cloud.
- **iOS/Android:** Full support for picking from and saving to Photo Library.

#### **2. Goals & Objectives**

*   **Goal 1: Multi-Destination Save Options.**
    *   **Objective:** Provide save destination options appropriate for each platform:
        *   iOS/Android: Device Photos, Cloud, Device File System
        *   macOS: Cloud, Device File System (Photos save not supported)

*   **Goal 2: Photo Library Integration on iOS/Android.**
    *   **Objective:** Enable saving to the native Photo Library on iOS and Android using the `gal` package.

*   **Goal 3: macOS Photos Picker Integration.**
    *   **Objective:** Enable picking images from macOS Photos app using `native_image_picker_macos` package (macOS 13+).

*   **Goal 4: Smart Default Save Location.**
    *   **Objective:** Save directory is initially unselected. When picking from file system/cloud, auto-populate with source directory. When picking from Photos, leave unselected.

*   **Goal 5: User Control Over Save Location.**
    *   **Objective:** Users can switch between save destinations and choose specific folders for file system/cloud saving.

#### **3. Non-Goals**

*   **No Change to Resizing Logic:** The core image processing and resizing logic is not affected.
*   **No Cloud Provider Configuration:** Cloud saving uses the native file picker which provides access to installed cloud providers (iCloud, Google Drive, etc.).
*   **No macOS Photos Save Support:** Saving to macOS Photo Library is not supported due to Flutter package limitations. Both `gal` and `photo_manager` crash when attempting to save to macOS Photos. Users must use file system or cloud save options on macOS.

#### **4. User Persona**

*   **Name:** Mobile/Desktop User
*   **Role:** A user who wants flexibility in where resized images are saved.
*   **Scenario 1:** After selecting images from the device photo gallery, the user wants to save resized versions back to the Photo Library.
*   **Scenario 2:** After selecting images from iCloud Drive, the user wants to save resized versions to a specific cloud folder.
*   **Requirement:** "I want to choose whether to save to my Photo Library, cloud storage, or local file system depending on my needs."

#### **5. Requirements**

| ID | Requirement | Description |
| :--- | :--- | :--- |
| **REQ-01** | **SaveDestination Enum** | A `SaveDestination` enum with values: `devicePhotos` ("Device Photos"), `cloud` ("Cloud"), `deviceFileSystem` ("Device File System"), implementing `DropdownLabel`. |
| **REQ-02** | **State Management** | `ImageResizeState` includes a `saveDestination` field (default: `deviceFileSystem`). The ViewModel provides `setSaveDestination()` to change it. |
| **REQ-03** | **Save Location UI** | The Save Location section displays a "Save To" dropdown for selecting the destination. On macOS, "Device Photos" is hidden from the dropdown. When "Cloud" or "Device File System" is selected, the "Choose Folder" button and directory path are shown. |
| **REQ-04** | **Photo Library Saving (iOS/Android)** | When `saveDestination` is `devicePhotos`, resized images are saved using the `gal` package (`Gal.putImage()`). Success message: "Images resized and saved to Photo Library". |
| **REQ-05** | **File System Saving** | When `saveDestination` is `cloud` or `deviceFileSystem`, resized images are saved using `File.writeAsBytes()` to the selected directory. Success message: "Images resized and saved to [path]". |
| **REQ-06** | **macOS Photos Picker** | macOS uses `native_image_picker_macos` package (v0.0.2) to enable native PHPicker for selecting images from Photos app (macOS 13+). Registered in `main()` with `NativeImagePickerMacOS.registerWithIfSupported()`. |
| **REQ-07** | **macOS Photos Save Block** | On macOS, saving to Photos is blocked with error message. Both `gal` and `photo_manager` packages crash on macOS when attempting to save. Safety check prevents crash. |
| **REQ-08** | **iOS Photo Library Support** | iOS `Info.plist` includes `NSPhotoLibraryAddUsageDescription` and `NSPhotoLibraryUsageDescription`. Uses `gal` package for saving. |
| **REQ-09** | **Android Photo Library Support** | Uses `gal` package for saving to device gallery. |
| **REQ-10** | **Conditional Save Directory** | When picking from file system/cloud, `state.saveDirectory` is auto-populated with source directory. When picking from Photos, save directory remains unselected (user must choose). |
| **REQ-11** | **Write Permission Validation** | For file system/cloud saving, the app tests write permissions before saving. If not writable, the user is prompted to select a different location. |
| **REQ-12** | **Per-Image Dimension Calculation** | When resizing multiple images, dimensions are calculated individually for each image to preserve aspect ratios. Uses `_calculatePixelDimensionsForImage(image)` method. |

#### **6. Success Metrics**

*   **macOS Platform:**
    *   "Save To" dropdown shows two options: Cloud, Device File System (Device Photos is hidden).
    *   "Photos" button opens native macOS Photos picker (macOS 13+).
    *   "Files/Drive" button opens file picker for selecting from file system/cloud.
    *   After resize, images are saved to the selected directory.
    *   Attempting to save to Photos (if state somehow gets set) shows error message instead of crashing.
*   **iOS/Android Platforms:**
    *   "Save To" dropdown shows three options: Device Photos, Cloud, Device File System.
    *   "Photos" button opens native photo gallery picker.
    *   "Files/Drive" button opens file picker for selecting from file system/cloud.
    *   After resize with "Device Photos" selected, images appear in the Photo Library.
    *   After resize with "Cloud" or "Device File System" selected, images are saved to the selected directory.
*   **Multi-Image Resize:**
    *   When resizing multiple images with different aspect ratios, each image maintains its own aspect ratio.
    *   Percentage-based resizing calculates dimensions per image, not based on first image only.
*   **Default Behavior:**
    *   Save destination defaults to Device File System.
    *   Save directory is initially unselected.
    *   When picking from file system/cloud, save directory auto-populates with source directory.
    *   When picking from Photos, save directory remains unselected (user must choose).

---

#### **7. Technical Implementation**

**Packages Used:**
- `native_image_picker_macos: ^0.0.2` - Native PHPicker for macOS Photos app (macOS 13+)
- `gal: ^2.3.2` - Photo Library save on iOS/Android
- `photo_manager: ^3.8.3` - Attempted for macOS Photos save (crashes, not used)
- `file_picker: ^8.1.6` - File/directory selection, cloud storage access
- `image_picker: ^1.1.2` - Photo gallery picker on iOS/Android

**Key Implementation Details:**

1. **macOS Photos Picker Registration:**
   ```dart
   // In main.dart
   if (Platform.isMacOS) {
     NativeImagePickerMacOS.registerWithIfSupported();
   }
   ```

2. **Platform-Specific Save Dropdown:**
   ```dart
   // In save_location_section.dart
   final availableDestinations = Platform.isMacOS
       ? SaveDestination.values.where((d) => d != SaveDestination.devicePhotos).toList()
       : SaveDestination.values;
   ```

3. **macOS Photos Save Safety Check:**
   ```dart
   // In image_resize_viewmodel.dart
   if (Platform.isMacOS && saveToPhotos) {
     state = state.copyWith(
       isResizing: false,
       snackbarMessage: 'Saving to Photos is not supported on macOS...',
     );
     return;
   }
   ```

4. **Per-Image Dimension Calculation:**
   ```dart
   // Calculate dimensions for each image individually
   for (final imageFile in state.selectedImages) {
     final image = img.decodeImage(await imageFile.readAsBytes());
     final (pixelWidth, pixelHeight) = _calculatePixelDimensionsForImage(image);
     // Resize using this image's specific dimensions
   }
   ```

**Known Limitations:**
- macOS cannot save to Photo Library (both `gal` and `photo_manager` crash on macOS)
- macOS Photos picker requires macOS 13+ (falls back to file picker on older versions)
- File conflict handling uses enum-based state to ensure proper change detection in Riverpod

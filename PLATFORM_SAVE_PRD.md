### **PRD: Platform-Aware Image Saving**

**Author:** Gemini Expert
**Version:** 1.0
**Date:** December 8, 2025
**Status:** Proposed

---

#### **1. Background**

The application currently features a "Save Location" section with a "Choose Folder" button. While this works on desktop platforms, it provides a poor user experience on mobile. On iOS, the file picker defaults to cloud storage locations (like iCloud Drive) or the app's sandboxed container, with no clear option to save directly to the user's main Photo Library. This is confusing and goes against user expectations for a mobile app that handles images.

The goal is to create a more intuitive and platform-native saving experience, ensuring users can easily save their resized images to their device's photo gallery on iOS and Android.

#### **2. Goals & Objectives**

*   **Goal 1: Implement Native Photo Library Saving.**
    *   **Objective:** On iOS and Android, successfully save resized images directly to the user's primary photo gallery (e.g., Photos app on iOS, Gallery/Photos on Android).

*   **Goal 2: Improve Mobile User Experience.**
    *   **Objective:** On mobile platforms, remove the confusing "Choose Folder" workflow and provide clear feedback that images are being saved to the photo gallery.

*   **Goal 3: Maintain Desktop Functionality.**
    *   **Objective:** On desktop platforms (macOS, Windows, Linux), the existing "Choose Folder" functionality should remain unchanged.

#### **3. Non-Goals**

*   **No Major UI Overhaul:** The overall look and feel of the app will not be changed. Modifications will be limited to the "Save Location" section and related user feedback.
*   **No Change to Resizing Logic:** The core image processing and resizing logic will not be affected.

#### **4. User Persona**

*   **Name:** Dana, the iPhone User
*   **Role:** A user who just resized a batch of photos for social media.
*   **Scenario:** After resizing her photos, Dana expects to find them in her Photos app, ready to be uploaded.
*   **Pain Point (Current State):** "I resized my pictures, but now I can't find them. The app asked me to pick a folder on my Google Drive. I just want them in my camera roll like every other photo app."

#### **5. Requirements**

This feature will be implemented through the following technical requirements:

| ID | Requirement | Description |
| :--- | :--- | :--- |
| **REQ-01** | **Add Image Gallery Saver Dependency** | Integrate the `image_gallery_saver` package. This package provides a simple, platform-agnostic API to save images and videos to the device's gallery, handling the necessary native code on both iOS and Android. |
| **REQ-02** | **Update iOS Project Configuration** | Add the necessary permission key to the `ios/Runner/Info.plist` file. This is required by iOS to allow an app to add images to the photo library. The key is `NSPhotoLibraryAddUsageDescription`, and it should have a user-facing string explaining why the app needs this permission (e.g., "This app needs access to save resized images to your photo library."). |
| **REQ-03** | **Implement Platform-Aware Save Logic** | In the `ImageResizeViewModel`, the `resizeImages` method will be updated. After an image is successfully resized into memory (`resizedBytes`), the saving logic will be wrapped in a platform check: <br>- If `Platform.isIOS` or `Platform.isAndroid`, call `ImageGallerySaver.saveImage(resizedBytes, name: newFileName)`. <br>- Otherwise (for desktop), retain the existing logic of writing the file to the path specified in `state.saveDirectory`. |
| **REQ-04** | **Adapt UI for Mobile vs. Desktop** | In `image_resize_screen.dart`, the "Save Location" section will be updated: <br>- The `_buildSaveLocationSection` widget will check the platform. <br>- On iOS and Android, the "Choose Folder" button and the directory path display will be hidden entirely. <br>- On desktop platforms, this section will remain visible and functional as it is now. |
| **REQ-05** | **Improve User Feedback** | In the `ImageResizeViewModel`, the `snackbarMessage` set after a successful resize will be made platform-aware: <br>- On mobile, it will be "Images saved to Photo Gallery." <br>- On desktop, it will remain "Images resized and saved to [folder path]." |
| **REQ-06** | **Configurable "Device" Button Source** | Add a setting on the `SettingsScreen` to allow the user to select the source for the "Device" button. The options will be: <br>- **Photo Gallery:** (Default) Uses `image_picker` to select from the device's native photo gallery. <br>- **File System:** Uses `file_picker` to select from the device's general file system. <br>The `ImageResizeViewModel` will be updated to manage this setting and execute the correct file-picking logic based on the selection. The "Cloud" button on the main screen will be removed, as its functionality is now merged into this setting. |

#### **6. Success Metrics**

*   **iOS:** After a successful resize, the new image appears in the device's Photos app.
*   **Android:** After a successful resize, the new image appears in the device's default gallery app.
*   **macOS/Windows:** The user can still choose a folder, and the resized image is saved to that location.
*   **UI:** The "Save Location" UI is hidden on mobile platforms but visible on desktop platforms.
*   **New Setting:** A new option exists on the Settings screen to switch the "Device" button's source. When "File System" is selected, tapping "Device" opens a general file browser instead of the photo gallery.

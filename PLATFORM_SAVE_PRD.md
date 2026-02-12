### **PRD: Multi-Destination Image Saving**

**Author:** Updated per user requirements
**Version:** 3.1
**Date:** February 7, 2026
**Status:** Implemented

---

#### **1. Background**

The application provides multiple save destination options across all platforms (macOS, iOS, Android). Users can choose to save resized images to their device's Photo Library, cloud storage, or local device file system.

A "Save To" dropdown in the Save Location section lets users select their preferred destination. When saving to the file system or cloud, users can choose a specific folder. When saving to Device Photos, images are saved directly to the Photo Library.

#### **2. Goals & Objectives**

*   **Goal 1: Multi-Destination Save Options.**
    *   **Objective:** Provide three save destination options on all platforms: Device Photos, Cloud, and Device File System.

*   **Goal 2: Photo Library Integration on All Platforms.**
    *   **Objective:** Enable saving to the native Photo Library on iOS, Android, and macOS using the `gal` package (supports all three platforms).

*   **Goal 3: Smart Default Save Location.**
    *   **Objective:** Default save destination is Device File System with the save directory automatically set to the source directory.

*   **Goal 4: User Control Over Save Location.**
    *   **Objective:** Users can switch between save destinations and choose specific folders for file system/cloud saving.

#### **3. Non-Goals**

*   **No Change to Resizing Logic:** The core image processing and resizing logic is not affected.
*   **No Cloud Provider Configuration:** Cloud saving uses the native file picker which provides access to installed cloud providers (iCloud, Google Drive, etc.).
*   **No macOS Photos Source Picker:** On macOS, the `image_picker` package wraps `file_selector` (standard file dialog), not the native Photos app. There is no Flutter package that provides a native macOS Photos picker for selecting source images. Users browse the file system to select images on macOS. Saving to Photos on macOS works via the `gal` package.

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
| **REQ-03** | **Save Location UI** | The Save Location section displays a "Save To" dropdown for selecting the destination. When "Device Photos" is selected, an info message is shown. When "Cloud" or "Device File System" is selected, the "Choose Folder" button and directory path are shown. |
| **REQ-04** | **Photo Library Saving** | When `saveDestination` is `devicePhotos`, resized images are saved using the `gal` package (`Gal.putImage()`), which supports iOS, Android, and macOS. Success message: "Images resized and saved to Photo Library". |
| **REQ-05** | **File System Saving** | When `saveDestination` is `cloud` or `deviceFileSystem`, resized images are saved using `File.writeAsBytes()` to the selected directory. Success message: "Images resized and saved to [path]". |
| **REQ-06** | **macOS Photo Library Support** | macOS `Info.plist` includes `NSPhotoLibraryAddUsageDescription` and `NSPhotoLibraryUsageDescription`. macOS entitlements include `com.apple.security.personal-information.photos-library`. |
| **REQ-07** | **iOS Photo Library Support** | iOS `Info.plist` includes `NSPhotoLibraryAddUsageDescription` and `NSPhotoLibraryUsageDescription` (already present). |
| **REQ-08** | **Smart Default Save Directory** | When images are selected, `state.saveDirectory` is automatically set to the parent directory of the first selected image. |
| **REQ-09** | **Write Permission Validation** | For file system/cloud saving, the app tests write permissions before saving. If not writable, the user is prompted to select a different location. |

#### **6. Success Metrics**

*   **All Platforms:** The "Save To" dropdown is visible with three options: Device Photos, Cloud, Device File System.
*   **Device Photos:** After resize, images appear in the device's Photo Library (Photos app on iOS/macOS, Gallery on Android).
*   **Cloud/File System:** After resize, images are saved to the selected directory.
*   **macOS:** Users can save to Photo Library, local file system, or cloud storage.
*   **iOS/Android:** Users can save to Photo Library, local device storage, or cloud storage.
*   **Default Behavior:** Save destination defaults to Device File System with the source directory as the save path.

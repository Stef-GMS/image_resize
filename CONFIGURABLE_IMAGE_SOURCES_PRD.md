### **PRD: Configurable Image Sources**

**Author:** Gemini Expert
**Version:** 1.0
**Date:** December 8, 2025
**Status:** Proposed

---

#### **1. Background**

To enhance flexibility and user control, the application needs to provide more explicit options for selecting image sources. The current implementation has inconsistent behavior for the "Device" button across platforms and a "Cloud" button with basic functionality. This PRD outlines the work to make both the "Device" and "Cloud" image sources configurable from a new settings panel.

#### **2. Goals & Objectives**

*   **Goal 1: Implement Configurable Local Image Picking.**
    *   **Objective:** Allow the user to configure the "Device" button to open either the native photo gallery or the general device file system.

*   **Goal 2: Implement Configurable Cloud Storage Picking.**
    *   **Objective:** Allow the user to select a cloud storage provider and browse it for images using the `multi_cloud_storage` package.

*   **Goal 3: Centralize Source Configuration.**
    *   **Objective:** Add a new "Image Sources" section to the `SettingsScreen` to manage these new options.

#### **3. Requirements**

This feature will be implemented through the following technical requirements:

| ID | Requirement | Description |
| :--- | :--- | :--- |
| **REQ-01** | **Add `multi_cloud_storage` Dependency** | Integrate the `multi_cloud_storage` package to handle browsing and authentication with various cloud storage providers. |
| **REQ-02** | **Update State for New Settings** | The `ImageResizeState` will be updated to hold the configuration for the new settings: <br>- An enum `DevicePickerSource` will be created with values `gallery` and `fileSystem`. <br>- A corresponding `devicePickerSource` property will be added to the state. <br>- An enum `CloudStorageProvider` will be created for the supported cloud services. <br>- A `cloudStorageProvider` property will be added to the state. |
| **REQ-03** | **Update Settings Screen** | The `SettingsScreen` will be converted to a `ConsumerWidget` and will contain a new "Image Sources" section with two settings: <br>- **Device Source:** A dropdown or segmented control to select between "Photo Gallery" and "File System". <br>- **Cloud Source:** A UI to select and configure the desired cloud storage provider (e.g., a dropdown of providers). |
| **REQ-04** | **Update ViewModel Logic** | The `ImageResizeViewModel` will be updated: <br>- A `setDevicePickerSource` method will be added. <br>- A `setCloudProvider` method will be added. <br>- The `pickFromDevice()` method will use the `devicePickerSource` setting to decide whether to use `image_picker` (gallery) or `file_picker` (file system). <br>- The `pickFromCloud()` method will be re-implemented to use the `multi_cloud_storage` package based on the selected provider. |
| **REQ-05** | **Update Main Screen UI** | The `ImageResizeScreen` will feature two distinct buttons in the "Source" section: <br>- **Device:** This button will call the `pickFromDevice()` method. <br>- **Cloud:** This button will call the `pickFromCloud()` method. |

#### **4. Success Metrics**

*   **Device Setting:** A new option on the Settings screen successfully switches the behavior of the "Device" button between opening the photo gallery and the file system browser.
*   **Cloud Setting:** A new option on the Settings screen allows for the selection of a cloud storage provider.
*   **Main Screen:** The "Device" and "Cloud" buttons are both present and trigger the correct logic based on the new settings.

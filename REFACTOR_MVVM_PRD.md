### **PRD: Refactoring to Model-View-ViewModel (MVVM) Pattern**

**Author:** Gemini Expert
**Version:** 1.0
**Date:** December 8, 2025
**Status:** Proposed

---

#### **1. Background**

The Image Resizer is a functional Flutter application that allows users to select an image and specify new dimensions for resizing. The current architecture, while functional, lacks a clear separation of concerns. Business logic, state management, and UI rendering are tightly coupled within the widget classes, primarily using `StatefulWidget` and `setState`. This approach hinders testability, makes state management difficult to track as complexity grows, and complicates future feature development.

This document proposes a strategic refactoring of the application to the **Model-View-ViewModel (MVVM)** architectural pattern. This will establish a robust and scalable foundation for the app.

#### **2. Goals & Objectives**

The primary goal of this refactor is to improve the internal quality of the application without altering its external behavior or appearance.

*   **Goal 1: Enforce Separation of Concerns.**
    *   **Objective:** Create three distinct and decoupled layers:
        *   **Model:** Pure data structures and business logic (e.g., image processing).
        *   **View:** The Flutter widget tree, responsible only for displaying data and capturing user input.
        *   **ViewModel:** The intermediary that holds UI state and executes commands in response to user actions.

*   **Goal 2: Improve State Management.**
    *   **Objective:** Replace scattered `setState` calls with a centralized, observable state managed by the ViewModel. This will create a single source of truth for the UI's state.

*   **Goal 3: Enhance Testability.**
    *   **Objective:** Enable unit testing for ViewModels and business logic (services) independent of the UI rendering, leading to more reliable code.

*   **Goal 4: Increase Maintainability & Scalability.**
    *   **Objective:** Make the codebase easier for developers to understand, debug, and extend with new features.

#### **3. Non-Goals**

To maintain a clear focus, the following are explicitly out of scope for this refactoring effort:

*   **No New Features:** This project will not introduce any new user-facing functionality.
*   **No UI/UX Redesign:** The application's appearance and user flow will remain identical to the current version.
*   **No Major Dependency Changes:** We will only add dependencies essential for state management (i.e., `flutter_riverpod`).

#### **4. Developer Persona**

*   **Name:** Alex, the Flutter Developer
*   **Role:** A developer tasked with maintaining and adding features to the Image Resizer app.
*   **Pain Points (Current State):** "When a bug occurs, I have to trace state changes through multiple `setState` calls in large widget files. It's hard to know where the business logic is handled. Writing tests for my UI logic is nearly impossible."
*   **Desired State (Post-Refactor):** "I can easily find the state and business logic in the Riverpod Notifier. The UI code is clean and declarative. I can write fast, reliable unit tests for the Notifier, which gives me confidence when I make changes."

#### **5. Requirements**

This refactor will be implemented through the following technical requirements:

| ID | Requirement | Description |
| :--- | :--- | :--- |
| **REQ-01** | **Introduce State Management Framework** | - Integrate the `flutter_riverpod` package for state management. <br>- Code generation packages (`riverpod_generator`, `freezed`, `build_runner`) were removed in favor of a manual implementation to resolve build-environment issues. |
| **REQ-02** | **Create Notifier Layer** | - Create a new directory: `lib/viewmodels/`. <br>- Implement `ImageResizeViewModel.dart` containing a `Notifier` class that extends `Notifier<ImageResizeState>`. <br>- A global `NotifierProvider` is manually defined to expose the viewmodel to the UI. |
| **REQ-03** | **Refactor the View Layer** | - The `ImageResizeScreen` is converted to a `ConsumerStatefulWidget`. <br>- The widget uses `ref.watch(imageResizeViewModelProvider)` to subscribe to state changes and `ref.read(imageResizeViewModelProvider.notifier)` to call methods. |
| **REQ-04** | **Solidify the Model Layer** | - The `lib/models/` directory holds pure data classes. <br>- The immutable `ImageResizeState` class was manually created with `copyWith`, `==`, and `hashCode` implementations. |
| **REQ-05** | **Abstract Business Logic (Services)** | - Create a new directory: `lib/services/`. <br>- Implement `ImageProcessingService.dart`. <br>- A global `Provider` is manually defined to make the service available for dependency injection into the `ImageResizeViewModel`. |
| **REQ-06** | **Implement Unit Tests** | - Create a `test/viewmodels/` directory. <br>- Write unit tests for `ImageResizeViewModel`. <br>- **Test Cases:** Use a `ProviderContainer` to test the notifier in isolation. Verify initial state, confirm state changes correctly after method calls, and mock the service provider to test interactions. |

#### **6. Success Metrics**

*   **Code Quality:** The `image_resize_screen.dart` file has been converted to a `ConsumerStatefulWidget` with a significant reduction in imperative code and a clear separation from business logic.
*   **Testability:** Unit tests for `ImageResizeViewModel` can be written to test state logic independent of the UI.
*   **Decoupling:** No `dart:ui` or `package:flutter` imports exist in any Notifier or Service file.
*   **Build Verification:** The application compiles and runs without any change in functionality.

#### **7. Future Considerations**

*   This MVVM with Riverpod pattern will serve as a blueprint for all new features and screens (e.g., refactoring `settings_screen.dart`).
*   The use of Riverpod provides a solid foundation that can scale from simple use cases to highly complex scenarios involving asynchronous operations and caching without needing to switch state management solutions.

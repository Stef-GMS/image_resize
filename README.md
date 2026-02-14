# Image Resize

A cross-platform Flutter application for resizing images with advanced features including multiple dimension units, EXIF preservation, custom filenames, and flexible save destinations.

## Platforms

- **macOS** (Desktop)
- **iOS** (Mobile)
- **Android** (Mobile)

## Features

### Image Selection
- **Pick from Photos** - Select images from device photo library
  - macOS: Native Photos app picker (macOS 13+)
  - iOS/Android: Native photo gallery picker
- **Pick from Files/Drive** - Select images from file system or cloud storage (iCloud, Google Drive, etc.)
- **Multiple Selection** - Resize multiple images at once with preserved aspect ratios

### Dimension Options
- **Pixels** - Specify exact pixel dimensions
- **Percentage** - Resize as percentage of original (maintains aspect ratio per image)
- **Inches** - Specify dimensions in inches with DPI
- **Centimeters** - Specify dimensions in cm with DPI
- **Millimeters** - Specify dimensions in mm with DPI
- **Maintain Aspect Ratio** - Lock width/height ratio during editing

### Resolution & Quality
- **DPI/Resolution** - Set output resolution (auto-detected from EXIF)
- **Output Format** - Choose JPG, PNG, or same as original
- **EXIF Preservation** - Maintains EXIF metadata with updated resolution

### File Naming
- **Base Filename** - Custom base name for output files
  - Auto-populated from original filename
  - Sequential numbering for multiple images (IMG_0001, IMG_0002, etc.)
- **Automatic Suffix** - Shows target dimensions and DPI (e.g., `_750x192_300`)
- **Custom Suffix** - Override automatic suffix with custom text

### Save Destinations
- **Device Photos** (iOS/Android only) - Save directly to photo library
- **Cloud** - Save to iCloud Drive, Google Drive, or other cloud storage
- **Device File System** - Save to local folders
- **Smart Directory Selection** - Auto-populates save directory from source location

### File Conflict Handling
- **Overwrite** - Replace existing files
- **Add Sequence Number** - Append number to filename (e.g., `image_1.jpg`, `image_2.jpg`)
- **Apply to All** - Use same choice for all conflicts in batch

### Additional Features
- **Reset Options** - Optional checkbox to reset all settings when clearing images
- **Accessibility** - High contrast text, proper color ratios
- **Platform-Specific UI** - Adapts to macOS/iOS/Android design patterns


## How It Works

### 1. Select Images
Choose your source images using one of two methods:
- **Photos Button** - Opens native photo library picker
- **Files/Drive Button** - Opens file/cloud storage picker

### 2. Configure Dimensions
Set your desired output size:
1. Choose dimension unit (Pixels, Percentage, Inches, cm, mm)
2. Enter width and height values
3. Optionally enable "Maintain Aspect Ratio" to lock proportions
4. Resolution (DPI) is auto-detected from EXIF or can be manually set

### 3. Customize Output (Optional)
- **Base Filename** - Auto-populated from source, or enter custom name
- **Suffix** - Automatically shows dimensions/DPI, or customize
- **Output Format** - Choose JPG, PNG, or keep original format
- **Reset Options** - Check to reset all settings when clearing images

### 4. Choose Save Location
Select where to save resized images:
- **Device Photos** (iOS/Android) - Saves to photo library
- **Cloud** - Choose cloud storage folder (iCloud, Google Drive, etc.)
- **Device File System** - Choose local folder

The save directory auto-populates when picking from files, or you can manually select a different location.

### 5. Resize
Tap the "Resize" button to process your images. If files already exist with the same names, you'll be prompted to:
- **Overwrite** - Replace existing files
- **Add Sequence Number** - Create new files with numbered suffixes

### 6. View Results
Resized images are saved to your chosen location with:
- Specified dimensions and resolution
- Preserved EXIF metadata (with updated DPI)
- Custom or automatic filenames
- Original quality (JPG quality: 95, PNG: level 6)

## Platform-Specific Behavior

### macOS
- ✅ Pick from Photos app (native PHPicker, macOS 13+)
- ✅ Save to file system or cloud
- ❌ Cannot save to Photos (Flutter limitation)

### iOS
- ✅ Pick from Photos app
- ✅ Save to Photos, file system, or cloud
- ✅ Full photo library integration

### Android
- ✅ Pick from Gallery
- ✅ Save to Gallery, file system, or cloud
- ✅ Full gallery integration

## Technical Details

### Architecture
- **MVVM Pattern** - ViewModel manages state, UI observes changes
- **Riverpod** - State management with `NotifierProvider`
- **Immutable State** - `ImageResizeState` with manual `copyWith`
- **Service Layer** - Separated business logic (ImageProcessingService, FileSystemService, PermissionService)

### Key Packages
- `image: ^4.7.2` - Image manipulation and resizing
- `exif: ^3.3.0` - EXIF metadata reading/writing
- `native_image_picker_macos: ^0.0.2` - macOS Photos picker
- `gal: ^2.3.2` - iOS/Android photo library save
- `file_picker: ^8.1.6` - File/directory selection
- `image_picker: ^1.1.2` - iOS/Android photo picker

### Multi-Image Processing
When resizing multiple images:
- Each image's dimensions are calculated individually
- Aspect ratios are preserved per image
- Percentage-based resizing uses each image's original dimensions
- Sequential filenames are generated (IMG_0001, IMG_0002, etc.)

## Development

### Requirements
- Flutter SDK 3.0+
- Dart 3.0+
- macOS 10.15+ (for macOS builds)
- iOS 12+ (for iOS builds)
- Android API 21+ (for Android builds)

### Building
```bash
# macOS
flutter build macos

# iOS
flutter build ios

# Android
flutter build apk
```

### Running
```bash
# macOS
flutter run -d macos

# iOS (requires device or simulator)
flutter run -d ios

# Android (requires device or emulator)
flutter run -d android
```

## Known Limitations

1. **macOS Photo Library Save** - Cannot save to macOS Photos due to Flutter package limitations (both `gal` and `photo_manager` crash)
2. **macOS Photos Picker** - Requires macOS 13+ (falls back to file picker on older versions)
3. **EXIF Filename** - Only extracted from device photos, not from file system picks

## License

[Add your license here]

## Author

Stephanie @ GeekMeSpeak

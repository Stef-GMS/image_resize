import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:image_resize/models/dimension_unit_type.dart';
import 'package:image_resize/screens/settings_screen.dart';
import 'package:image_resize/widgets/dimensions_section.dart';
import 'package:image_resize/widgets/dropdown_entry.dart';
import 'package:image_resize/widgets/text_field_entry.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

final tagXResolution = img.exifTagNameToID['XResolution']!;
final tagYResolution = img.exifTagNameToID['YResolution']!;

enum ImageResizeOutputFormat {
  sameAsOriginal,
  jpg,
  png,
}

/// The main screen of the application, where users can select and resize images.
class ImageResizeScreen extends StatefulWidget {
  /// Creates an [ImageResizeScreen].
  const ImageResizeScreen({
    super.key,
    required this.handleThemeChange,
    required this.themeMode,
  });

  /// A callback to handle theme changes.
  final void Function(ThemeMode) handleThemeChange;

  /// The current theme mode.
  final ThemeMode themeMode;

  @override
  ImageResizeScreenState createState() => ImageResizeScreenState();
}

/// The state for the [ImageResizeScreen].
class ImageResizeScreenState extends State<ImageResizeScreen> {
  /// The directory where the resized images will be saved.
  String? _saveDirectory;

  /// The list of images selected by the user.
  final List<File> _selectedImages = [];

  /// The controller for the width text field.
  final _widthController = TextEditingController();

  /// The controller for the height text field.
  final _heightController = TextEditingController();

  /// The controller for the suffix text field.
  final _suffixController = TextEditingController();

  /// The controller for the resolution text field.
  final _resolutionController = TextEditingController();

  /// Whether to scale the image proportionally.
  bool _scaleProportionally = true;

  /// Whether to resample the image.
  bool _resampleImage = true;

  /// Whether to maintain the aspect ratio of the image.
  bool _maintainAspectRatio = true;

  /// The aspect ratio of the first selected image.
  double? _aspectRatio;

  /// The first image selected by the user.
  img.Image? _firstImage;

  /// Whether to overwrite all existing files.
  bool _overwriteAll = false;

  /// Whether the user has manually edited the suffix.
  bool _userEditedSuffix = false;

  /// Whether to include the EXIF data in the resized image.
  bool _includeExif = true;

  /// The output format for the resized image.
  var _outputFormat = ImageResizeOutputFormat.sameAsOriginal;

  /// The focus node for the width text field.
  final _widthFocusNode = FocusNode();

  /// The focus node for the height text field.
  final _heightFocusNode = FocusNode();

  /// The dimension unit type for the fields to use.
  var _dimensionType = DimensionUnitType.pixels;

  @override
  void initState() {
    super.initState();

    _widthFocusNode.addListener(_onWidthFocusChange);
    _heightFocusNode.addListener(_onHeightFocusChange);
    _suffixController.addListener(_handleUserSuffixEdit);
    _resolutionController.addListener(_updateSuffix);
  }

  @override
  void dispose() {
    // Clean up the controllers and focus nodes when the widget is disposed.
    _widthFocusNode.removeListener(_onWidthFocusChange);
    _heightFocusNode.removeListener(_onHeightFocusChange);

    _widthController.dispose();
    _heightController.dispose();
    _suffixController.removeListener(_handleUserSuffixEdit);
    _resolutionController.dispose();

    _widthFocusNode.dispose();
    _heightFocusNode.dispose();

    super.dispose();
  }

  /// Sets [_userEditedSuffix] to true when the user edits the suffix.
  void _handleUserSuffixEdit() {
    _userEditedSuffix = true;
  }

  /// When the width focus changes, if maintain aspect ratio is enabled, the
  /// height is updated to maintain the aspect ratio.
  void _onWidthFocusChange() {
    if (!_widthFocusNode.hasFocus &&
        _maintainAspectRatio &&
        _aspectRatio != null &&
        _widthController.text.isNotEmpty) {
      final width = double.tryParse(_widthController.text);
      if (width != null) {
        final height = (width / _aspectRatio!).round();
        _heightController.text = height.toString();
      }
    }

    if (!_widthFocusNode.hasFocus) {
      Future.delayed(Duration.zero, _updateSuffix);
    }
  }

  /// When the height focus changes, if maintain aspect ratio is enabled, the
  /// width is updated to maintain the aspect ratio.
  void _onHeightFocusChange() {
    if (!_heightFocusNode.hasFocus &&
        _maintainAspectRatio &&
        _aspectRatio != null &&
        _heightController.text.isNotEmpty) {
      final height = double.tryParse(_heightController.text);

      if (height != null) {
        final width = (height * _aspectRatio!).round();
        _widthController.text = width.toString();
      }
    }

    if (!_heightFocusNode.hasFocus) {
      Future.delayed(Duration.zero, _updateSuffix);
    }
  }

  /// Picks images from the device's gallery.
  Future<void> _pickImages() async {
    final imagePicker = ImagePicker();
    final pickedFiles = await imagePicker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      final firstImageFile = File(pickedFiles.first.path);
      final fileBytes = await firstImageFile.readAsBytes();

      final image = img.decodeImage(fileBytes);

      if (image != null) {
        setState(() {
          _firstImage = image;
          _aspectRatio = image.width / image.height;
          print(' _aspectRatio: $_aspectRatio');
          // The image package automatically parses EXIF data. We can access it
          // from the decoded image object.
          final exifData = image.exif;
          // Try to read the DPI from the image's EXIF metadata.
          // The 'XResolution' tag stores the DPI.
          final xResolution = exifData.getTag(tagXResolution);

          if (xResolution != null) {
            print('dpi: ${xResolution.toInt()}');
            // If found, update the _resolutionController with the value.
            _resolutionController.text = xResolution.toInt().toString();
          } else {
            // If no DPI information is in the EXIF data, fall back to a default of 72.
            _resolutionController.text = '72';
          }

          _widthController.text = image.width.toString();
          _heightController.text = image.height.toString();

          _userEditedSuffix = false;
          _updateSuffix();
        });
      }

      setState(() {
        _selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
        _saveDirectory = File(pickedFiles.first.path).parent.path;
      });
    }
  }

  /// Clears the selected images.
  void _clearImageSelections() {
    setState(() {
      _selectedImages.clear();
      _saveDirectory = null;
      _aspectRatio = null;
      _firstImage = null;

      _widthController.clear();
      _heightController.clear();
      _suffixController.clear();
      _userEditedSuffix = false;
    });
  }

  /// Calculates the target pixel dimensions based on the user's input and selected unit.
  (int, int) _calculatePixelDimensions() {
    if (_firstImage == null) return (0, 0);

    final widthInput = double.tryParse(_widthController.text) ?? 0;
    final heightInput = double.tryParse(_heightController.text) ?? 0;

    // Parse the resolution from the controller, defaulting to 72 if empty or invalid.
    var resolution = double.tryParse(_resolutionController.text) ?? 72.0;

    switch (_dimensionType) {
      case DimensionUnitType.percent:
        return (
          (_firstImage!.width * widthInput / 100).round(),
          (_firstImage!.height * heightInput / 100).round(),
        );
      case DimensionUnitType.inches:
        // Convert inches to pixels using the dynamic resolution.
        return (
          (widthInput * resolution).round(),
          (heightInput * resolution).round(),
        );
      case DimensionUnitType.cm:
        // Convert centimeters to pixels. 1 inch = 2.54 cm.
        return (
          (widthInput * resolution / 2.54).round(),
          (heightInput * resolution / 2.54).round(),
        );
      case DimensionUnitType.mm:
        // Convert millimeters to pixels. 1 inch = 25.4 mm.
        return (
          (widthInput * resolution / 25.4).round(),
          (heightInput * resolution / 25.4).round(),
        );
      case DimensionUnitType.pixels:
        // For pixels, the input is used directly.
        return (
          widthInput.round(),
          heightInput.round(),
        );
    }
  }

  /// Updates the filename suffix automatically based on the calculated dimensions.
  /// This is skipped if the user has manually edited the suffix field.
  void _updateSuffix() {
    if (!_userEditedSuffix) {
      // Get the target dimensions in pixels.
      final (width, height) = _calculatePixelDimensions();
      final resolution = int.tryParse(_resolutionController.text) ?? 72;

      if (width > 0 && height > 0) {
        // Construct the suffix string in the format _[width]x[height]_[dpi].
        _suffixController.removeListener(_handleUserSuffixEdit);
        _suffixController.text = '_${width}x${height}_$resolution';
        _suffixController.addListener(_handleUserSuffixEdit);
        print(
          'dimensionType: $_dimensionType, '
          'width: ${_widthController.text}, '
          'height: ${_heightController.text}, '
          'original: ${_firstImage?.width}x${_firstImage?.height}, '
          'calculated: ${width}x$height',
        );
      } else {
        _suffixController.removeListener(_handleUserSuffixEdit);
        _suffixController.text = '';
        _suffixController.addListener(_handleUserSuffixEdit);
      }
    }
  }

  /// Picks images from the cloud.
  Future<void> _pickFromCloud() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'bmp',
        'webp',
      ],
    );
    if (result != null && result.files.isNotEmpty) {
      final firstImageFile = File(result.files.first.path!);
      final fileBytes = await firstImageFile.readAsBytes();
      final image = img.decodeImage(fileBytes);

      if (image != null) {
        setState(() {
          _firstImage = image;
          _aspectRatio = image.width / image.height;
          // The image package automatically parses EXIF data. We can access it
          // from the decoded image object.
          final exifData = image.exif;
          // Try to read the DPI from the image's EXIF metadata.
          // The 'XResolution' tag stores the DPI.
          final xResolution = exifData.getTag(tagXResolution);
          if (xResolution != null) {
            _resolutionController.text = xResolution.toInt().toString();
          } else {
            // If no DPI information is in the EXIF data, fall back to a default of 72.
            _resolutionController.text = '72';
          }
          _widthController.text = image.width.toString();
          _heightController.text = image.height.toString();
          _userEditedSuffix = false;
          _updateSuffix();
        });
      }
      setState(() {
        _selectedImages.addAll(result.paths.map((path) => File(path!)));
        _saveDirectory = File(result.files.first.path!).parent.path;
      });
    }
  }

  /// Resizes the selected images and saves them to the selected directory.
  Future<void> _resizeImages() async {
    if (_selectedImages.isEmpty) {
      _showSnackBar('Please select at least one image.');
      return;
    }

    if (_widthController.text.isEmpty || _heightController.text.isEmpty) {
      _showSnackBar('Please enter width and height.');
      return;
    }

    final widthInput = double.tryParse(_widthController.text);
    final heightInput = double.tryParse(_heightController.text);

    if (widthInput == null || heightInput == null) {
      _showSnackBar('Invalid width or height.');
      return;
    }

    var savePath = _saveDirectory;
    if (savePath == null) {
      final defaultDownloads = await _getDownloadsDirectory();
      if (defaultDownloads != null) {
        savePath = defaultDownloads.path;
      } else {
        await _selectSaveDirectory();
        savePath = _saveDirectory;
        if (savePath == null) {
          _showSnackBar('Please select a save directory.');
          return;
        }
      }
    }

    if (await _requestPermission()) {
      for (final imageFile in _selectedImages) {
        final newFileName = _getNewFileName(
          imageFile.path,
          widthInput.round(),
          heightInput.round(),
          _suffixController.text,
        );
        final newPath = '$savePath/$newFileName';

        final parentDir = File(newPath).parent;
        if (!await parentDir.exists()) {
          try {
            await parentDir.create(recursive: true);
          } catch (e) {
            _showSnackBar('Error: Could not create save directory: $e');
            continue; // Skip this image if directory can't be created
          }
        }

        if (!_overwriteAll && await File(newPath).exists()) {
          if (!mounted) return;
          final result = await showDialog<int>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('File already exists'),
              content: Text(
                'A file named "$newFileName" already exists. Do you want to overwrite it?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(0),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(1),
                  child: const Text('Overwrite'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(2),
                  child: const Text('Overwrite All'),
                ),
              ],
            ),
          );
          if (result == 0) {
            continue;
          } else if (result == 2) {
            setState(() {
              _overwriteAll = true;
            });
          }
          // If the file exists and we're overwriting (result == 1 or _overwriteAll is true)
          // explicitly delete the old file first to avoid permission issues during overwrite.
          try {
            await File(newPath).delete();
          } catch (e) {
            _showSnackBar('Error: Could not delete existing file for overwrite: $e');
            continue; // Skip this image if deletion fails
          }
        }

        final image = img.decodeImage(await imageFile.readAsBytes());
        if (image == null) continue;

        final (width, height) = _calculatePixelDimensions();

        final resizedImage = _scaleProportionally
            ? img.copyResize(
                image,
                width: width,
                height: height,
                interpolation: _resampleImage ? img.Interpolation.cubic : img.Interpolation.nearest,
              )
            : img.copyResize(
                image,
                width: width,
                height: height,
                interpolation: _resampleImage ? img.Interpolation.cubic : img.Interpolation.nearest,
              );

        // Get the resolution from the text controller.
        final resolution = int.tryParse(_resolutionController.text) ?? 72;

        // Create a new EXIF data object.
        final exif = image.exif;
        exif.imageIfd[tagXResolution] = img.IfdValueRational(resolution, 1);
        exif.imageIfd[tagYResolution] = img.IfdValueRational(resolution, 1);
        resizedImage.exif = exif;

        List<int> encodedImage;
        final outputFormat = switch (_outputFormat) {
          ImageResizeOutputFormat.sameAsOriginal =>
            imageFile.path.split('.').last.toLowerCase() == 'png' ? 'png' : 'jpg',
          ImageResizeOutputFormat value => value.name,
        };
        if (outputFormat == 'jpg') {
          encodedImage = img.encodeJpg(resizedImage);
        } else {
          encodedImage = img.PngEncoder(
            filter: img.PngFilter.paeth,
            level: 6,
            pixelDimensions: img.PngPhysicalPixelDimensions.dpi(resolution),
          ).encode(image);
        }

        await File(newPath).writeAsBytes(encodedImage);
      }
      _showSnackBar('Images resized and saved to $savePath');
    }
  }

  /// Requests permission to access the storage.
  Future<bool> _requestPermission() async {
    if (Platform.isMacOS) {
      return true;
    }
    if (Platform.isIOS) {
      var status = await Permission.photos.status;
      if (status.isDenied) {
        status = await Permission.photos.request();
      }
      return status.isGranted;
    } else if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    }
    // Default for other platforms
    return true;
  }

  /// Gets the downloads directory.
  Future<Directory?> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    } else if (Platform.isMacOS) {
      return getDownloadsDirectory();
    }
    return null;
  }

  /// Selects the directory where the resized images will be saved.
  Future<void> _selectSaveDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath(
      initialDirectory: _saveDirectory,
    );
    if (result != null) {
      setState(() {
        _saveDirectory = result;
      });
    }
  }

  /// Gets the new file name for the resized image.
  String _getNewFileName(
    String oldPath,
    int width,
    int height,
    String suffix,
  ) {
    final oldFileName = oldPath.split('/').last;
    final oldExtension = oldFileName.split('.').last;
    final oldNameWithoutExtension = oldFileName.substring(
      0,
      oldFileName.length - oldExtension.length - 1,
    );

    String newExtension;
    if (_outputFormat == ImageResizeOutputFormat.sameAsOriginal) {
      newExtension = oldExtension.toLowerCase();
    } else {
      newExtension = _outputFormat.name;
    }
    print("New filename: $oldNameWithoutExtension$suffix.$newExtension'");

    return '$oldNameWithoutExtension$suffix.$newExtension';
  }

  /// Shows a snackbar with the given [message].
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              _buildHeader(isDarkMode),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSourceSection(theme),
                      const SizedBox(height: 16),
                      DimensionsSection(
                        theme: theme,
                        maintainAspectRatio: _maintainAspectRatio,
                        onAspectRatioChanged: (value) {
                          setState(() {
                            _maintainAspectRatio = value!;
                          });
                        },
                        dimensionType: _dimensionType,
                        onUnitChanged: (value) {
                          setState(() {
                            _dimensionType = value!;
                            _updateSuffix();
                          });
                        },
                        widthController: _widthController,
                        widthFocusNode: _widthFocusNode,
                        heightController: _heightController,
                        heightFocusNode: _heightFocusNode,
                        resolutionController: _resolutionController,
                      ),
                      const SizedBox(height: 16),
                      _buildOptionsSection(theme),
                      const SizedBox(height: 16),
                      _buildOutputSection(theme),
                      const SizedBox(height: 16),
                      _buildSaveLocationSection(theme),
                      const SizedBox(height: 24),
                      _buildResizeButton(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the header of the screen.
  Widget _buildHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Image Resize',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    handleThemeChange: widget.handleThemeChange,
                    themeMode: widget.themeMode,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds the source section of the screen.
  Widget _buildSourceSection(ThemeData theme) {
    return _buildSectionCard(
      title: 'Source',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildIconButton(
                  theme: theme,
                  icon: Icons.photo_library_outlined,
                  label: 'Device',
                  onPressed: _pickImages,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildIconButton(
                  theme: theme,
                  icon: Icons.cloud_upload_outlined,
                  label: 'Cloud',
                  onPressed: _pickFromCloud,
                ),
              ),
            ],
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        _selectedImages[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _clearImageSelections,
                style: ElevatedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                ),
                child: const Text('Clear'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the options section of the screen.
  Widget _buildOptionsSection(ThemeData theme) {
    return _buildSectionCard(
      title: 'Options',
      child: Column(
        children: [
          _buildCheckboxRow(
            label: 'Scale Proportionally',
            value: _scaleProportionally,
            onChanged: (value) {
              setState(() {
                _scaleProportionally = value!;
              });
            },
          ),
          const Divider(),
          _buildCheckboxRow(
            label: 'Resample Image',
            value: _resampleImage,
            onChanged: (value) {
              setState(() {
                _resampleImage = value!;
              });
            },
          ),
          const Divider(),
          _buildCheckboxRow(
            label: 'Include metadata (EXIF)',
            value: _includeExif,
            onChanged: (value) {
              setState(() {
                _includeExif = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Builds the output section of the screen.
  Widget _buildOutputSection(ThemeData theme) {
    return _buildSectionCard(
      title: 'Output',
      child: Column(
        children: [
          TextFieldEntry(
            theme: theme,
            label: 'File Suffix',
            controller: _suffixController,
            placeholder: 'e.g., _resized',
          ),
          const SizedBox(height: 16),
          DropdownEntry<ImageResizeOutputFormat>(
            theme: theme,
            label: 'Output Format',
            value: _outputFormat,
            items: ImageResizeOutputFormat.values,
            onChanged: (value) {
              setState(() {
                _outputFormat = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  /// Builds the save location section of the screen.
  Widget _buildSaveLocationSection(ThemeData theme) {
    return _buildSectionCard(
      title: 'Save Location',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectSaveDirectory,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text('Choose Folder'),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              _saveDirectory ?? 'No directory selected',
              style: theme.textTheme.bodyMedium,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the resize button.
  Widget _buildResizeButton() {
    return ElevatedButton(
      onPressed: _selectedImages.isNotEmpty ? _resizeImages : null,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: const Text('Resize'),
    );
  }

  /// Builds a section card.
  Widget _buildSectionCard({
    required String title,
    required Widget child,
    Widget? headerAccessory,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                if (headerAccessory != null) headerAccessory,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  /// Builds an icon button.
  Widget _buildIconButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  /// Builds a checkbox row.
  Widget _buildCheckboxRow({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(
              height: 20,
              width: 20,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

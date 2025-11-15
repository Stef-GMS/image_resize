import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:exif/exif.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../screens/settings_screen.dart';
import '../widgets/dimensions_section.dart';

class ImageResizeScreen extends StatefulWidget {
  const ImageResizeScreen(
      {super.key, required this.handleThemeChange, required this.themeMode});

  final void Function(ThemeMode) handleThemeChange;
  final ThemeMode themeMode;

  @override
  ImageResizeScreenState createState() => ImageResizeScreenState();
}

class ImageResizeScreenState extends State<ImageResizeScreen> {
  String? _saveDirectory;

  final List<File> _selectedImages = [];
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _suffixController = TextEditingController();
  bool _scaleProportionally = true;
  bool _resampleImage = true;
  bool _maintainAspectRatio = true;
  double? _aspectRatio;
  img.Image? _firstImage;
  bool _overwriteAll = false;
  bool _userEditedSuffix = false;
  bool _includeExif = true;
  String _outputFormat = 'Same as Original';
  int _dpi = 72;

  final _widthFocusNode = FocusNode();
  final _heightFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _widthFocusNode.addListener(_onWidthFocusChange);
    _heightFocusNode.addListener(_onHeightFocusChange);
    _widthController.addListener(_updateSuffix);
    _heightController.addListener(_updateSuffix);
    _suffixController.addListener(() {
      _userEditedSuffix = true;
    });
  }

  @override
  void dispose() {
    _widthFocusNode.removeListener(_onWidthFocusChange);
    _heightFocusNode.removeListener(_onHeightFocusChange);
    _widthController.dispose();
    _heightController.dispose();
    _suffixController.dispose();
    _widthFocusNode.dispose();
    _heightFocusNode.dispose();
    super.dispose();
  }

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
  }

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
  }

  Future<void> _pickImages() async {
    final imagePicker = ImagePicker();
    final pickedFiles = await imagePicker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      final firstImageFile = File(pickedFiles.first.path);
      final fileBytes = await firstImageFile.readAsBytes();
      final image = img.decodeImage(fileBytes);
      final exifData = await readExifFromBytes(fileBytes);

      if (image != null) {
        setState(() {
          _firstImage = image;
          _aspectRatio = image.width / image.height;
          final xResolution = exifData['Image XResolution'];
          if (xResolution != null) {
            _dpi = xResolution.values.firstAsInt();
          } else {
            _dpi = 72;
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

  (int, int) _calculatePixelDimensions() {
    if (_firstImage == null) return (0, 0);

    final widthInput = double.tryParse(_widthController.text) ?? 0;
    final heightInput = double.tryParse(_heightController.text) ?? 0;
    const resolution = 72;

    switch (_dimensionType) {
      case 'percentage':
        return (
          (_firstImage!.width * widthInput / 100).round(),
          (_firstImage!.height * heightInput / 100).round()
        );
      case 'inches':
        return (
          (widthInput * resolution).round(),
          (heightInput * resolution).round()
        );
      case 'cm':
        return (
          (widthInput * resolution / 2.54).round(),
          (heightInput * resolution / 2.54).round()
        );
      case 'mm':
        return (
          (widthInput * resolution / 25.4).round(),
          (heightInput * resolution / 25.4).round()
        );
      case 'pixels':
      default:
        return (widthInput.round(), heightInput.round());
    }
  }

  void _updateSuffix() {
    if (!_userEditedSuffix) {
      final (width, height) = _calculatePixelDimensions();
      if (width > 0 && height > 0) {
        _suffixController.text = '_${width}x${height}_$_dpi';
      } else {
        _suffixController.text = '';
      }
    }
  }

  Future<void> _pickFromCloud() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
    );
    if (result != null && result.files.isNotEmpty) {
      final firstImageFile = File(result.files.first.path!);
      final fileBytes = await firstImageFile.readAsBytes();
      final image = img.decodeImage(fileBytes);
      final exifData = await readExifFromBytes(fileBytes);

      if (image != null) {
        setState(() {
          _firstImage = image;
          _aspectRatio = image.width / image.height;
          final xResolution = exifData['Image XResolution'];
          if (xResolution != null) {
            _dpi = xResolution.values.firstAsInt();
          } else {
            _dpi = 72;
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

  String _dimensionType = 'pixels';
  final Map<String, String> _unitMap = {
    'pixels': 'px',
    'percentage': '%',
    'cm': 'cm',
    'mm': 'mm',
    'inches': 'in'
  };

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
        }

        final image = img.decodeImage(await imageFile.readAsBytes());
        if (image == null) continue;

        final (width, height) = _calculatePixelDimensions();

        final resizedImage = _scaleProportionally
            ? img.copyResize(
                image,
                width: width,
                height: height,
                interpolation:
                    _resampleImage ? img.Interpolation.cubic : img.Interpolation.nearest,
              )
            : img.copyResize(
                image,
                width: width,
                height: height,
                interpolation:
                    _resampleImage ? img.Interpolation.cubic : img.Interpolation.nearest,
              );

        if (_includeExif) {
          resizedImage.exif = image.exif;
        }

        List<int> encodedImage;
        if (_outputFormat == 'jpg') {
          encodedImage = img.encodeJpg(resizedImage);
        } else if (_outputFormat == 'png') {
          encodedImage = img.encodePng(resizedImage);
        } else {
          final oldExtension = imageFile.path.split('.').last.toLowerCase();
          if (oldExtension == 'png') {
            encodedImage = img.encodePng(resizedImage);
          } else {
            encodedImage = img.encodeJpg(resizedImage);
          }
        }

        await File(newPath).writeAsBytes(encodedImage);
      }
      _showSnackBar('Images resized and saved to $savePath');
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isMacOS) {
      return true;
    }
    var status = await Permission.photos.status;
    if (status.isDenied) {
      status = await Permission.photos.request();
    }
    return status.isGranted;
  }

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

  String _getNewFileName(
      String oldPath, int width, int height, String suffix) {
    final oldFileName = oldPath.split('/').last;
    final oldExtension = oldFileName.split('.').last;
    final oldNameWithoutExtension = oldFileName.substring(
      0,
      oldFileName.length - oldExtension.length - 1,
    );

    String newExtension;
    if (_outputFormat == 'Same as Original') {
      newExtension = oldExtension.toLowerCase();
    } else {
      newExtension = _outputFormat.toLowerCase();
    }

    return '$oldNameWithoutExtension$suffix.$newExtension';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

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
                child: ListView(
                  padding: const EdgeInsets.only(top: 8.0),
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
                      unitMap: _unitMap,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Image Resizer',
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
                  backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                ),
                child: const Text('Clear'),
              ),
            ),
          ],
        ],
      ),
    );
  }

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

  Widget _buildOutputSection(ThemeData theme) {
    return _buildSectionCard(
      title: 'Output',
      child: Column(
        children: [
          _buildTextFieldRow(
            theme: theme,
            label: 'File Suffix',
            controller: _suffixController,
            placeholder: 'e.g., _resized',
          ),
          const SizedBox(height: 16),
          _buildDropdownRow(
            theme,
            'Output Format',
            _outputFormat,
            ['Same as Original', 'jpg', 'png'],
            (value) {
              setState(() {
                _outputFormat = value!;
              });
            },
          ),
        ],
      ),
    );
  }

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

  Widget _buildDropdownRow(ThemeData theme, String label, String value,
      List<String> items, ValueChanged<String?> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: items.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldRow({
    required ThemeData theme,
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    String? placeholder,
    String? unit,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: placeholder,
              isDense: true,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (unit != null) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              unit,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
        ],
      ],
    );
  }

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

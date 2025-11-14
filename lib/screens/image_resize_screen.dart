import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class ImageResizeScreen extends StatefulWidget {
  const ImageResizeScreen({super.key});

  @override
  _ImageResizeScreenState createState() => _ImageResizeScreenState();
}

class _ImageResizeScreenState extends State<ImageResizeScreen> {
  String? _saveDirectory;

  final List<File> _selectedImages = [];
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _resolutionController = TextEditingController();
  final _suffixController = TextEditingController();
  bool _scaleProportionally = true;
  bool _resampleImage = true;
  bool _maintainAspectRatio = true;
  double? _aspectRatio;

  final _widthFocusNode = FocusNode();
  final _heightFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _widthFocusNode.addListener(_onWidthFocusChange);
    _heightFocusNode.addListener(_onHeightFocusChange);
  }

  @override
  void dispose() {
    _widthFocusNode.removeListener(_onWidthFocusChange);
    _heightFocusNode.removeListener(_onHeightFocusChange);
    _widthController.dispose();
    _heightController.dispose();
    _resolutionController.dispose();
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
      final image = img.decodeImage(await firstImageFile.readAsBytes());
      if (image != null) {
        setState(() {
          _aspectRatio = image.width / image.height;
        });
      }

      setState(() {
        _selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
        _saveDirectory = File(pickedFiles.first.path).parent.path;
      });
    }
  }

  Future<void> _pickFromCloud() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result != null && result.files.isNotEmpty) {
      final firstImageFile = File(result.files.first.path!);
      final image = img.decodeImage(await firstImageFile.readAsBytes());
      if (image != null) {
        setState(() {
          _aspectRatio = image.width / image.height;
        });
      }
      setState(() {
        _selectedImages.addAll(result.paths.map((path) => File(path!)));
        _saveDirectory = File(result.files.first.path!).parent.path;
      });
    }
  }

  String _dimensionType = 'pixels';

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
    final resolution = int.tryParse(_resolutionController.text) ?? 72;

    if (widthInput == null || heightInput == null) {
      _showSnackBar('Invalid width or height.');
      return;
    }

    if (await _requestPermission()) {
      final savePath = _saveDirectory;
      if (savePath == null) {
        _showSnackBar('Could not determine save directory.');
        return;
      }

      for (final imageFile in _selectedImages) {
        final newFileName = _getNewFileName(
            imageFile.path,
            widthInput.round(),
            heightInput.round(),
            resolution,
            _suffixController.text);
        final newPath = '$savePath/$newFileName';

        if (await File(newPath).exists()) {
          final overwrite = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('File already exists'),
              content: Text(
                  'A file named "$newFileName" already exists. Do you want to overwrite it?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Overwrite'),
                ),
              ],
            ),
          );
          if (overwrite != true) {
            continue;
          }
        }

        final image = img.decodeImage(await imageFile.readAsBytes());
        if (image == null) continue;

        final int width;
        final int height;

        switch (_dimensionType) {
          case 'percent':
            width = (image.width * widthInput / 100).round();
            height = (image.height * heightInput / 100).round();
            break;
          case 'inches':
            width = (widthInput * resolution).round();
            height = (heightInput * resolution).round();
            break;
          case 'cm':
            width = (widthInput * resolution / 2.54).round();
            height = (heightInput * resolution / 2.54).round();
            break;
          case 'mm':
            width = (widthInput * resolution / 25.4).round();
            height = (heightInput * resolution / 25.4).round();
            break;
          case 'points':
            width = (widthInput * resolution / 72).round();
            height = (heightInput * resolution / 72).round();
            break;
          case 'pixels':
          default:
            width = widthInput.round();
            height = heightInput.round();
            break;
        }

        final resizedImage = _scaleProportionally
            ? img.copyResize(image,
                width: width,
                height: height,
                interpolation: _resampleImage
                    ? img.Interpolation.cubic
                    : img.Interpolation.nearest)
            : img.copyResize(image,
                width: width,
                height: height,
                interpolation: _resampleImage
                    ? img.Interpolation.cubic
                    : img.Interpolation.nearest);

        await File(newPath).writeAsBytes(img.encodeJpg(resizedImage));
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
      String oldPath, int width, int height, int resolution, String suffix) {
    final oldFileName = oldPath.split('/').last;
    final oldExtension = oldFileName.split('.').last;
    final oldNameWithoutExtension =
        oldFileName.substring(0, oldFileName.length - oldExtension.length - 1);
    return '$oldNameWithoutExtension$suffix.$oldExtension';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          ElevatedButton(
            onPressed: _pickImages,
            child: const Text('Select from Device'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _pickFromCloud,
            child: const Text('Select from Cloud'),
          ),
          const SizedBox(height: 16),
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.file(_selectedImages[index]),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          DropdownButton<String>(
            value: _dimensionType,
            onChanged: (String? newValue) {
              setState(() {
                _dimensionType = newValue!;
              });
            },
            items: <String>['pixels', 'percent', 'inches', 'cm', 'mm', 'points']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          CheckboxListTile(
            title: const Text('Maintain aspect ratio'),
            value: _maintainAspectRatio,
            onChanged: (value) {
              setState(() {
                _maintainAspectRatio = value!;
              });
            },
          ),
          TextField(
            controller: _widthController,
            focusNode: _widthFocusNode,
            decoration: InputDecoration(labelText: 'Width ($_dimensionType)'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _heightController,
            focusNode: _heightFocusNode,
            decoration: InputDecoration(labelText: 'Height ($_dimensionType)'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _resolutionController,
            decoration: const InputDecoration(labelText: 'Resolution (DPI)'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _suffixController,
            decoration: const InputDecoration(labelText: 'Filename Suffix'),
          ),
          CheckboxListTile(
            title: const Text('Scale proportionally'),
            value: _scaleProportionally,
            onChanged: (value) {
              setState(() {
                _scaleProportionally = value!;
              });
            },
          ),
          CheckboxListTile(
            title: const Text('Resample image'),
            value: _resampleImage,
            onChanged: (value) {
              setState(() {
                _resampleImage = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _selectSaveDirectory,
            child: const Text('Choose Save Location'),
          ),
          if (_saveDirectory != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Save Location: $_saveDirectory'),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                _selectedImages.isNotEmpty ? _resizeImages : null,
            child: const Text('Resize Images'),
          ),
        ],
      ),
    );
  }
}
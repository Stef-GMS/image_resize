
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

  Future<void> _pickImages() async {
    final imagePicker = ImagePicker();
    final pickedFiles = await imagePicker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
        if (_saveDirectory == null) {
          _saveDirectory = File(pickedFiles.first.path).parent.path;
        }
      });
    }
  }

  Future<void> _pickFromCloud() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(result.paths.map((path) => File(path!)));
        if (_saveDirectory == null) {
          _saveDirectory = File(result.files.first.path!).parent.path;
        }
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
      final savePath = _saveDirectory ?? (await _getDownloadsDirectory())?.path;
      if (savePath == null) {
        _showSnackBar('Could not determine save directory.');
        return;
      }

      for (final imageFile in _selectedImages) {
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

        final newFileName = _getNewFileName(
            imageFile.path, width, height, resolution, _suffixController.text);

        final newPath = '$savePath/$newFileName';
        await File(newPath).writeAsBytes(img.encodeJpg(resizedImage));
      }
      _showSnackBar('Images resized and saved to $savePath');
      setState(() {
        _selectedImages.clear();
        _saveDirectory = null;
      });
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
          TextField(
            controller: _widthController,
            decoration: InputDecoration(labelText: 'Width ($_dimensionType)'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _heightController,
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

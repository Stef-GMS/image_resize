import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageResizeScreen extends StatefulWidget {
  const ImageResizeScreen({super.key});

  @override
  ImageResizeScreenState createState() => ImageResizeScreenState();
}

class ImageResizeScreenState extends State<ImageResizeScreen> {
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
  bool _overwriteAll = false;

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
          _widthController.text = image.width.toString();
          _heightController.text = image.height.toString();
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
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
    );
    if (result != null && result.files.isNotEmpty) {
      final firstImageFile = File(result.files.first.path!);
      final image = img.decodeImage(await firstImageFile.readAsBytes());
      if (image != null) {
        setState(() {
          _aspectRatio = image.width / image.height;
          _widthController.text = image.width.toString();
          _heightController.text = image.height.toString();
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
          resolution,
          _suffixController.text,
        );
        final newPath = '$savePath/$newFileName';

        if (!_overwriteAll && await File(newPath).exists()) {
          if (!mounted) return; // Check if the widget is still mounted
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

  String _getNewFileName(String oldPath, int width, int height, int resolution, String suffix) {
    final oldFileName = oldPath.split('/').last;
    final oldExtension = oldFileName.split('.').last;
    final oldNameWithoutExtension = oldFileName.substring(
      0,
      oldFileName.length - oldExtension.length - 1,
    );
    return '$oldNameWithoutExtension$suffix.$oldExtension';
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

  void _clearImageSelections() {
    setState(() {
      _selectedImages.clear();
      _saveDirectory = null;
      _aspectRatio = null;
      _widthController.clear();
      _heightController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Wrap(
              spacing: 8.0, // horizontal spacing
              runSpacing: 8.0, // vertical spacing
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _pickImages,
                  child: const Text('From Device'),
                ),
                ElevatedButton(
                  onPressed: _pickFromCloud,
                  child: const Text('From Cloud'),
                ),
                ElevatedButton(
                  onPressed: _clearImageSelections,
                  child: const Text('Clear All'),
                ),
              ],
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
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
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
                                })
                                .toList(),
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Aspect Ratio'),
                            value: _maintainAspectRatio,
                            onChanged: (value) {
                              setState(() {
                                _maintainAspectRatio = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _widthController,
                            focusNode: _widthFocusNode,
                            decoration: InputDecoration(labelText: 'Width ($_dimensionType)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _heightController,
                            focusNode: _heightFocusNode,
                            decoration: InputDecoration(labelText: 'Height ($_dimensionType)'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Scale Prop.'),
                            value: _scaleProportionally,
                            onChanged: (value) {
                              setState(() {
                                _scaleProportionally = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Resample'),
                            value: _resampleImage,
                            onChanged: (value) {
                              setState(() {
                                _resampleImage = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0, // horizontal spacing
              runSpacing: 8.0, // vertical spacing
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _selectSaveDirectory,
                  child: const Text('Save Location'),
                ),
                ElevatedButton(
                  onPressed: _selectedImages.isNotEmpty ? _resizeImages : null,
                  child: const Text('Resize'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

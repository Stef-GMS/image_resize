
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Image Resizer'),
        ),
        body: const ImageResizeScreen(),
      ),
    );
  }
}

class ImageResizeScreen extends StatefulWidget {
  const ImageResizeScreen({super.key});

  @override
  _ImageResizeScreenState createState() => _ImageResizeScreenState();
}

class _ImageResizeScreenState extends State<ImageResizeScreen> {
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
    setState(() {
      _selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
    });
  }

  Future<void> _pickFromCloud() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        _selectedImages.addAll(result.paths.map((path) => File(path!)));
      });
    }
  }

  Future<void> _resizeImages() async {
    if (_selectedImages.isEmpty) {
      _showSnackBar('Please select at least one image.');
      return;
    }

    if (_widthController.text.isEmpty || _heightController.text.isEmpty) {
      _showSnackBar('Please enter width and height.');
      return;
    }

    final width = int.tryParse(_widthController.text);
    final height = int.tryParse(_heightController.text);
    final resolution = int.tryParse(_resolutionController.text) ?? 72;

    if (width == null || height == null) {
      _showSnackBar('Invalid width or height.');
      return;
    }

    if (await _requestPermission()) {
      for (final imageFile in _selectedImages) {
        final image = img.decodeImage(await imageFile.readAsBytes());
        if (image == null) continue;

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

        final downloadsDir = await _getDownloadsDirectory();
        if (downloadsDir != null) {
          final newPath = '${downloadsDir.path}/$newFileName';
          await File(newPath).writeAsBytes(img.encodeJpg(resizedImage));
        }
      }
      _showSnackBar('Images resized and saved to the appropriate directory.');
      setState(() {
        _selectedImages.clear();
      });
    }
  }

  Future<bool> _requestPermission() async {
    if (Platform.isIOS) {
      var status = await Permission.photos.status;
      if (status.isDenied) {
        status = await Permission.photos.request();
      }
      return status.isGranted;
    } else {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    }
  }

  Future<Directory?> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    }
    return null;
  }

  String _getNewFileName(
      String oldPath, int width, int height, int resolution, String suffix) {
    final oldFileName = oldPath.split('/').last;
    final oldExtension = oldFileName.split('.').last;
    final oldNameWithoutExtension =
        oldFileName.substring(0, oldFileName.length - oldExtension.length - 1);
    return '$oldNameWithoutExtension\_${width}x${height}\_${resolution}dpi$suffix.$oldExtension';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
          TextField(
            controller: _widthController,
            decoration: const InputDecoration(labelText: 'Width'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _heightController,
            decoration: const InputDecoration(labelText: 'Height'),
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
            onPressed: _resizeImages,
            child: const Text('Resize Images'),
          ),
        ],
      ),
    );
  }
}
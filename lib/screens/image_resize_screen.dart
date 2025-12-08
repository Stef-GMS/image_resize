import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_resize/models/dimension_unit_type.dart';
import 'package:image_resize/models/image_resize_output_format.dart';
import 'package:image_resize/models/image_resize_state.dart';
import 'package:image_resize/screens/settings_screen.dart';
import 'package:image_resize/viewmodels/image_resize_viewmodel.dart';
import 'package:image_resize/widgets/dimensions_section.dart';
import 'package:image_resize/widgets/dropdown_entry.dart';
import 'package:image_resize/widgets/text_field_entry.dart';

/// The main screen of the application, refactored to be a ConsumerWidget.
/// It observes the [ImageResizeViewModel] for its state and delegates all
/// business logic to it.
class ImageResizeScreen extends ConsumerStatefulWidget {
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
  ConsumerState<ImageResizeScreen> createState() => _ImageResizeScreenState();
}

class _ImageResizeScreenState extends ConsumerState<ImageResizeScreen> {
  // Text editing controllers are local UI state, managed by the widget.
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _suffixController = TextEditingController();
  final _resolutionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listeners to notify the viewmodel of user input.
    // _suffixController.addListener(() {
    //   ref.read(imageResizeViewModelProvider.notifier).setSuffix(_suffixController.text);
    // });
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources.
    _widthController.dispose();
    _heightController.dispose();
    _suffixController.dispose();
    _resolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Watch the provider to get the current state and notifier.
    final state = ref.watch(imageResizeViewModelProvider);
    final notifier = ref.read(imageResizeViewModelProvider.notifier);

    // Listen for snackbar messages from the viewmodel.
    ref.listen(imageResizeViewModelProvider.select((s) => s.snackbarMessage), (_, message) {
      if (message != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
        notifier.dismissSnackbar();
      }
    });
    
    // Synchronize text controllers with the state from the viewmodel.
    // This is a one-way binding from state -> UI.
    if (_widthController.text != state.width) {
      _widthController.text = state.width;
    }
    if (_heightController.text != state.height) {
      _heightController.text = state.height;
    }
    if (_suffixController.text != state.suffix) {
      _suffixController.text = state.suffix;
    }
    if (_resolutionController.text != state.resolution) {
      _resolutionController.text = state.resolution;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              _buildHeader(isDarkMode),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSourceSection(theme, state, notifier),
                          const SizedBox(height: 16),
                          DimensionsSection(
                            theme: theme,
                            maintainAspectRatio: state.maintainAspectRatio,
                            onAspectRatioChanged: (value) => notifier.setMaintainAspectRatio(value!),
                            dimensionType: state.dimensionType,
                            onUnitChanged: (value) => notifier.setDimensionType(value!),
                            widthController: _widthController,
                            heightController: _heightController,
                            resolutionController: _resolutionController,
                            onWidthChanged: (value) => notifier.setWidth(value),
                            onHeightChanged: (value) => notifier.setHeight(value),
                            onResolutionChanged: (value) => notifier.setResolution(value),
                          ),
                          const SizedBox(height: 16),
                          _buildOptionsSection(theme, state, notifier),
                          const SizedBox(height: 16),
                          _buildOutputSection(theme, state, notifier),
                          const SizedBox(height: 16),
                          _buildSaveLocationSection(theme, state, notifier),
                          const SizedBox(height: 24),
                          _buildResizeButton(state, notifier),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    if (state.isResizing)
                      Container(
                        color: const Color(0x80000000),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // region Build Methods (now pure UI)
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

  Widget _buildSourceSection(ThemeData theme, ImageResizeState state, ImageResizeViewModel notifier) {
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
                  onPressed: notifier.pickImages,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildIconButton(
                  theme: theme,
                  icon: Icons.cloud_upload_outlined,
                  label: 'Cloud',
                  onPressed: notifier.pickFromCloud,
                ),
              ),
            ],
          ),
          if (state.selectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.selectedImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        state.selectedImages[index],
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
                onPressed: notifier.clearImageSelections,
                style: ElevatedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  backgroundColor: theme.colorScheme.error.withAlpha(25),
                ),
                child: const Text('Clear'),
              ),
            ),
          ],
        ],
      ),
    );
  }

    Widget _buildOptionsSection(ThemeData theme, ImageResizeState state, ImageResizeViewModel notifier) {
    return _buildSectionCard(
      title: 'Options',
      child: Column(
        children: [
          _buildCheckboxRow(
            label: 'Scale Proportionally',
            value: state.scaleProportionally,
            onChanged: (value) => notifier.setScaleProportionally(value!),
          ),
          const Divider(),
          _buildCheckboxRow(
            label: 'Resample Image',
            value: state.resampleImage,
            onChanged: (value) => notifier.setResampleImage(value!),
          ),
          const Divider(),
          _buildCheckboxRow(
            label: 'Include metadata (EXIF)',
            value: state.includeExif,
            onChanged: (value) => notifier.setIncludeExif(value!),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputSection(ThemeData theme, ImageResizeState state, ImageResizeViewModel notifier) {
    return _buildSectionCard(
      title: 'Output',
      child: Column(
        children: [
          TextFieldEntry(
            theme: theme,
            label: 'File Suffix',
            controller: _suffixController,
            placeholder: 'e.g., _resized',
            onChanged: (value) => notifier.setSuffix(value),
          ),
          const SizedBox(height: 16),
          DropdownEntry<ImageResizeOutputFormat>(
            theme: theme,
            label: 'Output Format',
            value: state.outputFormat,
            items: ImageResizeOutputFormat.values,
            onChanged: (value) => notifier.setOutputFormat(value!),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveLocationSection(ThemeData theme, ImageResizeState state, ImageResizeViewModel notifier) {
    return _buildSectionCard(
      title: 'Save Location',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: notifier.selectSaveDirectory,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
              state.saveDirectory ?? 'No directory selected',
              style: theme.textTheme.bodyMedium,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResizeButton(ImageResizeState state, ImageResizeViewModel notifier) {
    return ElevatedButton(
      onPressed: state.selectedImages.isNotEmpty && !state.isResizing ? notifier.resizeImages : null,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      child: const Text('Resize'),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
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
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            SizedBox(
              height: 20,
              width: 20,
              child: Checkbox(value: value, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
  // endregion
}

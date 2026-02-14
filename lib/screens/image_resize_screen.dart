import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_resize/models/file_conflict_state.dart';
import 'package:image_resize/viewmodels/image_resize_viewmodel.dart';
import 'package:image_resize/widgets/dimensions_section.dart';
import 'package:image_resize/widgets/file_conflict_dialog.dart';
import 'package:image_resize/widgets/header_section.dart';
import 'package:image_resize/widgets/options_section.dart';
import 'package:image_resize/widgets/output_section.dart';
import 'package:image_resize/widgets/resize_button_section.dart';
import 'package:image_resize/widgets/save_location_section.dart';
import 'package:image_resize/widgets/source_section.dart';

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
  final _baseFilenameController = TextEditingController();
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
    _baseFilenameController.dispose();
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

    // Listen for file conflicts and show dialog
    ref.listen(imageResizeViewModelProvider.select((s) => s.fileConflictState), (_, conflictState) {
      if (conflictState == FileConflictState.pending) {
        final conflictInfo = ref.read(imageResizeViewModelProvider).conflictInfo;
        if (conflictInfo != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => FileConflictDialog(
              filename: conflictInfo.filename,
              onOverwrite: () {
                Navigator.of(context).pop();
                notifier.setFileConflictOverwrite();
                notifier.resizeImages(); // Retry with overwrite enabled
              },
              onAddSequence: () {
                Navigator.of(context).pop();
                notifier.setFileConflictAddSequence();
                notifier.resizeImages(); // Retry with sequence numbering enabled
              },
              onCancel: () {
                Navigator.of(context).pop();
                notifier.setFileConflictResolved();
              },
            ),
          );
        }
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
    if (_baseFilenameController.text != state.baseFilename) {
      _baseFilenameController.text = state.baseFilename;
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
              HeaderSection(
                isDarkMode: isDarkMode,
                handleThemeChange: widget.handleThemeChange,
                themeMode: widget.themeMode,
              ),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SourceSection(theme: theme),
                          const SizedBox(height: 16),
                          DimensionsSection(
                            theme: theme,
                            maintainAspectRatio: state.maintainAspectRatio,
                            onAspectRatioChanged: (value) =>
                                notifier.setMaintainAspectRatio(value!),
                            dimensionType: state.dimensionType,
                            onUnitChanged: (value) => notifier.setDimensionType(value),
                            widthController: _widthController,
                            heightController: _heightController,
                            resolutionController: _resolutionController,
                            onWidthChanged: (value) => notifier.setWidth(value),
                            onHeightChanged: (value) => notifier.setHeight(value),
                            onResolutionChanged: (value) => notifier.setResolution(value),
                          ),
                          const SizedBox(height: 16),
                          OptionsSection(theme: theme),
                          const SizedBox(height: 16),
                          OutputSection(
                            theme: theme,
                            suffixController: _suffixController,
                            baseFilenameController: _baseFilenameController,
                          ),
                          const SizedBox(height: 16),
                          SaveLocationSection(theme: theme),
                          const SizedBox(height: 24),
                          ResizeButtonSection(),
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

  // endregion
}

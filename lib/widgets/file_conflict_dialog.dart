import 'package:flutter/material.dart';

enum FileConflictChoice { none, overwrite, addSequence }

/// Dialog shown when file conflicts are detected during save.
class FileConflictDialog extends StatefulWidget {
  const FileConflictDialog({
    super.key,
    required this.filename,
    required this.onOverwrite,
    required this.onAddSequence,
    required this.onCancel,
  });

  final String filename;
  final VoidCallback onOverwrite;
  final VoidCallback onAddSequence;
  final VoidCallback onCancel;

  @override
  State<FileConflictDialog> createState() => _FileConflictDialogState();
}

class _FileConflictDialogState extends State<FileConflictDialog> {
  FileConflictChoice _selectedChoice = FileConflictChoice.none;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('File Conflict'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The following file(s) already exist:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            widget.filename,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'How would you like to proceed?',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          RadioListTile<FileConflictChoice>(
            title: const Text('Overwrite All'),
            value: FileConflictChoice.overwrite,
            groupValue: _selectedChoice,
            onChanged: (value) {
              setState(() {
                _selectedChoice = value!;
              });
            },
          ),
          RadioListTile<FileConflictChoice>(
            title: const Text('Add Sequence Numbers'),
            value: FileConflictChoice.addSequence,
            groupValue: _selectedChoice,
            onChanged: (value) {
              setState(() {
                _selectedChoice = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedChoice == FileConflictChoice.none
              ? null
              : () {
                  if (_selectedChoice == FileConflictChoice.overwrite) {
                    widget.onOverwrite();
                  } else if (_selectedChoice == FileConflictChoice.addSequence) {
                    widget.onAddSequence();
                  }
                },
          child: const Text('Resize'),
        ),
      ],
    );
  }
}


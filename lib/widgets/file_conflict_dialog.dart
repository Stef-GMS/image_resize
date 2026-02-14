import 'package:flutter/material.dart';

/// Dialog shown when file conflicts are detected during save.
class FileConflictDialog extends StatelessWidget {
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
            filename,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'How would you like to proceed?',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onAddSequence,
          child: const Text('Add Sequence Numbers'),
        ),
        FilledButton(
          onPressed: onOverwrite,
          child: const Text('Overwrite All'),
        ),
      ],
    );
  }
}


/// Information about a file conflict that needs user resolution.
class FileConflictInfo {
  /// The filename that already exists
  final String filename;

  /// The full path where the file would be saved
  final String fullPath;

  /// Creates a [FileConflictInfo].
  const FileConflictInfo({
    required this.filename,
    required this.fullPath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileConflictInfo &&
          runtimeType == other.runtimeType &&
          filename == other.filename &&
          fullPath == other.fullPath;

  @override
  int get hashCode => filename.hashCode ^ fullPath.hashCode;
}


/// Enum representing the action to take when a file already exists.
enum FileConflictAction {
  /// Overwrite the existing file
  overwrite,

  /// Add a sequence number to the filename (e.g., filename_1.jpg)
  addSequenceNumber,

  /// Skip saving this file
  skip,

  /// Apply the chosen action to all remaining conflicts
  applyToAll,
}


/// Represents the state of file conflict detection
enum FileConflictState {
  /// No conflict detected or conflict has been resolved
  none,
  
  /// Conflict detected, waiting for user to choose action
  pending,
  
  /// User chose to overwrite all conflicting files
  overwrite,
  
  /// User chose to add sequence numbers to avoid conflicts
  addSequence,
}


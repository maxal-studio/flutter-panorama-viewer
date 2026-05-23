import 'selection.dart';

/// A group that maintains the relationship between an original selection and its processed parts
class SelectionGroup {
  /// The original selection drawn by the user
  final Selection original;

  /// The processed selections (split parts) derived from the original
  final List<Selection> processed;

  /// Creates a new selection group
  ///
  /// @param original The original selection drawn by the user
  /// @param processed The processed selections (split parts) derived from the original
  SelectionGroup({
    required this.original,
    required this.processed,
  });

  /// Whether this selection was split into multiple parts
  bool get wasSplit => processed.length > 1;

  /// Returns either the original or processed selections based on debug mode
  List<Selection> getSelections(bool debugMode) {
    return debugMode ? processed : [original];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectionGroup &&
        other.original == original &&
        _listEquals(other.processed, processed);
  }

  @override
  int get hashCode {
    return original.hashCode ^ _listHashCode(processed);
  }

  // Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Helper method to compute hash code for a list
  int _listHashCode<T>(List<T> list) {
    int result = 1;
    for (var element in list) {
      result = 31 * result + (element?.hashCode ?? 0);
    }
    return result;
  }
}

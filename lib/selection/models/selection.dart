import 'lat_lng.dart';
import 'selection_style.dart';
import 'selection_type.dart';

/// Represents a selection drawn by the user
class Selection {
  /// Unique identifier for the selection
  final String id;

  /// The type of selection
  final SelectionType type;

  /// The points that make up the selection
  final List<LatLng> points;

  /// When the selection was created
  final DateTime createdAt;

  /// The visual style of the selection
  final SelectionStyle style;

  /// Creates a new selection
  ///
  /// @param id Optional unique identifier, defaults to a timestamp
  /// @param type The type of selection
  /// @param points The points that make up the selection
  /// @param style The visual style of the selection
  Selection({
    String? id,
    required this.type,
    required this.points,
    SelectionStyle? style,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = DateTime.now(),
        style = style ?? const SelectionStyle();

  /// Creates a copy of this selection with the given fields replaced with new values
  Selection copyWith({
    String? id,
    SelectionType? type,
    List<LatLng>? points,
    SelectionStyle? style,
  }) {
    return Selection(
      id: id ?? this.id,
      type: type ?? this.type,
      points: points ?? List.from(this.points),
      style: style ?? this.style,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Selection &&
        other.id == id &&
        other.type == type &&
        _listEquals(other.points, points) &&
        other.style == style;
  }

  @override
  int get hashCode {
    return id.hashCode ^ type.hashCode ^ _listHashCode(points) ^ style.hashCode;
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

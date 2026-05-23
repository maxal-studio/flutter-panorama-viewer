import 'package:flutter/material.dart';

/// Defines the visual style of a selection
class SelectionStyle {
  /// The width of the stroke in logical pixels
  final double strokeWidth;

  /// The color of the stroke
  final Color strokeColor;

  /// The fill color of the selection, or null for no fill
  final Color? fillColor;

  /// The dash pattern for the stroke, or null for a solid line
  final List<double>? dashPattern;

  /// Whether to close the shape by connecting the last point to the first
  final bool closeShape;

  /// Creates a new selection style
  ///
  /// @param strokeWidth The width of the stroke in logical pixels
  /// @param strokeColor The color of the stroke
  /// @param fillColor The fill color of the selection, or null for no fill
  /// @param dashPattern The dash pattern for the stroke, or null for a solid line
  /// @param closeShape Whether to close the shape by connecting the last point to the first
  const SelectionStyle({
    this.strokeWidth = 2.0,
    this.strokeColor = Colors.red,
    this.fillColor,
    this.dashPattern,
    this.closeShape = false,
  });

  /// Creates a copy of this selection style with the given fields replaced with new values
  SelectionStyle copyWith({
    double? strokeWidth,
    Color? strokeColor,
    Color? fillColor,
    List<double>? dashPattern,
    bool? closeShape,
  }) {
    return SelectionStyle(
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeColor: strokeColor ?? this.strokeColor,
      fillColor: fillColor ?? this.fillColor,
      dashPattern: dashPattern ?? this.dashPattern,
      closeShape: closeShape ?? this.closeShape,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectionStyle &&
        other.strokeWidth == strokeWidth &&
        other.strokeColor == strokeColor &&
        other.fillColor == fillColor &&
        _listEquals(other.dashPattern, dashPattern) &&
        other.closeShape == closeShape;
  }

  @override
  int get hashCode {
    return strokeWidth.hashCode ^
        strokeColor.hashCode ^
        fillColor.hashCode ^
        _listHashCode(dashPattern) ^
        closeShape.hashCode;
  }

  // Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  // Helper method to compute hash code for a list
  int _listHashCode<T>(List<T>? list) {
    if (list == null) return 0;
    int result = 1;
    for (var element in list) {
      result = 31 * result + (element?.hashCode ?? 0);
    }
    return result;
  }
}

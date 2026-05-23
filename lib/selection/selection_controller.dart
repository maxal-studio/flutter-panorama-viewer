import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import '../utils/panorama_utils.dart';
import 'models/index.dart';
import 'services/selection_processor.dart';
export 'models/index.dart';

// Move typedef outside the class
typedef SelectionUpdateCallback = void Function(
  int selectionsCount,
  int? selectionsLeft,
  List<Selection> selections,
);

class SelectionController extends ChangeNotifier {
  // Remove animation and interaction related fields
  SelectionType _currentType = SelectionType.none;
  SelectionType? _lastActiveType;
  Selection? _currentSelection;
  // Replace selections list with a list of SelectionGroup objects
  List<SelectionGroup> _selectionGroups = [];
  SelectionState _state = SelectionState.idle;
  int? _maxSelections;
  // ignore: prefer_final_fields
  bool _isSelectionActive = true;
  SelectionStyle _currentStyle = const SelectionStyle();
  final Map<SelectionType, SelectionStyle> _stylesByType = {};
  CoordinateConverter? _converter;
  final SelectionUpdateCallback? onSelectionUpdate;
  // Add option to control wrap-around splitting (default: true)
  bool _splitWrapAroundPolygon = true;
  // Add debug mode flag (default: false)
  bool _debugMode = false;

  // Minimum distance between points to avoid too many points
  static const double minDistanceThreshold = 10.0;

  // Stream controller for selection state changes
  final _stateController = StreamController<SelectionState>.broadcast();
  Stream<SelectionState> get stateStream => _stateController.stream;

  SelectionType get currentType => _currentType;
  SelectionState get currentState => _state;
  bool get isDrawing => _state == SelectionState.drawing;
  Selection? get currentSelection => _currentSelection;

  // Update selections getter to return either original or processed selections
  List<Selection> get selections {
    List<Selection> result = [];
    for (final group in _selectionGroups) {
      result.addAll(group.getSelections(_debugMode));
    }
    return List.unmodifiable(result);
  }

  // Add getter for the original selections (always returns originals regardless of debug mode)
  List<Selection> get originalSelections {
    return List.unmodifiable(
        _selectionGroups.map((group) => group.original).toList());
  }

  // Add getter for the processed selections (always returns processed regardless of debug mode)
  List<Selection> get processedSelections {
    List<Selection> result = [];
    for (final group in _selectionGroups) {
      result.addAll(group.processed);
    }
    return List.unmodifiable(result);
  }

  // Add getter for debug mode
  bool get debugMode => _debugMode;

  // Add setter for debug mode
  set debugMode(bool value) {
    if (_debugMode != value) {
      _debugMode = value;
      notifyListeners();
    }
  }

  // Add getter for the wrap-around splitting option
  bool get splitWrapAroundPolygon => _splitWrapAroundPolygon;

  // Add constructor to optionally set max selections
  SelectionController({
    int? maxSelections,
    bool enabled = true,
    SelectionType selectionType = SelectionType.none,
    SelectionStyle? selectionStyle, // Add selection style
    this.onSelectionUpdate,
    bool splitWrapAroundPolygon = true, // Add parameter to constructor
    bool debugMode = false, // Add debug mode parameter
  })  : _maxSelections = maxSelections,
        _isSelectionActive = enabled,
        _currentType = selectionType,
        _currentStyle =
            selectionStyle ?? const SelectionStyle(), // Initialize style
        _splitWrapAroundPolygon =
            splitWrapAroundPolygon, // Initialize from parameter
        _debugMode = debugMode, // Initialize debug mode
        _lastActiveType =
            selectionType != SelectionType.none ? selectionType : null;

  // Add setter for the wrap-around splitting option
  set splitWrapAroundPolygon(bool value) {
    if (_splitWrapAroundPolygon != value) {
      _splitWrapAroundPolygon = value;
      notifyListeners();
    }
  }

  // Add a separate method to explicitly set the option
  void setSplitWrapAroundPolygon(bool enable) {
    splitWrapAroundPolygon = enable;
  }

  // Add a method to set debug mode
  void setDebugMode(bool enable) {
    debugMode = enable;
  }

  // Add getter to check if max selections reached
  bool get canAddMoreSelections =>
      _maxSelections == null || _selectionGroups.length < _maxSelections!;

  bool get isSelectionActive => _isSelectionActive;
  bool get canSelect =>
      _isSelectionActive && _currentType != SelectionType.none;

  // Single source of truth for interaction prevention
  bool get shouldPreventPanoramaInteraction =>
      _currentType != SelectionType.none;

  void setSelectionType(SelectionType type) {
    // Always update state and notify even if type is the same
    // This ensures panorama interaction state is properly updated after image changes
    _currentType = type;
    _lastActiveType = type != SelectionType.none ? type : _lastActiveType;
    clearCurrentSelection();

    // Force state update
    _state = SelectionState.idle;
    _stateController.add(_state);

    notifyListeners();
  }

  void setSelectionStyle(SelectionStyle style, {SelectionType? forType}) {
    if (forType != null) {
      _stylesByType[forType] = style;
      if (forType == _currentType) {
        _currentStyle = style;
      }
    } else {
      _currentStyle = style;
    }
    notifyListeners();
  }

  void setConverter(CoordinateConverter converter) {
    _converter = converter;
    // Notify listeners when converter is updated to ensure UI rebuilds
    notifyListeners();
  }

  void startDrawing(Offset point) {
    if (_currentType == SelectionType.none || _converter == null) return;
    if (!canAddMoreSelections) {
      return;
    }

    final Vector3 o = _converter!.positionToLatLon(point.dx, point.dy);
    final latLng = LatLng(
      _converter!.degrees(-o.y),
      _converter!.degrees(o.x),
    );

    _state = SelectionState.drawing;
    _currentSelection = Selection(
      type: _currentType,
      points: [latLng],
      style: _stylesByType[_currentType] ?? _currentStyle,
    );

    _stateController.add(_state);
    notifyListeners();
  }

  void addPoint(Offset point) {
    if (!isDrawing || _currentSelection == null || _converter == null) return;

    final Vector3 o = _converter!.positionToLatLon(point.dx, point.dy);
    final latLng = LatLng(
      _converter!.degrees(-o.y),
      _converter!.degrees(o.x),
    );

    final points = _currentSelection!.points;
    if (points.isEmpty) {
      points.add(latLng);
    } else {
      final lastLatLng = points.last;
      final lastPos = _converter!.positionFromLatLon(
        lastLatLng.latitude,
        lastLatLng.longitude,
      );
      final distance = (Offset(lastPos.x, lastPos.y) - point).distance;

      if (distance >= minDistanceThreshold) {
        points.add(latLng);
      }
    }
    notifyListeners();
  }

  void completeDrawing() {
    if (!isDrawing || _currentSelection == null) return;

    // Ensure we have at least 3 points for a valid polygon
    if (_currentSelection!.points.length < 3) {
      clearCurrentSelection();
      return;
    }

    // Create a copy of the current selection as the original
    final originalSelection = Selection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _currentSelection!.type,
      points: List<LatLng>.from(_currentSelection!.points),
      style: _currentSelection!.style,
    );

    // Process the selection if wrap-around splitting is enabled
    List<Selection> processedSelections;
    if (_splitWrapAroundPolygon) {
      processedSelections =
          SelectionProcessor.splitWrapAroundSelection(originalSelection);
    } else {
      processedSelections = [originalSelection];
    }

    // Create a selection group with the original and processed selections
    final selectionGroup = SelectionGroup(
      original: originalSelection,
      processed: processedSelections,
    );

    // Add the selection group to the list
    _selectionGroups.add(selectionGroup);

    // Reset state
    _currentSelection = null;
    _state = SelectionState.completed;
    _stateController.add(_state);

    // Notify about the selection update
    _notifySelectionUpdate();

    notifyListeners();
  }

  void clearCurrentSelection() {
    _currentSelection = null;
    _state = SelectionState.idle;
    _stateController.add(_state);
    // Don't change movement state here
    notifyListeners();
  }

  void clearAllSelections() {
    _selectionGroups.clear();
    _currentSelection = null;
    _state = SelectionState.idle;
    _stateController.add(_state);
    _notifySelectionUpdate(); // Notify after clearing
    notifyListeners();
  }

  void undoLastSelection() {
    if (_selectionGroups.isNotEmpty) {
      _selectionGroups.removeLast();
      _state = SelectionState.idle;
      _stateController.add(_state);
      _notifySelectionUpdate(); // Notify after removing
      notifyListeners();
    }
  }

  List<List<LatLng>> getSelectedCoordinatesLatLng() {
    List<List<LatLng>> allCoordinates = [];

    // Add points from completed selections (use processed selections for coordinates)
    for (final selection in processedSelections) {
      allCoordinates.add(List<LatLng>.from(selection.points));
    }

    return allCoordinates;
  }

  List<List<Offset>> getSelectedCoordinatesScreen() {
    if (_converter == null) return [];

    List<List<Offset>> allCoordinates = [];

    // Convert points from completed selections (use processed selections for coordinates)
    for (final selection in processedSelections) {
      allCoordinates.add(
        selection.points.map((latLng) {
          final pos = _converter!.positionFromLatLon(
            latLng.latitude,
            latLng.longitude,
          );
          return Offset(pos.x, pos.y);
        }).toList(),
      );
    }

    return allCoordinates;
  }

  /// Get selections as image coordinates
  ///
  /// This method automatically gets the image size from the converter's scene
  /// and converts the selected points to image coordinates.
  /// If the image size cannot be determined, it returns an empty list.
  ///
  /// @return List of lists of image coordinates, or empty list if image size cannot be determined
  List<List<Offset>> getSelectedCoordinatesImage() {
    if (_converter == null) return [];

    // Try to get the image size from the converter's scene
    final scene = _converter!.scene;
    if (scene.texture == null) return [];

    final imageSize = Size(
      scene.texture!.width.toDouble(),
      scene.texture!.height.toDouble(),
    );

    List<List<Offset>> allCoordinates = [];

    // Convert points from completed selections (use processed selections for coordinates)
    for (final selection in processedSelections) {
      allCoordinates.add(
        _converter!.latLngListToImageCoordinates(selection.points, imageSize),
      );
    }

    return allCoordinates;
  }

  /// Convert a screen coordinate to a LatLng
  ///
  /// This method converts a screen coordinate to a LatLng using the converter's
  /// positionToLatLon method. If the converter is not set, it returns a LatLng
  /// with coordinates (0, 0).
  ///
  /// @param point The screen coordinate to convert
  /// @return The converted LatLng
  LatLng screenCoordinateToLatLng(Offset point) {
    if (_converter == null) return const LatLng(0, 0);

    final Vector3 o = _converter!.positionToLatLon(point.dx, point.dy);
    return LatLng(
      _converter!.degrees(-o.y),
      _converter!.degrees(o.x),
    );
  }

  /// Convert a LatLng to a screen coordinate
  ///
  /// This method converts a LatLng to a screen coordinate using the converter's
  /// positionFromLatLon method. If the converter is not set, it returns an Offset
  /// with coordinates (0, 0).
  ///
  /// @param latLng The LatLng to convert
  /// @return The converted screen coordinate
  Offset latLngToScreenCoordinate(LatLng latLng) {
    if (_converter == null) return Offset.zero;

    final pos = _converter!.positionFromLatLon(
      latLng.latitude,
      latLng.longitude,
    );
    return Offset(pos.x, pos.y);
  }

  /// Convert a list of LatLng to a list of screen coordinates
  ///
  /// This method converts a list of LatLng to a list of screen coordinates using
  /// the converter's positionFromLatLon method. If the converter is not set, it
  /// returns an empty list.
  ///
  /// @param latLngs The list of LatLng to convert
  /// @return The converted list of screen coordinates
  List<Offset> latLngListToScreenCoordinates(List<LatLng> latLngs) {
    if (_converter == null) return [];

    return latLngs.map((latLng) {
      final pos = _converter!.positionFromLatLon(
        latLng.latitude,
        latLng.longitude,
      );
      return Offset(pos.x, pos.y);
    }).toList();
  }

  /// Convert a list of screen coordinates to a list of LatLng
  ///
  /// This method converts a list of screen coordinates to a list of LatLng using
  /// the converter's positionToLatLon method. If the converter is not set, it
  /// returns an empty list.
  ///
  /// @param points The list of screen coordinates to convert
  /// @return The converted list of LatLng
  List<LatLng> screenCoordinatesToLatLngList(List<Offset> points) {
    if (_converter == null) return [];

    return points.map((point) {
      final Vector3 o = _converter!.positionToLatLon(point.dx, point.dy);
      return LatLng(
        _converter!.degrees(-o.y),
        _converter!.degrees(o.x),
      );
    }).toList();
  }

  /// Convert a list of image coordinates to a list of LatLng
  ///
  /// This method converts a list of image coordinates to a list of LatLng using
  /// the converter's imageCoordinatesToLatLngList method. If the converter is not
  /// set, it returns an empty list.
  ///
  /// @param points The list of image coordinates to convert
  /// @param imageSize The size of the image
  /// @return The converted list of LatLng
  List<LatLng> imageCoordinatesToLatLngList(
      List<Offset> points, Size imageSize) {
    if (_converter == null) return [];
    return _converter!.imageCoordinatesToLatLngList(points, imageSize);
  }

  // Add method to change max selections
  void setMaxSelections(int? maxSelections) {
    _maxSelections = maxSelections;
    // If current selections exceed new max, trim the list
    if (_maxSelections != null && _selectionGroups.length > _maxSelections!) {
      _selectionGroups = _selectionGroups.sublist(0, _maxSelections!);
      notifyListeners();
    }
  }

  // Add method to explicitly reset selection state
  void resetSelection() {
    setSelectionType(SelectionType.none);
  }

  // Helper method to notify about selection changes
  void _notifySelectionUpdate() {
    onSelectionUpdate?.call(
      _selectionGroups.length,
      _maxSelections != null ? _maxSelections! - _selectionGroups.length : null,
      List.unmodifiable(
          processedSelections), // Always return processed selections to the user
    );
  }

  /// Get the processed selections for the user
  ///
  /// This method returns the processed selections (split polygons) for the user.
  /// These are the selections that should be used for processing, not for display.
  ///
  /// @return List of processed selections
  List<Selection> getProcessedSelections() {
    return processedSelections;
  }

  /// Get the original selections for the user
  ///
  /// This method returns the original selections (unsplit polygons) for the user.
  /// These are the selections that were drawn by the user.
  ///
  /// @return List of original selections
  List<Selection> getOriginalSelections() {
    return originalSelections;
  }

  /// Get the selection groups
  ///
  /// This method returns the selection groups, which contain both the original
  /// and processed selections.
  ///
  /// @return List of selection groups
  List<SelectionGroup> getSelectionGroups() {
    return List.unmodifiable(_selectionGroups);
  }

  /// Check if a selection has been split
  ///
  /// This method checks if a selection has been split into multiple parts.
  ///
  /// @param originalSelectionId The ID of the original selection
  /// @return True if the selection has been split, false otherwise
  bool isSelectionSplit(String originalSelectionId) {
    for (final group in _selectionGroups) {
      if (group.original.id == originalSelectionId) {
        return group.wasSplit;
      }
    }
    return false;
  }

  /// Get the number of parts a selection has been split into
  ///
  /// This method returns the number of parts a selection has been split into.
  /// If the selection has not been split, it returns 1.
  ///
  /// @param originalSelectionId The ID of the original selection
  /// @return The number of parts the selection has been split into
  int getSelectionPartCount(String originalSelectionId) {
    for (final group in _selectionGroups) {
      if (group.original.id == originalSelectionId) {
        return group.processed.length;
      }
    }
    return 0;
  }

  /// Get the processed selections for a specific original selection
  ///
  /// This method returns the processed selections for a specific original selection.
  ///
  /// @param originalSelectionId The ID of the original selection
  /// @return List of processed selections for the original selection
  List<Selection> getProcessedSelectionsForOriginal(
      String originalSelectionId) {
    for (final group in _selectionGroups) {
      if (group.original.id == originalSelectionId) {
        return List.unmodifiable(group.processed);
      }
    }
    return [];
  }

  @override
  void dispose() {
    _stateController.close();
    super.dispose();
  }
}

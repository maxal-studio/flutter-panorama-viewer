# Selection Controller

The Selection Controller allows users to make selections on the panoramic image. This can be useful for marking areas of interest, creating interactive regions, or analyzing specific parts of the panorama.

## Basic Usage

To enable selections in your panorama:

1. Create a SelectionController
2. Configure selection parameters
3. Add it to your PanoramaViewer

```dart
final SelectionController _selectionController = SelectionController(
  maxSelections: 2,
  selectionType: SelectionType.none,
  selectionStyle: SelectionStyle(
    strokeColor: Colors.yellow,
    strokeWidth: 2,
    fillColor: Colors.white.withOpacity(0.5),
    dashPattern: [5, 5],
  ),
  onSelectionUpdate: (count, remaining, selections) {
    print('Selections made: $count');
    print('Selections remaining: $remaining');
    print('All selections: $selections');
  },
);

// In your widget
PanoramaViewer(
  selectionController: _selectionController,
  child: Image.asset('your_panorama.jpg'),
)
```

## Selection Types

The package supports different types of selections:

- `SelectionType.none`: No selection active
- `SelectionType.freeDraw`: Free-form drawing selection

## Selection Style

You can customize the appearance of selections using SelectionStyle:

```dart
SelectionStyle(
  strokeColor: Colors.yellow,    // Border color
  strokeWidth: 2,               // Border width
  fillColor: Colors.white.withOpacity(0.5), // Fill color
  dashPattern: [5, 5],         // Dash pattern for the border
)
```

## Managing Selections

The SelectionController provides several methods to manage selections:

```dart
// Start a new selection
_selectionController.setSelectionType(SelectionType.freeDraw);

// Clear all selections
_selectionController.clearAllSelections();

// Undo last selection
_selectionController.undoLastSelection();

// Get current selections
List<Selection> selections = _selectionController.selections;
```

## Selection Events

Monitor selection changes using the onSelectionUpdate callback:

```dart
SelectionController(
  onSelectionUpdate: (count, remaining, selections) {
    // count: Number of selections made
    // remaining: Number of selections still available
    // selections: List of all current selections
  },
)
```

## Coordinate System

Selections use a latitude/longitude coordinate system:

```dart
class LatLng {
  final double latitude;   // -90 to 90 degrees
  final double longitude;  // -180 to 180 degrees
}
```

## Example Implementation

Here's a complete example showing how to implement selection functionality:

```dart
class _MyPanoramaState extends State<MyPanorama> {
  late SelectionController _selectionController;

  @override
  void initState() {
    super.initState();
    _selectionController = SelectionController(
      maxSelections: 2,
      selectionType: SelectionType.none,
      selectionStyle: SelectionStyle(
        strokeColor: Colors.yellow,
        strokeWidth: 2,
        fillColor: Colors.white.withOpacity(0.5),
        dashPattern: [5, 5],
      ),
      onSelectionUpdate: (count, remaining, selections) {
        setState(() {
          // Update UI based on selections
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.draw_outlined),
            onPressed: () {
              _selectionController.setSelectionType(SelectionType.freeDraw);
            },
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: () {
              _selectionController.clearAllSelections();
            },
          ),
        ],
      ),
      body: PanoramaViewer(
        selectionController: _selectionController,
        child: Image.asset('your_panorama.jpg'),
      ),
    );
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }
}
```

## Important Notes

1. When selection mode is active, panorama interaction (panning, zooming) is disabled
2. Selections persist across panorama movements and zooms
3. The maximum number of selections can be configured
4. Selections can be cleared individually or all at once
5. The selection style can be changed at any time 
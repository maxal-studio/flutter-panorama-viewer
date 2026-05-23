# Hotspots

Hotspots are interactive elements that can be placed on specific locations in your panoramic image. The package supports both widget-based hotspots and polygon hotspots.

## Basic Usage

Add hotspots to your PanoramaViewer using the `hotspots` parameter:

```dart
PanoramaViewer(
  hotspots: [
    Hotspot(
      latitude: -4,
      longitude: 0,
      width: 40,
      height: 40,
      widget: YourWidget(),
    ),
    PolygonHotspot(
      points: [
        LatLng(-10, -10),
        LatLng(-10, 10),
        LatLng(-20, 10),
        LatLng(-20, -10),
      ],
      onTap: () {
        print('Polygon tapped');
      },
    ),
  ],
  child: Image.asset('your_panorama.jpg'),
)
```

## Types of Hotspots

### 1. Widget Hotspots

Widget hotspots allow you to place any Flutter widget at a specific location in the panorama:

```dart
Hotspot(
  latitude: -4,        // Vertical position (-90 to 90)
  longitude: 0,        // Horizontal position (-180 to 180)
  width: 40,          // Width in pixels
  height: 40,         // Height in pixels
  widget: TextButton(
    style: ButtonStyle(
      shape: WidgetStateProperty.all(const CircleBorder()),
      backgroundColor: WidgetStateProperty.all(Colors.black38),
      foregroundColor: WidgetStateProperty.all(Colors.white),
    ),
    onPressed: () {
      print('Hotspot tapped');
    },
    child: const Icon(Icons.add),
  ),
)
```

### 2. Polygon Hotspots

Polygon hotspots allow you to create interactive shapes on the panorama:

```dart
PolygonHotspot(
  points: [
    LatLng(-10, -10), // Bottom left
    LatLng(-10, 10),  // Bottom right
    LatLng(-20, 10),  // Top right
    LatLng(-20, -10), // Top left
    LatLng(-10, -10), // Close the polygon
  ],
  style: HotspotStyle(
    strokeColor: Colors.red.shade900,
    strokeWidth: 2,
    fillColor: Colors.red.withOpacity(0.3),
    dashPattern: [5, 5],
  ),
  onTap: () {
    print('Polygon tapped');
  },
)
```

## Hotspot Styling

### Widget Hotspot Properties

- `latitude`: Vertical position (-90 to 90 degrees)
- `longitude`: Horizontal position (-180 to 180 degrees)
- `width`: Width in pixels
- `height`: Height in pixels
- `widget`: Any Flutter widget

### Polygon Hotspot Properties

- `points`: List of LatLng coordinates defining the polygon shape
- `style`: HotspotStyle for appearance customization
- `onTap`: Callback function when the polygon is tapped

### HotspotStyle Properties

```dart
HotspotStyle(
  strokeColor: Colors.red.shade900,  // Border color
  strokeWidth: 2,                    // Border width
  fillColor: Colors.red.withOpacity(0.3), // Fill color
  dashPattern: [5, 5],              // Border dash pattern
)
```

## Example Implementations

### 1. Interactive Button Hotspot

```dart
Hotspot(
  latitude: 0,
  longitude: 0,
  width: 60,
  height: 60,
  widget: ElevatedButton(
    style: ElevatedButton.styleFrom(
      shape: const CircleBorder(),
      backgroundColor: Colors.blue.withOpacity(0.7),
    ),
    onPressed: () {
      // Handle button press
    },
    child: const Icon(Icons.info, color: Colors.white),
  ),
)
```

### 2. Information Text Hotspot

```dart
Hotspot(
  latitude: 10,
  longitude: 45,
  width: 120,
  height: 40,
  widget: Container(
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Center(
      child: Text(
        'Point of Interest',
        style: TextStyle(color: Colors.white),
      ),
    ),
  ),
)
```

### 3. Interactive Region with Polygon

```dart
PolygonHotspot(
  points: [
    LatLng(0, 0),      // Center
    LatLng(20, 20),    // Top right
    LatLng(20, -20),   // Top left
    LatLng(0, 0),      // Close the triangle
  ],
  style: HotspotStyle(
    strokeColor: Colors.blue,
    strokeWidth: 5,
    fillColor: Colors.green.withOpacity(0.3),
  ),
  onTap: () {
    // Handle polygon tap
  },
)
```

## Best Practices

1. **Positioning**: Use appropriate latitude and longitude values to ensure hotspots are visible in the desired location.

2. **Size**: Keep widget hotspots reasonably sized to avoid overwhelming the panorama view.

3. **Visual Feedback**: Provide clear visual feedback for interactive hotspots.

4. **Performance**: Avoid adding too many hotspots as it may affect performance.

5. **Responsiveness**: Make hotspots responsive to different screen sizes by using relative sizing when possible.

## Important Notes

1. Hotspots maintain their position during panorama movement and zoom
2. Widget hotspots can contain any Flutter widget
3. Polygon hotspots can create complex shapes with custom styling
4. All coordinates use the latitude/longitude system
5. Hotspots can overlap, so consider z-index implications 
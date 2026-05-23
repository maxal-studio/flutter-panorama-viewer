# Panorama Viewer

A 360-degree panorama viewer.

This package is an updated porting of the plugin https://github.com/zesage/panorama.

## Getting Started

Add panorama as a dependency in your pubspec.yaml file.

```yaml
dependencies:
  panorama_viewer: ^2.0.1
```

Import and add the Panorama Viewer widget to your project.

```dart
import 'package:panorama_viewer/panorama_viewer.dart';
... ...
  
@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: PanoramaViewer(
          child: Image.asset('assets/panorama360.jpg'),
        ),
      ),
    );
  }
```

## Documentation

Detailed documentation for specific features:

- [Image Filters and Shaders](docs/image_filters.md) - Learn how to apply and create custom image filters
- [Selection Controller](docs/selection_controller.md) - Implement interactive region selection
- [Hotspots](docs/hotspots.md) - Add interactive elements to your panorama

## Example files:

- Example 1 - Minimum code
- Example 2 - Transparent appbar
- Example 3 - Hotspots and callbacks
- Example 4 - Zoom and position with buttons
- Example 5 - 2 panoramas side by side
- Example 6 - Panorama Selection
- Example 7 - Image Filters

## Features

- 360-degree panorama viewing
- Interactive hotspots and regions
- Custom image filters and shaders
- Region selection tools
- Touch and sensor controls
- Customizable UI elements
- Multiple panorama support
- Zoom and position controls

## Migration from the Panorama package

- In the dependencies, use `panorama_viewer` instead of `panorama`.
- In the Dart files where you use panorama, change the import to: `import 'package:panorama_viewer/panorama_viewer.dart';`.
- Change the widget name from `Panorama` to `PanoramaViewer`.
- If you've used `SensorControl`, change `SensorControl.Orientation` to `SensorControl.orientation`. All constant names are now in lower camel case, following the latest Dart best practices.

## Web implementation

On the web, sensors are not utilized because the sensor library used is only compatible with iOS and Android devices. Additionally, on some Android devices, if the panoramic image is too large, nothing is displayed. When checking the console log remotely, you may encounter WebGL errors or warnings.





import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:panorama_viewer/selection/selection_controller.dart';

class ExampleScreen6 extends StatefulWidget {
  const ExampleScreen6({super.key, required this.title});
  final String title;
  @override
  ExampleScreen6State createState() => ExampleScreen6State();
}

class ExampleScreen6State extends State<ExampleScreen6> {
  late SelectionController _selectionController;

  // Images
  List<String> images = [
    'assets/panorama1.webp',
    'assets/panorama2.webp',
  ];
  int currentImage = 0;

  @override
  void initState() {
    super.initState();

    // Selection controller
    _selectionController = SelectionController(
      maxSelections: 2,
      selectionType: SelectionType.none,
      selectionStyle: SelectionStyle(
        strokeColor: Colors.yellow,
        strokeWidth: 2,
        fillColor: Colors.white.withValues(alpha: 0.5),
        dashPattern: [5, 5],
      ),
      onSelectionUpdate: (count, remaining, List<Selection> selections) {
        getSelectedCoordinatesImage();
      },
    );
  }

  // Get image coordinates (simplified version)
  void getSelectedCoordinatesImage() {
    // Get image coordinates using the automatic method
    List<List<Offset>> imageCoordinates =
        _selectionController.getSelectedCoordinatesImage();

    inspect(imageCoordinates);
  }

  /// Next image
  void nextImage() {
    setState(() {
      if (currentImage < images.length - 1) {
        currentImage++;
      } else {
        // Go to first image
        currentImage = 0;
      }
    });
  }

  /// Previous image
  void previousImage() {
    setState(() {
      if (currentImage > 0) {
        currentImage--;
      } else {
        // Go to last image
        currentImage = images.length - 1;
      }
    });
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selection'),
        actions: [
          IconButton(
            onPressed: () {
              previousImage();
            },
            icon: const Icon(Icons.arrow_back),
          ),
          // Next
          IconButton(
            onPressed: () {
              nextImage();
            },
            icon: const Icon(Icons.arrow_forward),
          ),

          IconButton(
            icon: const Icon(Icons.data_array),
            onPressed: () {
              getSelectedCoordinatesImage();
            },
            tooltip: 'Get Image Coordinates',
          ),
          IconButton(
            icon: const Icon(Icons.touch_app_outlined),
            onPressed: () {
              _selectionController.setSelectionType(SelectionType.none);
            },
            tooltip: 'Disable Free Draw',
          ),
          IconButton(
            icon: const Icon(Icons.draw_outlined),
            onPressed: () {
              _selectionController.setSelectionType(SelectionType.freeDraw);
            },
            tooltip: 'Make Free Draw Selection',
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: () {
              _selectionController.clearAllSelections();
            },
            tooltip: 'Clear All Selections',
          ),
          IconButton(
            icon: const Icon(Icons.undo_outlined),
            onPressed: () {
              _selectionController.undoLastSelection();
            },
            tooltip: 'Undo Last Selection',
          ),
        ],
      ),
      body: Stack(
        children: [
          PanoramaViewer(
            animSpeed: 0.5,
            selectionController: _selectionController,
            latitude: 0,
            longitude: 50,
            onLongPressEnd: (longitude, latitude, tilt) {
              debugPrint('Long press ended at $longitude, $latitude, $tilt');
            },
            onLongPressMoveUpdate: (longitude, latitude, tilt) {
              debugPrint('Long press moved to $longitude, $latitude, $tilt');
            },
            onLongPressStart: (longitude, latitude, tilt) {
              debugPrint('Long press started at $longitude, $latitude, $tilt');
            },
            hotspots: [
              Hotspot(
                latitude: -4,
                longitude: 0,
                width: 40,
                height: 40,
                widget: TextButton(
                  style: ButtonStyle(
                    shape: WidgetStateProperty.all(const CircleBorder()),
                    backgroundColor: WidgetStateProperty.all(Colors.black38),
                    foregroundColor: WidgetStateProperty.all(Colors.white),
                  ),
                  onPressed: () {
                    debugPrint('Hotspot tapped');
                  },
                  child: const Icon(Icons.add),
                ),
              ),

              // New square PolygonHotspot
              PolygonHotspot(
                points: const [
                  LatLng(-10, -10), // Bottom left
                  LatLng(-10, 10), // Bottom right
                  LatLng(-20, 10), // Top right
                  LatLng(-20, -10), // Top left
                  LatLng(-10, -10), // Close the square
                ],
                style: HotspotStyle(
                  strokeColor: Colors.red.shade900,
                  strokeWidth: 2,
                  fillColor: Colors.red.withValues(alpha: 0.3),
                  dashPattern: [5, 5],
                ),
                onTap: () {
                  debugPrint('Square tapped');
                },
              ),

              // Triangle shape with red fill and blue border
              PolygonHotspot(
                points: const [
                  LatLng(0, 0), // Center
                  LatLng(20, 20), // Top right
                  LatLng(20, -20), // Top left
                  LatLng(0, 0),
                ],
                style: HotspotStyle(
                  strokeColor: Colors.blue,
                  strokeWidth: 5,
                  fillColor: Colors.green,
                ),
                onTap: () {
                  debugPrint('Triangle tapped');
                },
              ),
            ],
            child: Image.asset(images[currentImage]),
          ),
        ],
      ),
    );
  }
}

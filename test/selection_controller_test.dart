import 'package:flutter_test/flutter_test.dart';
import 'package:panorama_viewer/selection/selection_controller.dart';
import 'package:panorama_viewer/utils/panorama_utils.dart';
import 'package:panorama_viewer/cube/scene.dart';
import 'package:vector_math/vector_math_64.dart';

// Mock CoordinateConverter for testing
class MockCoordinateConverter extends CoordinateConverter {
  MockCoordinateConverter() : super(Scene(), 500);

  @override
  Vector3 positionToLatLon(double x, double y) {
    return Vector3(0, 0, 0);
  }

  @override
  Vector3 positionFromLatLon(double lat, double lon) {
    return Vector3(0, 0, 0);
  }

  @override
  double degrees(double rad) {
    return rad * 180 / 3.14159;
  }
}

void main() {
  group('SelectionController', () {
    late SelectionController controller;

    setUp(() {
      controller = SelectionController(
        splitWrapAroundPolygon: true,
        debugMode: false,
        selectionType: SelectionType.freeDraw,
      );
      controller.setConverter(MockCoordinateConverter());
    });

    test('Original and processed selections are maintained separately', () {
      // First, verify that we start with no selections
      expect(controller.selections.length, 0);
      expect(controller.getProcessedSelections().length, 0);
      expect(controller.getOriginalSelections().length, 0);

      // Now let's simulate drawing a selection that wraps around
      // We'll do this by setting the current selection and then completing it

      // Set up a selection that wraps around
      controller
          .startDrawing(Offset.zero); // This will create a current selection

      // Manually modify the points of the current selection to create a wrap-around
      // This is a bit hacky but necessary for testing
      final currentSelection = controller.currentSelection;
      if (currentSelection != null) {
        currentSelection.points.clear();
        currentSelection.points.addAll([
          const LatLng(0, 170), // Right side
          const LatLng(10, 175), // Right side
          const LatLng(20, -175), // Left side (wrap around)
          const LatLng(10, -170), // Left side
          const LatLng(0, 170), // Back to right side (wrap around)
        ]);

        // Now complete the drawing
        controller.completeDrawing();

        // Verify that in normal mode, we see 1 selection (original)
        expect(controller.selections.length, 1);

        // But the processed selections should be 2
        expect(controller.getProcessedSelections().length, 2);

        // Enable debug mode to see processed selections
        controller.setDebugMode(true);

        // In debug mode, we should see 2 selections (split parts)
        expect(controller.selections.length, 2);

        // Verify that the original selections are still 1
        expect(controller.getOriginalSelections().length, 1);

        // Test undo functionality
        controller.undoLastSelection();

        // After undo, both should be empty
        expect(controller.getProcessedSelections().length, 0);
        expect(controller.getOriginalSelections().length, 0);
      } else {
        fail('Failed to create current selection');
      }
    });

    test('Debug mode toggles between original and processed selections', () {
      // Set up a selection that wraps around
      controller.startDrawing(Offset.zero);

      // Manually modify the points to create a wrap-around
      final currentSelection = controller.currentSelection;
      if (currentSelection != null) {
        currentSelection.points.clear();
        currentSelection.points.addAll([
          const LatLng(0, 170),
          const LatLng(10, 175),
          const LatLng(20, -175),
          const LatLng(10, -170),
          const LatLng(0, 170),
        ]);

        // Complete the drawing
        controller.completeDrawing();

        // In normal mode, we should see the original selection
        expect(controller.selections.length, 1);

        // Toggle debug mode
        controller.setDebugMode(true);

        // In debug mode, we should see the processed selections
        expect(controller.selections.length, 2);

        // Toggle back to normal mode
        controller.setDebugMode(false);

        // Back to seeing the original selection
        expect(controller.selections.length, 1);
      } else {
        fail('Failed to create current selection');
      }
    });
  });
}

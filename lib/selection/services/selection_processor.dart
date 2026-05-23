import '../models/index.dart';

/// Service for processing selections
class SelectionProcessor {
  /// Detects if a selection wraps around the panorama boundary and splits it if needed.
  ///
  /// This method checks consecutive points in the selection to detect significant
  /// longitude jumps (typically near -180°/+180° boundary) and splits the selection
  /// into two parts at the wrap-around points.
  ///
  /// @param selection The selection to check and potentially split
  /// @return A list containing either the original selection (if no wrap-around)
  ///         or two new selections representing the split parts
  static List<Selection> splitWrapAroundSelection(Selection selection) {
    // Need at least 3 points to form a valid polygon
    if (selection.points.length < 3) {
      return [selection];
    }

    // This threshold detects significant longitude jumps (in degrees)
    // Typically a jump of more than 180 degrees indicates a wrap-around
    const double wrapAroundThreshold = 180.0;

    // Create a copy of points for processing (this handles open and closed polygons consistently)
    // If the polygon is already closed (first point equals last point), we keep it as is
    // If not, we'll close it temporarily for processing
    List<LatLng> processPoints = List<LatLng>.from(selection.points);
    bool wasOpen = false;

    if (processPoints.first.latitude != processPoints.last.latitude ||
        processPoints.first.longitude != processPoints.last.longitude) {
      processPoints
          .add(processPoints.first); // Close the polygon for processing
      wasOpen = true;
    }

    // First pass: identify if there's any wrap-around
    bool hasWrapAround = false;
    for (int i = 1; i < processPoints.length; i++) {
      final LatLng prev = processPoints[i - 1];
      final LatLng current = processPoints[i];

      double lonDiff = (current.longitude - prev.longitude).abs();
      if (lonDiff > wrapAroundThreshold) {
        hasWrapAround = true;
        break;
      }
    }

    if (!hasWrapAround) {
      return [selection]; // No wrap-around detected, return original
    }

    // We have a wrap-around. Let's split the polygon.
    // For longitude wrap-around near -180/180
    final double leftBoundary = -180.0;
    final double rightBoundary = 180.0;

    // Create two parts of the polygon
    List<LatLng> leftPart = []; // Points in western hemisphere (-180 to 0)
    List<LatLng> rightPart = []; // Points in eastern hemisphere (0 to 180)

    // Process each edge of the polygon, including the closing edge (if temporary)
    for (int i = 0; i < processPoints.length - 1; i++) {
      final LatLng p1 = processPoints[i];
      final LatLng p2 = processPoints[i + 1];

      // Determine which side each point lies on
      final bool p1OnLeft = p1.longitude < 0;
      final bool p2OnLeft = p2.longitude < 0;

      // Add the first point to its respective part
      if (p1OnLeft) {
        leftPart.add(p1);
      } else {
        rightPart.add(p1);
      }

      // Check if this edge crosses the boundary
      if (p1OnLeft != p2OnLeft ||
          (p1.longitude - p2.longitude).abs() > wrapAroundThreshold) {
        // Calculate intersection points with the boundary

        // Calculate interpolation parameter
        double t;

        if ((p1.longitude < 0 && p2.longitude > 0) ||
            (p1.longitude > 0 && p2.longitude < 0)) {
          // Regular crossing through longitude 0 (less common in 360 panoramas)
          // Use linear interpolation formula based on longitudes
          t = -p1.longitude / (p2.longitude - p1.longitude);
        } else {
          // Crossing through the -180/180 boundary (more common in panoramas)
          double normLon1 = p1.longitude;
          double normLon2 = p2.longitude;

          // Normalize longitudes for calculation
          if (normLon1 > 0 && normLon2 < 0) {
            // Crossing from east to west (right to left)
            normLon2 += 360; // Adjust to be in the range [180, 540]
          } else if (normLon1 < 0 && normLon2 > 0) {
            // Crossing from west to east (left to right)
            normLon1 += 360; // Adjust to be in the range [180, 540]
          }

          // Calculate t for the -180/180 boundary
          if (p1OnLeft) {
            t = (leftBoundary - p1.longitude) / (normLon2 - p1.longitude);
          } else {
            t = (rightBoundary - p1.longitude) / (normLon2 - p1.longitude);
          }
        }

        // Clamp t between 0 and 1 to ensure it's on the segment
        t = t.clamp(0.0, 1.0);

        // Calculate the intersection latitude using linear interpolation
        double lat = p1.latitude + t * (p2.latitude - p1.latitude);

        // Create intersection points at both boundaries
        LatLng intersectionLeft = LatLng(lat, leftBoundary);
        LatLng intersectionRight = LatLng(lat, rightBoundary);

        // Add these intersection points to their respective parts
        leftPart.add(intersectionLeft);
        rightPart.add(intersectionRight);
      }
    }

    // The special case: if the polygon was open and starts/ends on different sides
    if (wasOpen) {
      // Remove the temporary closing point we added
      processPoints.removeLast();

      // Check if the polygon starts and ends on different sides
      final bool firstPointOnLeft = processPoints.first.longitude < 0;
      final bool lastPointOnLeft = processPoints.last.longitude < 0;

      if (firstPointOnLeft != lastPointOnLeft) {
        // Need to handle the implicit closing edge specially
        final LatLng p1 = processPoints.last;
        final LatLng p2 = processPoints.first;

        // Calculate intersection for this closing edge (similar to above)
        double t;
        if ((p1.longitude < 0 && p2.longitude > 0) ||
            (p1.longitude > 0 && p2.longitude < 0)) {
          t = -p1.longitude / (p2.longitude - p1.longitude);
        } else {
          double normLon1 = p1.longitude;
          double normLon2 = p2.longitude;

          if (normLon1 > 0 && normLon2 < 0) {
            normLon2 += 360;
          } else if (normLon1 < 0 && normLon2 > 0) {
            normLon1 += 360;
          }

          if (p1.longitude < 0) {
            t = (leftBoundary - p1.longitude) / (normLon2 - p1.longitude);
          } else {
            t = (rightBoundary - p1.longitude) / (normLon2 - p1.longitude);
          }
        }

        t = t.clamp(0.0, 1.0);
        double lat = p1.latitude + t * (p2.latitude - p1.latitude);

        // Add these special boundary points for the closing edge
        LatLng intersectionLeft = LatLng(lat, leftBoundary);
        LatLng intersectionRight = LatLng(lat, rightBoundary);

        leftPart.add(intersectionLeft);
        rightPart.add(intersectionRight);
      }
    }

    // Create final selections from the parts
    List<Selection> result = [];

    // Close each part if the original was closed or has closeShape style
    // Skip if already closed (first equals last)
    if (selection.style.closeShape) {
      // Ensure left part is closed if it has enough points
      if (leftPart.length >= 3) {
        if (leftPart.first.latitude != leftPart.last.latitude ||
            leftPart.first.longitude != leftPart.last.longitude) {
          leftPart.add(leftPart.first);
        }
      }

      // Ensure right part is closed if it has enough points
      if (rightPart.length >= 3) {
        if (rightPart.first.latitude != rightPart.last.latitude ||
            rightPart.first.longitude != rightPart.last.longitude) {
          rightPart.add(rightPart.first);
        }
      }
    }

    // Create selection objects for valid parts (need at least 3 points to form a polygon)
    if (leftPart.length >= 3) {
      result.add(Selection(
        type: selection.type,
        points: leftPart,
        style: selection.style,
      ));
    }

    if (rightPart.length >= 3) {
      result.add(Selection(
        type: selection.type,
        points: rightPart,
        style: selection.style,
      ));
    }

    return result.isNotEmpty
        ? result
        : [selection]; // Fall back to original if no valid parts
  }
}

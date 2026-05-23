import 'package:flutter/material.dart';
import 'package:panorama_viewer/cube/scene.dart';
import 'package:vector_math/vector_math_64.dart';
import '../utils/panorama_utils.dart';
import 'hotspot_types.dart';
import 'package:panorama_viewer/selection/models/index.dart';

class PolygonHotspotPainter extends CustomPainter {
  final List<LatLng> points;
  final HotspotStyle style;
  final Scene scene;
  Path? _cachedPath;

  PolygonHotspotPainter({
    required this.points,
    required this.style,
    required this.scene,
  });

  Path _buildPath() {
    if (_cachedPath != null) return _cachedPath!;

    final converter = CoordinateConverter(scene, 500);
    final path = Path();
    bool isFirst = true;
    bool isVisible = false;

    for (final point in points) {
      // Use the same simple approach as Hotspot
      final Vector3 pos = converter.positionFromLatLon(
        point.latitude,
        point.longitude,
      );

      // Skip if point is behind the sphere
      if (pos.z < 0) continue;

      isVisible = true;

      if (isFirst) {
        path.moveTo(pos.x, pos.y);
        isFirst = false;
      } else {
        path.lineTo(pos.x, pos.y);
      }
    }

    // Only close the path if we have visible points and fill color
    if (!isFirst && style.fillColor != null) {
      path.close();
    }

    // Return empty path if nothing is visible
    if (!isVisible) {
      _cachedPath = Path();
      return _cachedPath!;
    }

    _cachedPath = path;
    return path;
  }

  bool isInside(Offset point) {
    final path = _buildPath();
    return path.contains(point);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final path = _buildPath();
    if (path.getBounds().isEmpty) return;

    // Draw fill first
    if (style.fillColor != null) {
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = style.fillColor!;
      canvas.drawPath(path, fillPaint);
    }

    // Then draw stroke
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.strokeWidth
      ..color = style.strokeColor;

    if (style.dashPattern != null) {
      canvas.drawPath(
        _dashPath(path, style.dashPattern!),
        strokePaint,
      );
    } else {
      canvas.drawPath(path, strokePaint);
    }
  }

  Path _dashPath(Path path, List<double> dashPattern) {
    final Path dashedPath = Path();
    final double dashLength = dashPattern[0];
    final double gapLength = dashPattern[1];

    // Get all path metrics
    final metrics = path.computeMetrics(forceClosed: false).toList();

    for (final metric in metrics) {
      double start = 0;
      bool draw = true;

      while (start < metric.length) {
        final double segmentLength = draw ? dashLength : gapLength;
        final double end = (start + segmentLength).clamp(0, metric.length);

        if (draw) {
          final segment = metric.extractPath(start, end);
          dashedPath.addPath(segment, Offset.zero);
        }

        start = end;
        draw = !draw;
      }
    }

    return dashedPath;
  }

  @override
  bool shouldRepaint(PolygonHotspotPainter oldDelegate) {
    return points != oldDelegate.points || style != oldDelegate.style;
  }
}

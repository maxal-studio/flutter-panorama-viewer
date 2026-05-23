import 'package:flutter/material.dart';
import 'package:panorama_viewer/cube/scene.dart';
import 'package:vector_math/vector_math_64.dart';
import '../utils/panorama_utils.dart';
import 'package:panorama_viewer/selection/models/index.dart';

class SelectionPainter extends CustomPainter {
  final Selection? currentSelection;
  final List<Selection> completedSelections;
  final Scene scene;

  SelectionPainter({
    required this.currentSelection,
    required this.completedSelections,
    required this.scene,
  });

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

  void _drawSelection(Canvas canvas, Selection selection) {
    if (selection.points.isEmpty) return;

    final converter = CoordinateConverter(scene, 500);
    final path = Path();
    bool isFirst = true;
    bool isVisible = false;

    for (final point in selection.points) {
      final Vector3 pos = converter.positionFromLatLon(
        point.latitude,
        point.longitude,
      );

      // Skip points behind the sphere
      if (pos.z < 0) continue;

      isVisible = true;

      if (isFirst) {
        path.moveTo(pos.x, pos.y);
        isFirst = false;
      } else {
        path.lineTo(pos.x, pos.y);
      }
    }

    // Don't draw anything if no points are visible
    if (!isVisible) return;

    // Close the path only if we have visible points and fill color
    if (!isFirst && selection.style.fillColor != null) {
      path.close();
    }

    // Draw fill first if we have visible points
    if (selection.style.fillColor != null) {
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = selection.style.fillColor!;

      canvas.drawPath(path, fillPaint);
    }

    // Then draw stroke
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selection.style.strokeWidth
      ..color = selection.style.strokeColor;

    if (selection.style.dashPattern != null) {
      canvas.drawPath(
        _dashPath(path, selection.style.dashPattern!),
        strokePaint,
      );
    } else {
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed selections
    for (final selection in completedSelections) {
      _drawSelection(canvas, selection);
    }

    // Draw current selection
    if (currentSelection != null) {
      _drawSelection(canvas, currentSelection!);
    }
  }

  @override
  bool shouldRepaint(SelectionPainter oldDelegate) {
    return currentSelection != oldDelegate.currentSelection ||
        completedSelections != oldDelegate.completedSelections;
  }
}

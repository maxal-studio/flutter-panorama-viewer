import 'package:flutter/material.dart';
import 'package:panorama_viewer/cube/scene.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../utils/panorama_utils.dart';
import 'package:panorama_viewer/selection/models/index.dart';

class HotspotStyle {
  final Color strokeColor;
  final double strokeWidth;
  final Color? fillColor;
  final List<double>? dashPattern;

  const HotspotStyle({
    this.strokeColor = Colors.blue,
    this.strokeWidth = 2.0,
    this.fillColor,
    this.dashPattern,
  });

  HotspotStyle copyWith({
    Color? strokeColor,
    double? strokeWidth,
    Color? fillColor,
    List<double>? dashPattern,
  }) {
    return HotspotStyle(
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      fillColor: fillColor ?? this.fillColor,
      dashPattern: dashPattern ?? this.dashPattern,
    );
  }
}

abstract class BaseHotspot {
  final String? name;
  final Widget? widget;

  const BaseHotspot({
    this.name,
    this.widget,
  });

  Widget build(BuildContext context, Scene scene);
}

class Hotspot extends BaseHotspot {
  final double latitude;
  final double longitude;
  final Offset origin;
  final double width;
  final double height;

  const Hotspot({
    super.name,
    super.widget,
    required this.latitude,
    required this.longitude,
    this.origin = const Offset(0.5, 0.5),
    this.width = 32.0,
    this.height = 32.0,
  });

  @override
  Widget build(BuildContext context, Scene scene) {
    return widget ?? const SizedBox();
  }
}

class PolygonHotspot extends BaseHotspot {
  final List<LatLng> points;
  final HotspotStyle style;
  final VoidCallback? onTap;

  const PolygonHotspot({
    super.name,
    super.widget,
    required this.points,
    this.style = const HotspotStyle(),
    this.onTap,
  });

  @override
  Widget build(BuildContext context, Scene scene) => const SizedBox();
}

class PolygonHitTestPainter extends CustomPainter {
  final List<LatLng> points;
  final Scene scene;
  final VoidCallback onTap;

  PolygonHitTestPainter({
    required this.points,
    required this.scene,
    required this.onTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // No need to paint anything, this painter is only for hit testing
  }

  @override
  bool? hitTest(Offset position) {
    final path = _buildHitTestPath();
    if (path.contains(position)) {
      onTap();
      return true;
    }
    return false;
  }

  Path _buildHitTestPath() {
    final converter = CoordinateConverter(scene, 500);
    final path = Path();
    bool isFirst = true;

    for (final point in points) {
      final Vector3 pos = converter.positionFromLatLon(
        point.latitude,
        point.longitude,
      );

      if (pos.z < 0) continue;

      if (isFirst) {
        path.moveTo(pos.x, pos.y);
        isFirst = false;
      } else {
        path.lineTo(pos.x, pos.y);
      }
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

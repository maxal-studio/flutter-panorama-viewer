import 'package:flutter/material.dart';
import 'package:panorama_viewer/cube/scene.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'hotspot_types.dart';
import '../utils/panorama_utils.dart';

class HotspotLayer extends StatelessWidget {
  final List<BaseHotspot> hotspots;
  final Scene scene;
  final Stream<dynamic>? updateStream;

  const HotspotLayer({
    super.key,
    required this.hotspots,
    required this.scene,
    this.updateStream,
  });

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to detect size changes directly
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Update scene camera viewport if needed
        if (scene.camera.viewportWidth != constraints.maxWidth ||
            scene.camera.viewportHeight != constraints.maxHeight) {
          scene.camera.viewportWidth = constraints.maxWidth;
          scene.camera.viewportHeight = constraints.maxHeight;
        }

        // Create converter with the current viewport size
        final converter = CoordinateConverter(
          scene,
          scene.camera.viewportHeight /
              2, // Use half of viewport height as radius
        );

        final allHotspots = <Widget>[];

        // Handle polygon hotspots first (underneath)
        final polygonHotspots = hotspots.whereType<PolygonHotspot>().toList();
        if (polygonHotspots.isNotEmpty) {
          // Add the visual layer for polygons - wrap in StreamBuilder to update on rotation/movement
          allHotspots.add(
            StreamBuilder(
                stream: updateStream,
                builder: (context, _) {
                  return CustomPaint(
                    painter: UnifiedHotspotPainter(
                      hotspots: polygonHotspots,
                      scene: scene,
                    ),
                    size: Size.infinite,
                  );
                }),
          );

          // Add the hit test layer for polygons - also wrap in StreamBuilder
          allHotspots.add(
            StreamBuilder(
                stream: updateStream,
                builder: (context, _) {
                  return Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (event) {
                      final position = event.localPosition;
                      for (final hotspot in polygonHotspots.reversed) {
                        if (hotspot.onTap != null &&
                            _isInsidePolygon(position, hotspot)) {
                          hotspot.onTap!();
                          break;
                        }
                      }
                    },
                    child: const SizedBox.expand(),
                  );
                }),
          );
        }

        // Handle widget hotspots on top - use StreamBuilder to update positions
        final widgetHotspots = hotspots.whereType<Hotspot>().toList();
        if (widgetHotspots.isNotEmpty) {
          // Use the stream passed from PanoramaViewer
          allHotspots.add(
            StreamBuilder(
              stream: updateStream,
              builder: (context, _) {
                final List<Widget> positionedHotspots = [];

                for (final hotspot in widgetHotspots) {
                  final Vector3 pos = converter.positionFromLatLon(
                    hotspot.latitude,
                    hotspot.longitude,
                  );

                  // Skip if behind the camera
                  if (pos.z < 0) continue;

                  final Matrix4 transform = scene.camera.lookAtMatrix *
                      converter.matrixFromLatLon(
                          hotspot.latitude, hotspot.longitude);

                  final Offset originOffset = Offset(
                    hotspot.width * hotspot.origin.dx,
                    hotspot.height * hotspot.origin.dy,
                  );

                  positionedHotspots.add(
                    Positioned(
                      left: pos.x - originOffset.dx,
                      top: pos.y - originOffset.dy,
                      width: hotspot.width,
                      height: hotspot.height,
                      child: Transform(
                        origin: originOffset,
                        transform: transform..invert(),
                        child: Material(
                          type: MaterialType.transparency,
                          child: hotspot.widget ?? const SizedBox(),
                        ),
                      ),
                    ),
                  );
                }

                return Stack(
                  fit: StackFit.expand,
                  children: positionedHotspots,
                );
              },
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: allHotspots,
        );
      },
    );
  }

  bool _isInsidePolygon(Offset position, PolygonHotspot hotspot) {
    // Use updated converter with current viewport size
    final converter = CoordinateConverter(
      scene,
      scene.camera.viewportHeight / 2, // Use half of viewport height as radius
    );

    final path = Path();
    bool isFirst = true;

    for (final point in hotspot.points) {
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
    return path.contains(position);
  }
}

class UnifiedHotspotPainter extends CustomPainter {
  final List<PolygonHotspot> hotspots;
  final Scene scene;

  UnifiedHotspotPainter({
    required this.hotspots,
    required this.scene,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final hotspot in hotspots) {
      _paintPolygon(canvas, hotspot);
    }
  }

  void _paintPolygon(Canvas canvas, PolygonHotspot hotspot) {
    // Use updated converter with current viewport size
    final converter = CoordinateConverter(
      scene,
      scene.camera.viewportHeight / 2, // Use half of viewport height as radius
    );

    final path = Path();
    bool isFirst = true;
    bool isVisible = false;

    for (final point in hotspot.points) {
      final Vector3 pos = converter.positionFromLatLon(
        point.latitude,
        point.longitude,
      );

      if (pos.z < 0) continue;
      isVisible = true;

      if (isFirst) {
        path.moveTo(pos.x, pos.y);
        isFirst = false;
      } else {
        path.lineTo(pos.x, pos.y);
      }
    }

    if (!isVisible) return;
    if (!isFirst && hotspot.style.fillColor != null) {
      path.close();
    }

    if (hotspot.style.fillColor != null) {
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = hotspot.style.fillColor!;
      canvas.drawPath(path, fillPaint);
    }

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = hotspot.style.strokeWidth
      ..color = hotspot.style.strokeColor;

    if (hotspot.style.dashPattern != null) {
      canvas.drawPath(
        _dashPath(path, hotspot.style.dashPattern!),
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
  bool shouldRepaint(UnifiedHotspotPainter oldDelegate) {
    return hotspots != oldDelegate.hotspots;
  }
}

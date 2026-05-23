import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dchs_motion_sensors/dchs_motion_sensors.dart';
import 'package:panorama_viewer/cube/cube.dart';
import 'package:panorama_viewer/cube/mesh.dart';
import 'package:panorama_viewer/cube/scene.dart';
import 'package:panorama_viewer/cube/scene_object.dart';
import 'package:panorama_viewer/hotspots/hotspot_types.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'selection/selection_controller.dart';
import 'selection/selection_painter.dart';
import 'utils/panorama_utils.dart';
import 'hotspots/hotspot_layer.dart';
import 'shaders/shader_controller.dart';
export 'hotspots/hotspot_types.dart';
export 'selection/models/index.dart';

enum SensorControl {
  /// No sensor used.
  none,

  /// Use gyroscope and accelerometer.
  orientation,

  /// Use magnetometer and accelerometer. The logitude 0 points to north.
  absoluteOrientation,
}

class PanoramaViewer extends StatefulWidget {
  const PanoramaViewer({
    super.key,
    this.latitude = 0,
    this.longitude = 0,
    this.zoom = 1.0,
    this.minLatitude = -90.0,
    this.maxLatitude = 90.0,
    this.minLongitude = -180.0,
    this.maxLongitude = 180.0,
    this.minZoom = 1.0,
    this.maxZoom = 5.0,
    this.sensitivity = 1.0,
    this.latSegments = 32,
    this.lonSegments = 64,
    this.sensorControl = SensorControl.none,
    this.croppedArea = const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0),
    this.croppedFullWidth = 1.0,
    this.croppedFullHeight = 1.0,
    this.onViewChanged,
    this.onTap,
    this.onLongPressStart,
    this.onLongPressMoveUpdate,
    this.onLongPressEnd,
    this.onImageLoad,
    this.child,
    this.hotspots,
    this.shaderController,
    this.animSpeed = 0.0,
    this.animReverse = true,
    this.interactive = true,
    this.selectionController,
    this.backgroundColor = Colors.black,
  });

  /// The initial latitude, in degrees, between -90 and 90. default to 0 (the vertical center of the image).
  final double latitude;

  /// The initial longitude, in degrees, between -180 and 180. default to 0 (the horizontal center of the image).
  final double longitude;

  /// The initial zoom, default to 1.0.
  final double zoom;

  /// The minimal latitude to show. default to -90.0
  final double minLatitude;

  /// The maximal latitude to show. default to 90.0
  final double maxLatitude;

  /// The minimal longitude to show. default to -180.0
  final double minLongitude;

  /// The maximal longitude to show. default to 180.0
  final double maxLongitude;

  /// The minimal zomm. default to 1.0
  final double minZoom;

  /// The maximal zomm. default to 5.0
  final double maxZoom;

  /// The sensitivity of the gesture. default to 1.0
  final double sensitivity;

  /// The number of vertical divisions of the sphere.
  final int latSegments;

  /// The number of horizontal divisions of the sphere.
  final int lonSegments;

  /// Control the panorama with motion sensors.
  final SensorControl sensorControl;

  /// Area of the image was cropped from the full sized photo sphere.
  final Rect croppedArea;

  /// Original full width from which the image was cropped.
  final double croppedFullWidth;

  /// Original full height from which the image was cropped.
  final double croppedFullHeight;

  /// This event will be called when the view direction has changed, it contains latitude and longitude about the current view.
  final Function(double longitude, double latitude, double tilt)? onViewChanged;

  /// This event will be called when the user has tapped, it contains latitude and longitude about where the user tapped.
  final Function(double longitude, double latitude, double tilt)? onTap;

  /// This event will be called when the user has started a long press, it contains latitude and longitude about where the user pressed.
  final Function(double longitude, double latitude, double tilt)?
      onLongPressStart;

  /// This event will be called when the user has drag-moved after a long press, it contains latitude and longitude about where the user pressed.
  final Function(double longitude, double latitude, double tilt)?
      onLongPressMoveUpdate;

  /// This event will be called when the user has stopped a long presses, it contains latitude and longitude about where the user pressed.
  final Function(double longitude, double latitude, double tilt)?
      onLongPressEnd;

  /// This event will be called when provided image is loaded on texture.
  final Function()? onImageLoad;

  /// Specify an Image(equirectangular image) widget to the panorama.
  final Image? child;

  /// Place widgets in the panorama.
  final List<BaseHotspot>? hotspots;

  /// Controller for managing shaders
  final ShaderController? shaderController;

  /// Animation speed of the panorama
  final double animSpeed;

  /// Reverse animation direction
  final bool animReverse;

  /// Interactive mode of the panorama
  final bool interactive;

  /// Controller for managing selections on the panorama
  final SelectionController? selectionController;

  /// The background color to show while the image is loading. Defaults to Colors.black.
  final Color backgroundColor;

  @override
  PanoramaState createState() => PanoramaState();
}

class PanoramaState extends State<PanoramaViewer>
    with SingleTickerProviderStateMixin {
  Scene? scene;
  SceneObject? surface;
  late double latitudeRad;
  late double longitudeRad;
  double latitudeDelta = 0;
  double longitudeDelta = 0;
  double zoomDelta = 0;
  late Offset _lastFocalPoint;
  double? _lastZoom;
  final double _radius = 500;
  final double _dampingFactor = 0.05;
  double _animateDirection = 1.0;
  double _animSpeed = 0.0;
  late AnimationController _controller;
  double screenOrientationRad = 0.0;
  late Vector3 orientation;
  StreamSubscription? _orientationSubscription;
  StreamSubscription? _screenOrientSubscription;
  late StreamController<Null> _streamController;
  Stream<Null>? _stream;
  ImageStream? _imageStream;
  ui.Image? _processedImage;
  Timer? _textureUpdateTimer;
  ImageInfo? _lastImageInfo;

  // Store original animation speed to restore it later
  double _originalAnimSpeed = 0.0;

  // Add new getters to separate gesture handling logic
  bool get _isPanoramaMovementAllowed {
    if (widget.selectionController == null) {
      return widget.interactive;
    }
    return widget.selectionController?.currentType == SelectionType.none &&
        widget.interactive;
  }

  bool get _isDrawingAllowed {
    if (widget.selectionController == null) {
      return false;
    }
    return widget.selectionController?.currentType == SelectionType.freeDraw;
  }

  void _handleTapUp(TapUpDetails details) {
    final Vector3 o =
        positionToLatLon(details.localPosition.dx, details.localPosition.dy);
    widget.onTap!(degrees(o.x), degrees(-o.y), degrees(o.z));
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    final Vector3 o =
        positionToLatLon(details.localPosition.dx, details.localPosition.dy);
    widget.onLongPressStart!(degrees(o.x), degrees(-o.y), degrees(o.z));
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    final Vector3 o =
        positionToLatLon(details.localPosition.dx, details.localPosition.dy);
    widget.onLongPressMoveUpdate!(degrees(o.x), degrees(-o.y), degrees(o.z));
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    final Vector3 o =
        positionToLatLon(details.localPosition.dx, details.localPosition.dy);
    widget.onLongPressEnd!(degrees(o.x), degrees(-o.y), degrees(o.z));
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (_isDrawingAllowed) {
      widget.selectionController?.startDrawing(details.localFocalPoint);
      return;
    }

    if (_isPanoramaMovementAllowed) {
      _lastFocalPoint = details.localFocalPoint;
      _lastZoom = null;
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_isDrawingAllowed) {
      widget.selectionController?.addPoint(details.localFocalPoint);
      return;
    }

    if (_isPanoramaMovementAllowed) {
      final offset = details.localFocalPoint - _lastFocalPoint;
      _lastFocalPoint = details.localFocalPoint;
      latitudeDelta += widget.sensitivity *
          0.5 *
          math.pi *
          offset.dy /
          scene!.camera.viewportHeight;
      longitudeDelta -= widget.sensitivity *
          _animateDirection *
          0.5 *
          math.pi *
          offset.dx /
          scene!.camera.viewportHeight;
      _lastZoom ??= scene!.camera.zoom;
      zoomDelta +=
          _lastZoom! * details.scale - (scene!.camera.zoom + zoomDelta);
      if (widget.sensorControl == SensorControl.none &&
          !_controller.isAnimating) {
        _controller.reset();
        if (_animSpeed != 0) {
          _controller.repeat();
        } else {
          _controller.forward();
        }
      }
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_isDrawingAllowed) {
      widget.selectionController?.completeDrawing();
      return;
    }
  }

  /// Updates the panorama view based on current state.
  ///
  /// This method handles all view updates including:
  /// - Initial positioning
  /// - Programmatic view changes (setView, setZoom)
  /// - Animation updates
  /// - User interaction updates
  ///
  /// @param forceUpdate When true, updates will occur even in selection mode.
  /// Set to true for programmatic/initial updates, false for user-initiated updates.
  void _updateView({bool forceUpdate = false}) {
    if (scene == null) return;

    // Only check selection state if controller exists and update is not forced
    if (!forceUpdate &&
        widget.selectionController != null &&
        widget.selectionController!.currentType != SelectionType.none) {
      return; // Skip updates only when controller exists and in selection mode
    }

    // auto rotate
    longitudeDelta += 0.001 * _animSpeed;
    if (_animSpeed != 0) {
      if (widget.animReverse) {
        if (longitudeRad + longitudeDelta > widget.maxLongitude * pi / 180.0) {
          _animateDirection = -1.0;
        } else if (longitudeRad + longitudeDelta <
            widget.minLongitude * pi / 180.0) {
          _animateDirection = 1.0;
        }
      }
      longitudeDelta += 0.001 * _animSpeed * _animateDirection;
    }
    // animate vertical rotating
    latitudeRad += latitudeDelta * _dampingFactor * widget.sensitivity;
    latitudeDelta *= 1 - _dampingFactor * widget.sensitivity;
    // animate horizontal rotating
    longitudeRad += _animateDirection *
        longitudeDelta *
        _dampingFactor *
        widget.sensitivity;
    longitudeDelta *= 1 - _dampingFactor * widget.sensitivity;
    // animate zomming
    final double zoom = scene!.camera.zoom + zoomDelta * _dampingFactor;
    zoomDelta *= 1 - _dampingFactor;
    scene!.camera.zoom = zoom.clamp(widget.minZoom, widget.maxZoom);
    // stop animation if not needed
    if (latitudeDelta.abs() < 0.001 &&
        longitudeDelta.abs() < 0.001 &&
        zoomDelta.abs() < 0.001) {
      if (widget.sensorControl == SensorControl.none &&
          _animSpeed == 0 &&
          _controller.isAnimating) {
        _controller.stop();
      }
    }

    // rotate for screen orientation
    Quaternion q = Quaternion.axisAngle(Vector3(0, 0, 1), screenOrientationRad);
    // rotate for device orientation
    q *= Quaternion.euler(-orientation.z, -orientation.y, -orientation.x);
    // rotate to latitude zero
    q *= Quaternion.axisAngle(Vector3(1, 0, 0), math.pi * 0.5);

    // check and limit the rotation range
    Vector3 o = quaternionToOrientation(q);
    final double minLat = radians(math.max(-89.9, widget.minLatitude));
    final double maxLat = radians(math.min(89.9, widget.maxLatitude));
    final double minLon = radians(widget.minLongitude);
    final double maxLon = radians(widget.maxLongitude);
    final double lat = (-o.y).clamp(minLat, maxLat);
    final double lon = o.x.clamp(minLon, maxLon);
    if (lat + latitudeRad < minLat) latitudeRad = minLat - lat;
    if (lat + latitudeRad > maxLat) latitudeRad = maxLat - lat;
    if (maxLon - minLon < math.pi * 2) {
      if (lon + longitudeRad < minLon || lon + longitudeRad > maxLon) {
        longitudeRad = (lon + longitudeRad < minLon ? minLon : maxLon) - lon;
        // reverse rotation when reaching the boundary
        if (_animSpeed != 0) {
          if (widget.animReverse) {
            _animateDirection *= -1.0;
          } else {
            _controller.stop();
          }
        }
      }
    }
    o.x = lon;
    o.y = -lat;
    q = orientationToQuaternion(o);

    // rotate to longitude zero
    q *= Quaternion.axisAngle(Vector3(0, 1, 0), -math.pi * 0.5);
    // rotate around the global Y axis
    q *= Quaternion.axisAngle(Vector3(0, 1, 0), longitudeRad);
    // rotate around the local X axis
    q = Quaternion.axisAngle(Vector3(1, 0, 0), -latitudeRad) * q;

    o = quaternionToOrientation(
        q * Quaternion.axisAngle(Vector3(0, 1, 0), math.pi * 0.5));
    widget.onViewChanged?.call(degrees(o.x), degrees(-o.y), degrees(o.z));

    q.rotate(scene!.camera.target..setFrom(Vector3(0, 0, -_radius)));
    q.rotate(scene!.camera.up..setFrom(Vector3(0, 1, 0)));
    scene!.update();
    _streamController.add(null);
  }

  void _updateSensorControl() {
    if (kIsWeb) return;

    _orientationSubscription?.cancel();

    switch (widget.sensorControl) {
      case SensorControl.orientation:
        motionSensors.orientationUpdateInterval =
            Duration.microsecondsPerSecond ~/ 60;
        _orientationSubscription =
            motionSensors.orientation.listen((OrientationEvent event) {
          orientation.setValues(event.yaw, event.pitch, event.roll);
        });
        break;
      case SensorControl.absoluteOrientation:
        motionSensors.absoluteOrientationUpdateInterval =
            Duration.microsecondsPerSecond ~/ 60;
        _orientationSubscription = motionSensors.absoluteOrientation
            .listen((AbsoluteOrientationEvent event) {
          orientation.setValues(event.yaw, event.pitch, event.roll);
        });
        break;
      default:
    }

    _screenOrientSubscription?.cancel();
    if (widget.sensorControl != SensorControl.none) {
      _screenOrientSubscription = motionSensors.screenOrientation
          .listen((ScreenOrientationEvent event) {
        screenOrientationRad = radians(event.angle!);
      });
    }
  }

  void _updateTexture(ImageInfo imageInfo, bool synchronousCall) async {
    setState(() {
      _processedImage = imageInfo.image;
    });

    if (widget.shaderController == null) {
      setState(() {
        surface?.mesh.texture = _processedImage;
        surface?.mesh.textureRect = Rect.fromLTWH(
          0,
          0,
          _processedImage!.width.toDouble(),
          _processedImage!.height.toDouble(),
        );
        scene?.texture = _processedImage;
        scene?.updateTexture();
      });
      return;
    }

    // Update shader controller in scene
    scene?.shaderController = widget.shaderController;
    setState(() {
      surface?.mesh.texture = _processedImage;
      surface?.mesh.textureRect = Rect.fromLTWH(
        0,
        0,
        _processedImage!.width.toDouble(),
        _processedImage!.height.toDouble(),
      );
      scene?.texture = _processedImage;
      scene?.updateTexture();
    });

    _lastImageInfo = imageInfo;
    widget.onImageLoad?.call();
  }

  void _loadImage() {
    if (widget.child?.image == null) return;

    _imageStream?.removeListener(ImageStreamListener(_updateTexture));
    _imageStream = widget.child!.image.resolve(const ImageConfiguration());
    _imageStream!.addListener(ImageStreamListener(_updateTexture));
  }

  void _onSceneCreated(Scene scene) {
    this.scene = scene;
    scene.camera.near = 1.0;
    scene.camera.far = _radius + 1.0;
    scene.camera.fov = 75;
    scene.camera.zoom = widget.zoom;
    scene.camera.position.setFrom(Vector3(0, 0, 0.1));

    // Set the converter after scene is initialized
    if (widget.selectionController != null) {
      widget.selectionController!.setConverter(
        CoordinateConverter(
          scene,
          _radius,
          croppedArea: widget.croppedArea,
          croppedFullWidth: widget.croppedFullWidth,
          croppedFullHeight: widget.croppedFullHeight,
        ),
      );
    }

    if (widget.child != null) {
      final Mesh mesh = generateSphereMesh(
          radius: _radius,
          latSegments: widget.latSegments,
          lonSegments: widget.lonSegments,
          croppedArea: widget.croppedArea,
          croppedFullWidth: widget.croppedFullWidth,
          croppedFullHeight: widget.croppedFullHeight);
      surface = SceneObject(
        name: 'surface',
        mesh: mesh,
        backfaceCulling: false,
      );
      _loadImage();
      scene.world.add(surface!);
      // Force initial positioning regardless of selection mode
      // This ensures the panorama is correctly positioned on initialization
      _updateView(forceUpdate: true);
    }
  }

  Matrix4 matrixFromLatLon(double lat, double lon) {
    return Matrix4.rotationY(radians(90.0 - lon))..rotateX(radians(lat));
  }

  Vector3 positionToLatLon(double x, double y) {
    // transform viewport coordinate to NDC, values between -1 and 1
    final Vector4 v = Vector4(2.0 * x / scene!.camera.viewportWidth - 1.0,
        1.0 - 2.0 * y / scene!.camera.viewportHeight, 1.0, 1.0);
    // create projection matrix
    final Matrix4 m =
        scene!.camera.projectionMatrix * scene!.camera.lookAtMatrix;
    // apply inversed projection matrix
    m.invert();
    v.applyMatrix4(m);
    // apply perspective division
    v.scale(1 / v.w);
    // get rotation from two vectors
    final Quaternion q =
        Quaternion.fromTwoVectors(v.xyz, Vector3(0.0, 0.0, -_radius));
    // get euler angles from rotation
    return quaternionToOrientation(
        q * Quaternion.axisAngle(Vector3(0, 1, 0), math.pi * 0.5));
  }

  Vector3 positionFromLatLon(double lat, double lon) {
    // create projection matrix
    final Matrix4 m = scene!.camera.projectionMatrix *
        scene!.camera.lookAtMatrix *
        matrixFromLatLon(lat, lon);
    // apply projection matrix
    final Vector4 v = Vector4(0.0, 0.0, -_radius, 1.0)..applyMatrix4(m);
    // apply perspective division and transform NDC to the viewport coordinate
    return Vector3(
      (1.0 + v.x / v.w) * scene!.camera.viewportWidth / 2,
      (1.0 - v.y / v.w) * scene!.camera.viewportHeight / 2,
      v.z,
    );
  }

  Widget buildHotspotWidgets(List<BaseHotspot>? hotspots) {
    if (hotspots == null || scene == null) return const SizedBox();

    return HotspotLayer(
      hotspots: hotspots,
      scene: scene!,
      updateStream: _stream,
    );
  }

  @override
  void initState() {
    super.initState();
    latitudeRad = radians(widget.latitude);
    longitudeRad = radians(widget.longitude);
    orientation = Vector3(0, radians(90), 0);

    _originalAnimSpeed = widget.animSpeed;
    _animSpeed = widget.animSpeed;

    _streamController = StreamController<Null>.broadcast();
    _stream = _streamController.stream;

    _updateSensorControl();

    _controller = AnimationController(
        duration: const Duration(milliseconds: 60000), vsync: this)
      // Animation updates are user-independent but should respect selection mode
      // We don't force updates here to allow selection mode to block animations
      ..addListener(() => _updateView());
    if (widget.sensorControl != SensorControl.none || _animSpeed != 0) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _textureUpdateTimer?.cancel();
    _processedImage?.dispose();
    _lastImageInfo = null;
    _imageStream?.removeListener(ImageStreamListener(_updateTexture));
    _orientationSubscription?.cancel();
    _screenOrientSubscription?.cancel();
    _controller.dispose();
    _streamController.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(PanoramaViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.child?.image != oldWidget.child?.image) {
      _loadImage();

      // Update the coordinate converter when the image changes
      if (widget.selectionController != null && scene != null) {
        widget.selectionController!.setConverter(
          CoordinateConverter(
            scene!,
            _radius,
            croppedArea: widget.croppedArea,
            croppedFullWidth: widget.croppedFullWidth,
            croppedFullHeight: widget.croppedFullHeight,
          ),
        );
      }
    }

    if (widget.sensorControl != oldWidget.sensorControl) {
      _updateSensorControl();
    }

    // Update shader controller if changed
    if (widget.shaderController != oldWidget.shaderController) {
      scene?.shaderController = widget.shaderController;
      if (_lastImageInfo != null) {
        _updateTexture(_lastImageInfo!, false);
      }
    }

    // Store new original value if animSpeed changes
    if (widget.animSpeed != oldWidget.animSpeed) {
      _originalAnimSpeed = widget.animSpeed;
    }

    // Check if selection state changed
    bool wasInSelection =
        oldWidget.selectionController?.currentType != SelectionType.none;
    bool isInSelection =
        widget.selectionController?.currentType != SelectionType.none;

    if (wasInSelection != isInSelection) {
      if (isInSelection) {
        // Entering selection mode - force stop animation
        _animSpeed = 0;
        _controller.stop();
      } else {
        // Exiting selection mode - restore original speed
        _animSpeed = _originalAnimSpeed;
        if (_animSpeed != 0) {
          _controller.repeat();
        }
        // Force view update when exiting selection mode
        // This ensures the panorama position is immediately updated after selection ends
        _updateView(forceUpdate: true);
      }
    }

    if (widget.selectionController != oldWidget.selectionController) {
      widget.selectionController?.setConverter(
        CoordinateConverter(
          scene!,
          _radius,
          croppedArea: widget.croppedArea,
          croppedFullWidth: widget.croppedFullWidth,
          croppedFullHeight: widget.croppedFullHeight,
        ),
      );
    }

    // Update the converter if cropped area changes
    if (widget.croppedArea != oldWidget.croppedArea ||
        widget.croppedFullWidth != oldWidget.croppedFullWidth ||
        widget.croppedFullHeight != oldWidget.croppedFullHeight) {
      widget.selectionController?.setConverter(
        CoordinateConverter(
          scene!,
          _radius,
          croppedArea: widget.croppedArea,
          croppedFullWidth: widget.croppedFullWidth,
          croppedFullHeight: widget.croppedFullHeight,
        ),
      );
    }

    // Force update view if latitude or longitude changed
    if (widget.latitude != oldWidget.latitude ||
        widget.longitude != oldWidget.longitude) {
      latitudeRad = radians(widget.latitude);
      longitudeRad = radians(widget.longitude);
      // Force view update when latitude/longitude props change
      // This ensures the panorama moves to the new position even in selection mode
      _updateView(forceUpdate: true);
    }
  }

  // Add the setZoom method here
  void setZoom(double zoomLevel) {
    setState(() {
      zoomDelta = zoomLevel - scene!.camera.zoom;
      if (!_controller.isAnimating) {
        _controller.reset();
        _controller.repeat();
      }
      // Force view update for programmatic zoom change
      // This ensures zoom changes are applied even in selection mode
      _updateView(forceUpdate: true);
    });
  }

  void setView(double newLatitude, double newLongitude) {
    setState(() {
      longitudeRad = longitudeRad % (2 * pi);
      latitudeRad = max(min(latitudeRad, pi / 2), -pi / 2);

      double newLongitudeRad = radians(newLongitude) % (2 * pi);
      double newLatitudeRad = max(min(radians(newLatitude), pi / 2), -pi / 2);

      latitudeDelta = ((newLatitudeRad - latitudeRad) + pi) % (2 * pi) - pi;
      longitudeDelta = ((newLongitudeRad - longitudeRad) + pi) % (2 * pi) - pi;

      if (!_controller.isAnimating) {
        _controller.reset();
        _controller.repeat();
      }
      // Force view update for programmatic position change
      // This ensures the panorama moves to the specified position even in selection mode
      _updateView(forceUpdate: true);
    });
  }

  void setAnimSpeed(double newSpeed) {
    setState(() {
      _animSpeed = newSpeed;
      if (!_controller.isAnimating) {
        _controller.reset();
        _controller.repeat();
      }
      // Force view update for animation speed change
      // This ensures animation changes are applied even in selection mode
      _updateView(forceUpdate: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget pano = Stack(
      children: [
        Cube(
          interactive: false,
          onSceneCreated: _onSceneCreated,
          backgroundColor: widget.backgroundColor,
        ),
        if (widget.selectionController != null && scene != null)
          StreamBuilder(
            // Use StreamBuilder to update with panorama
            stream: _stream,
            builder: (context, _) {
              return ListenableBuilder(
                listenable: widget.selectionController!,
                builder: (context, _) {
                  return CustomPaint(
                    painter: SelectionPainter(
                      currentSelection:
                          widget.selectionController!.currentSelection,
                      completedSelections:
                          widget.selectionController!.selections,
                      scene: scene!,
                    ),
                    size: Size.infinite,
                  );
                },
              );
            },
          ),
        StreamBuilder(
          stream: _stream,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            return buildHotspotWidgets(widget.hotspots);
          },
        ),
      ],
    );

    // Wrap with LayoutBuilder to detect size changes
    Widget sizedPano = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Check if size has changed and emit stream event if it has
        if (scene != null &&
            (scene!.camera.viewportWidth != constraints.maxWidth ||
                scene!.camera.viewportHeight != constraints.maxHeight)) {
          // Update camera viewport size
          scene!.camera.viewportWidth = constraints.maxWidth;
          scene!.camera.viewportHeight = constraints.maxHeight;

          // Emit stream event to update hotspots
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _streamController.add(null);
          });
        }

        return pano;
      },
    );

    // Wrap with ListenableBuilder when selection controller is provided
    if (widget.selectionController != null) {
      return ListenableBuilder(
        listenable: widget.selectionController!,
        builder: (context, _) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            onTapUp: _isPanoramaMovementAllowed && widget.onTap != null
                ? _handleTapUp
                : null,
            onLongPressStart:
                _isPanoramaMovementAllowed && widget.onLongPressStart != null
                    ? _handleLongPressStart
                    : null,
            onLongPressMoveUpdate: _isPanoramaMovementAllowed &&
                    widget.onLongPressMoveUpdate != null
                ? _handleLongPressMoveUpdate
                : null,
            onLongPressEnd:
                _isPanoramaMovementAllowed && widget.onLongPressEnd != null
                    ? _handleLongPressEnd
                    : null,
            child: sizedPano,
          );
        },
      );
    }

    // Original GestureDetector if no selection controller
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onScaleStart: _isPanoramaMovementAllowed ? _handleScaleStart : null,
      onScaleUpdate: _isPanoramaMovementAllowed ? _handleScaleUpdate : null,
      onScaleEnd: _isPanoramaMovementAllowed ? _handleScaleEnd : null,
      onTapUp: _isPanoramaMovementAllowed && widget.onTap != null
          ? _handleTapUp
          : null,
      onLongPressStart:
          _isPanoramaMovementAllowed && widget.onLongPressStart != null
              ? _handleLongPressStart
              : null,
      onLongPressMoveUpdate:
          _isPanoramaMovementAllowed && widget.onLongPressMoveUpdate != null
              ? _handleLongPressMoveUpdate
              : null,
      onLongPressEnd:
          _isPanoramaMovementAllowed && widget.onLongPressEnd != null
              ? _handleLongPressEnd
              : null,
      child: sizedPano,
    );
  }

  // Add helper method to convert screen coordinates to LatLng
  LatLng screenToLatLng(Offset screenPoint) {
    final Vector3 o = positionToLatLon(screenPoint.dx, screenPoint.dy);
    return LatLng(degrees(-o.y), degrees(o.x));
  }

  double degrees(double rad) {
    return rad * 180.0 / pi;
  }

  double radians(double deg) {
    return deg * pi / 180.0;
  }

  /// Returns the original image size if available
  Size? getOriginalImageSize() {
    if (_processedImage != null) {
      return Size(
        _processedImage!.width.toDouble(),
        _processedImage!.height.toDouble(),
      );
    }
    return null;
  }

  /// Toggle debug mode for selections
  ///
  /// When debug mode is enabled, the processed (split) selections will be shown
  /// instead of the original selections.
  ///
  /// @param enable Whether to enable debug mode
  void setSelectionsDebugMode(bool enable) {
    widget.selectionController?.setDebugMode(enable);
  }

  /// Get the current debug mode state
  bool getSelectionsDebugMode() {
    return widget.selectionController?.debugMode ?? false;
  }

  /// Get the processed selections
  ///
  /// This method returns the processed selections (split polygons).
  /// These are the selections that should be used for processing, not for display.
  ///
  /// @return List of processed selections
  List<Selection> getProcessedSelections() {
    return widget.selectionController?.getProcessedSelections() ?? [];
  }

  /// Get the original selections
  ///
  /// This method returns the original selections (unsplit polygons).
  /// These are the selections that were drawn by the user.
  ///
  /// @return List of original selections
  List<Selection> getOriginalSelections() {
    return widget.selectionController?.getOriginalSelections() ?? [];
  }

  /// Check if a selection has been split
  ///
  /// This method checks if a selection has been split into multiple parts.
  ///
  /// @param originalSelectionId The ID of the original selection
  /// @return True if the selection has been split, false otherwise
  bool isSelectionSplit(String originalSelectionId) {
    return widget.selectionController?.isSelectionSplit(originalSelectionId) ??
        false;
  }

  /// Get the number of parts a selection has been split into
  ///
  /// This method returns the number of parts a selection has been split into.
  /// If the selection has not been split, it returns 1.
  ///
  /// @param originalSelectionId The ID of the original selection
  /// @return The number of parts the selection has been split into
  int getSelectionPartCount(String originalSelectionId) {
    return widget.selectionController
            ?.getSelectionPartCount(originalSelectionId) ??
        0;
  }

  /// Get the processed selections for a specific original selection
  ///
  /// This method returns the processed selections for a specific original selection.
  ///
  /// @param originalSelectionId The ID of the original selection
  /// @return List of processed selections for the original selection
  List<Selection> getProcessedSelectionsForOriginal(
      String originalSelectionId) {
    return widget.selectionController
            ?.getProcessedSelectionsForOriginal(originalSelectionId) ??
        [];
  }
}

Mesh generateSphereMesh(
    {num radius = 1.0,
    int latSegments = 16,
    int lonSegments = 16,
    ui.Image? texture,
    Rect croppedArea = const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0),
    double croppedFullWidth = 1.0,
    double croppedFullHeight = 1.0}) {
  int count = (latSegments + 1) * (lonSegments + 1);
  List<Vector3> vertices = List<Vector3>.filled(count, Vector3.zero());
  List<Offset> texcoords = List<Offset>.filled(count, Offset.zero);
  List<Polygon> indices =
      List<Polygon>.filled(latSegments * lonSegments * 2, Polygon(0, 0, 0));

  int i = 0;
  for (int y = 0; y <= latSegments; ++y) {
    final double tv = y / latSegments;
    final double v =
        (croppedArea.top + croppedArea.height * tv) / croppedFullHeight;
    final double sv = math.sin(v * math.pi);
    final double cv = math.cos(v * math.pi);
    for (int x = 0; x <= lonSegments; ++x) {
      final double tu = x / lonSegments;
      final double u =
          (croppedArea.left + croppedArea.width * tu) / croppedFullWidth;
      vertices[i] = Vector3(radius * math.cos(u * math.pi * 2.0) * sv,
          radius * cv, radius * math.sin(u * math.pi * 2.0) * sv);
      texcoords[i] = Offset(tu, 1.0 - tv);
      i++;
    }
  }

  i = 0;
  for (int y = 0; y < latSegments; ++y) {
    final int base1 = (lonSegments + 1) * y;
    final int base2 = (lonSegments + 1) * (y + 1);
    for (int x = 0; x < lonSegments; ++x) {
      indices[i++] = Polygon(base1 + x, base1 + x + 1, base2 + x);
      indices[i++] = Polygon(base1 + x + 1, base2 + x + 1, base2 + x);
    }
  }

  final Mesh mesh = Mesh(
      vertices: vertices,
      texcoords: texcoords,
      indices: indices,
      texture: texture);
  return mesh;
}

Vector3 quaternionToOrientation(Quaternion q) {
  // final Matrix4 m = Matrix4.compose(Vector3.zero(), q, Vector3.all(1.0));
  // final Vector v = motionSensors.getOrientation(m);
  // return Vector3(v.z, v.y, v.x);
  final storage = q.storage;
  final double x = storage[0];
  final double y = storage[1];
  final double z = storage[2];
  final double w = storage[3];
  final double roll =
      math.atan2(-2 * (x * y - w * z), 1.0 - 2 * (x * x + z * z));
  final double pitch = math.asin(2 * (y * z + w * x));
  final double yaw =
      math.atan2(-2 * (x * z - w * y), 1.0 - 2 * (x * x + y * y));
  return Vector3(yaw, pitch, roll);
}

Quaternion orientationToQuaternion(Vector3 v) {
  final Matrix4 m = Matrix4.identity();
  m.rotateZ(v.z);
  m.rotateX(v.y);
  m.rotateY(v.x);
  return Quaternion.fromRotation(m.getRotation());
}

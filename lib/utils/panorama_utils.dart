import 'dart:math';

import 'package:flutter/material.dart';
import 'package:panorama_viewer/cube/scene.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:panorama_viewer/selection/models/index.dart';

Vector3 quaternionToOrientation(Quaternion q) {
  final storage = q.storage;
  final double x = storage[0];
  final double y = storage[1];
  final double z = storage[2];
  final double w = storage[3];
  final double roll = atan2(-2 * (x * y - w * z), 1.0 - 2 * (x * x + z * z));
  final double pitch = asin(2 * (y * z + w * x));
  final double yaw = atan2(-2 * (x * z - w * y), 1.0 - 2 * (x * x + y * y));
  return Vector3(yaw, pitch, roll);
}

class CoordinateConverter {
  final Scene scene;
  final double radius;
  // Add properties for cropped panoramas
  final Rect croppedArea;
  final double croppedFullWidth;
  final double croppedFullHeight;

  CoordinateConverter(
    this.scene,
    this.radius, {
    this.croppedArea = const Rect.fromLTWH(0.0, 0.0, 1.0, 1.0),
    this.croppedFullWidth = 1.0,
    this.croppedFullHeight = 1.0,
  });

  Vector3 positionToLatLon(double x, double y) {
    // transform viewport coordinate to NDC, values between -1 and 1
    final Vector4 v = Vector4(2.0 * x / scene.camera.viewportWidth - 1.0,
        1.0 - 2.0 * y / scene.camera.viewportHeight, 1.0, 1.0);
    // create projection matrix
    final Matrix4 m = scene.camera.projectionMatrix * scene.camera.lookAtMatrix;
    // apply inversed projection matrix
    m.invert();
    v.applyMatrix4(m);
    // apply perspective division
    v.scale(1 / v.w);
    // get rotation from two vectors
    final Quaternion q =
        Quaternion.fromTwoVectors(v.xyz, Vector3(0.0, 0.0, -radius));
    // get euler angles from rotation
    return quaternionToOrientation(
        q * Quaternion.axisAngle(Vector3(0, 1, 0), pi * 0.5));
  }

  Vector3 positionFromLatLon(double lat, double lon) {
    // create projection matrix
    final Matrix4 m = scene.camera.projectionMatrix *
        scene.camera.lookAtMatrix *
        matrixFromLatLon(lat, lon);
    // apply projection matrix
    final Vector4 v = Vector4(0.0, 0.0, -radius, 1.0)..applyMatrix4(m);
    // apply perspective division and transform NDC to the viewport coordinate
    return Vector3(
      (1.0 + v.x / v.w) * scene.camera.viewportWidth / 2,
      (1.0 - v.y / v.w) * scene.camera.viewportHeight / 2,
      v.z,
    );
  }

  Matrix4 matrixFromLatLon(double lat, double lon) {
    return Matrix4.rotationY(radians(90.0 - lon))..rotateX(radians(lat));
  }

  double degrees(double rad) => rad * 180.0 / pi;
  double radians(double deg) => deg * pi / 180.0;

  /// Converts a LatLng point to image pixel coordinates
  /// This conversion is independent of viewport size, zoom, or camera orientation
  /// @param point The LatLng point to convert
  /// @param imageSize The size of the original panorama image
  /// @return The pixel coordinates in the original image
  Offset latLngToImageCoordinate(LatLng point, Size imageSize) {
    // For a full equirectangular image:
    // x = (longitude + 180) * width / 360
    // y = (90 - latitude) * height / 180

    // Adjust for cropped panoramas
    final double normalizedLon = (point.longitude + 180) / 360;
    final double normalizedLat = (90 - point.latitude) / 180;

    // Map to the cropped area
    final double croppedNormalizedLon =
        (normalizedLon - croppedArea.left) / croppedArea.width;
    final double croppedNormalizedLat =
        (normalizedLat - croppedArea.top) / croppedArea.height;

    // Convert to pixel coordinates
    return Offset(
      croppedNormalizedLon * imageSize.width,
      croppedNormalizedLat * imageSize.height,
    );
  }

  /// Converts image pixel coordinates to a LatLng point
  /// This conversion is independent of viewport size, zoom, or camera orientation
  /// @param point The pixel coordinates in the original image
  /// @param imageSize The size of the original panorama image
  /// @return The corresponding LatLng point
  LatLng imageCoordinateToLatLng(Offset point, Size imageSize) {
    // Normalize coordinates to [0, 1] range within the cropped area
    final double croppedNormalizedLon = point.dx / imageSize.width;
    final double croppedNormalizedLat = point.dy / imageSize.height;

    // Map to the full panorama
    final double normalizedLon =
        croppedArea.left + (croppedNormalizedLon * croppedArea.width);
    final double normalizedLat =
        croppedArea.top + (croppedNormalizedLat * croppedArea.height);

    // Convert to latitude and longitude
    final double longitude = (normalizedLon * 360) - 180;
    final double latitude = 90 - (normalizedLat * 180);

    return LatLng(latitude, longitude);
  }

  /// Converts a list of LatLng points to image pixel coordinates
  /// @param points The list of LatLng points to convert
  /// @param imageSize The size of the original panorama image
  /// @return The list of pixel coordinates in the original image
  List<Offset> latLngListToImageCoordinates(
      List<LatLng> points, Size imageSize) {
    return points
        .map((point) => latLngToImageCoordinate(point, imageSize))
        .toList();
  }

  /// Converts a list of image pixel coordinates to LatLng points
  /// @param points The list of pixel coordinates in the original image
  /// @param imageSize The size of the original panorama image
  /// @return The list of corresponding LatLng points
  List<LatLng> imageCoordinatesToLatLngList(
      List<Offset> points, Size imageSize) {
    return points
        .map((point) => imageCoordinateToLatLng(point, imageSize))
        .toList();
  }
}

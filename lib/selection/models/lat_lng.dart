/// Represents a geographical coordinate with latitude and longitude
class LatLng {
  /// The latitude in degrees, between -90 and 90
  final double latitude;

  /// The longitude in degrees, between -180 and 180
  final double longitude;

  /// Creates a new LatLng
  ///
  /// @param latitude The latitude in degrees
  /// @param longitude The longitude in degrees
  const LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng(lat: $latitude, lng: $longitude)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatLng &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

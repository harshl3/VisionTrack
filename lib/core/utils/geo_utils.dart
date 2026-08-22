import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);
}

class GeoUtils {
  static const double earthRadiusMeters = 6371000;

  static GeoPoint destinationPoint(
    double lat,
    double lng,
    double bearingDegrees,
    double distanceMeters,
  ) {
    final bearing = bearingDegrees * math.pi / 180;
    final latRad = lat * math.pi / 180;
    final lngRad = lng * math.pi / 180;
    final angularDistance = distanceMeters / earthRadiusMeters;

    final lat2 = math.asin(
      math.sin(latRad) * math.cos(angularDistance) +
          math.cos(latRad) * math.sin(angularDistance) * math.cos(bearing),
    );
    final lng2 = lngRad +
        math.atan2(
          math.sin(bearing) * math.sin(angularDistance) * math.cos(latRad),
          math.cos(angularDistance) - math.sin(latRad) * math.sin(lat2),
        );

    return GeoPoint(lat2 * 180 / math.pi, lng2 * 180 / math.pi);
  }

  static List<LatLng> buildCoverageWedge({
    required double latitude,
    required double longitude,
    required double azimuthDegrees,
    required double rangeMeters,
    double fieldOfViewDegrees = 60,
    int arcPoints = 20,
  }) {
    final center = LatLng(latitude, longitude);
    final points = <LatLng>[center];

    final startBearing = azimuthDegrees - (fieldOfViewDegrees / 2);
    final step = fieldOfViewDegrees / arcPoints;

    for (var i = 0; i <= arcPoints; i++) {
      final bearing = startBearing + (step * i);
      final edge = destinationPoint(latitude, longitude, bearing, rangeMeters);
      points.add(LatLng(edge.latitude, edge.longitude));
    }

    points.add(center);
    return points;
  }
}

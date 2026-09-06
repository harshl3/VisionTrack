import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../constants/app_colors.dart';
import '../../data/models/camera.dart';

/// Interactive Camera Marker Pin on Map
class CameraMarkerWidget extends StatelessWidget {
  final Color color;
  final double azimuthAngle;
  final bool isSelected;
  final VoidCallback? onTap;

  const CameraMarkerWidget({
    super.key,
    required this.color,
    this.azimuthAngle = 0.0,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Direction indicator arrow (if azimuth is set)
          if (azimuthAngle != 0)
            Transform.rotate(
              angle: azimuthAngle * (math.pi / 180),
              child: Transform.translate(
                offset: const Offset(0, -18),
                child: CustomPaint(
                  size: const Size(12, 12),
                  painter: _AzimuthArrowPainter(color: color),
                ),
              ),
            ),

          // Outer selection glow
          if (isSelected)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.3),
                border: Border.all(color: color, width: 2),
              ),
            ),

          // Main circular camera marker pin
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryNavy,
              border: Border.all(
                color: isSelected ? Colors.white : color,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.videocam_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AzimuthArrowPainter extends CustomPainter {
  final Color color;

  _AzimuthArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height * 0.7)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AzimuthArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Helper to calculate geodesic destination point given start, distance, bearing
LatLng calculateGeodesicPoint(LatLng start, double distanceMeters, double bearingDegrees) {
  const double earthRadius = 6378137.0; // WGS-84 equatorial radius
  final double distRatio = distanceMeters / earthRadius;
  final double bearingRad = bearingDegrees * (math.pi / 180.0);

  final double lat1 = start.latitude * (math.pi / 180.0);
  final double lon1 = start.longitude * (math.pi / 180.0);

  final double lat2 = math.asin(
    math.sin(lat1) * math.cos(distRatio) +
        math.cos(lat1) * math.sin(distRatio) * math.cos(bearingRad),
  );

  final double lon2 = lon1 +
      math.atan2(
        math.sin(bearingRad) * math.sin(distRatio) * math.cos(lat1),
        math.cos(distRatio) - math.sin(lat1) * math.sin(lat2),
      );

  return LatLng(lat2 * (180.0 / math.pi), lon2 * (180.0 / math.pi));
}

/// Builds directional vision cone (pie wedge) polygons based on azimuth angle and range
List<Polygon> buildCameraVisionCones(List<Camera> cameras) {
  return cameras.map((camera) {
    final center = LatLng(camera.latitude, camera.longitude);
    final range = camera.cameraRange <= 0 ? 50.0 : camera.cameraRange;
    final azimuth = camera.azimuthAngle;
    final isGovt = camera.cameraType.toLowerCase() == 'government';
    final baseColor = isGovt ? AppColors.govtCamera : AppColors.privateCamera;

    final List<LatLng> points = [center];

    // If azimuth angle is defined (> 0), draw a directional FOV cone (wedge)
    // Typically CCTV camera FOV is 60-70 degrees
    const double fov = 65.0;
    final double startAngle = azimuth - (fov / 2);
    final double endAngle = azimuth + (fov / 2);
    const int steps = 18;

    for (int i = 0; i <= steps; i++) {
      final double angle = startAngle + (endAngle - startAngle) * (i / steps);
      points.add(calculateGeodesicPoint(center, range, angle));
    }
    points.add(center); // Close polygon back to camera origin

    return Polygon(
      points: points,
      color: baseColor.withValues(alpha: 0.16),
      borderColor: baseColor.withValues(alpha: 0.55),
      borderStrokeWidth: 1.5,
    );
  }).toList();
}

/// Pulsating Blue Dot Live User Location Marker
class LiveUserLocationMarker extends StatelessWidget {
  const LiveUserLocationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse ring
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.25),
            ),
          ),
          // White border ring
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          // Inner solid blue dot
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }
}

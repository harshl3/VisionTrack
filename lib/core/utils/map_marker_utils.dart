import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

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
            child: Center(
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


import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<BitmapDescriptor> createCameraMarkerIcon(Color color) async {
  const int size = 48; // Clean, compact 48x48 icon size
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
  );

  final center = Offset(size / 2, size / 2);

  // 1. Dark background circle
  final bgPaint = Paint()
    ..color = const Color(0xFF0F172A)
    ..style = PaintingStyle.fill;
  canvas.drawCircle(center, 20, bgPaint);

  // 2. Colored border ring
  final borderPaint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  canvas.drawCircle(center, 20, borderPaint);

  // 3. Simple 2D Camera Icon inside
  final iconPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  // Main camera body
  final bodyRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(center.dx - 9, center.dy - 6, 14, 12),
    const Radius.circular(2.5),
  );
  canvas.drawRRect(bodyRect, iconPaint);

  // Lens Triangle
  final lensPath = Path()
    ..moveTo(center.dx + 5, center.dy - 3)
    ..lineTo(center.dx + 10, center.dy - 5)
    ..lineTo(center.dx + 10, center.dy + 5)
    ..lineTo(center.dx + 5, center.dy + 3)
    ..close();
  canvas.drawPath(lensPath, iconPaint);

  final picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(size, size);
  final ByteData? byteData = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  if (byteData == null) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  }
  final Uint8List bytes = byteData.buffer.asUint8List();
  return BitmapDescriptor.bytes(bytes);
}

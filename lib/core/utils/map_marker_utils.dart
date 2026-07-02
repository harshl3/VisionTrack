import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<BitmapDescriptor> createCameraMarkerIcon(Color color) async {
  const int size = 120;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
  );

  final paint = Paint()..color = color;
  final body = RRect.fromRectAndRadius(
    const Rect.fromLTWH(18, 36, 84, 52),
    const Radius.circular(16),
  );
  canvas.drawRRect(body, paint);

  final top = RRect.fromRectAndRadius(
    const Rect.fromLTWH(30, 18, 60, 26),
    const Radius.circular(12),
  );
  canvas.drawRRect(top, paint);

  final lensPaint = Paint()..color = Colors.white;
  canvas.drawCircle(const Offset(60, 62), 18, lensPaint);
  canvas.drawCircle(const Offset(60, 62), 12, paint);
  canvas.drawCircle(
    const Offset(54, 56),
    4,
    Paint()..color = Colors.white.withOpacity(0.8),
  );

  final picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(size, size);
  final ByteData? byteData = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  if (byteData == null) {
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  }
  final Uint8List bytes = byteData.buffer.asUint8List();
  return BitmapDescriptor.fromBytes(bytes);
}

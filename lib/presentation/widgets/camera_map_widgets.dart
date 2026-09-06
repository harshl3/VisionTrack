import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/camera.dart';

class CameraStatsCards extends StatelessWidget {
  final int totalCameras;
  final int activeCameras;
  final int recentlyAdded;

  const CameraStatsCards({
    super.key,
    required this.totalCameras,
    required this.activeCameras,
    required this.recentlyAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _StatCard(
          label: 'TOTAL CAMERAS',
          value: totalCameras.toString(),
          icon: Icons.videocam,
          color: AppColors.accentBlue,
        ),
        const SizedBox(height: 10),
        _StatCard(
          label: 'ACTIVE CAMERAS',
          value: activeCameras.toString(),
          icon: Icons.check_circle,
          color: AppColors.successGreen,
        ),
        const SizedBox(height: 10),
        _StatCard(
          label: 'RECENTLY ADDED',
          value: recentlyAdded.toString(),
          icon: Icons.fiber_new,
          color: AppColors.privateCamera,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 190,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.glassBackground : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.glassBorder : const Color(0xFFCBD5E1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        color: isDark ? AppColors.textWhite : const Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CameraInfoPopup extends StatelessWidget {
  final Camera camera;
  final VoidCallback onClose;

  const CameraInfoPopup({
    super.key,
    required this.camera,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textWhite : const Color(0xFF0F172A);
    final textGrey = isDark ? AppColors.textGrey : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.secondaryNavy.withValues(alpha: 0.90)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.accentBlue.withValues(alpha: 0.4)
                    : const Color(0xFF93C5FD),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black87 : Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          camera.cameraName,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.primaryNavy : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          camera.cameraType.toUpperCase(),
                          style: TextStyle(
                            color: isDark ? AppColors.textGrey : const Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: Icon(Icons.close, color: textGrey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    camera.status,
                    style: TextStyle(
                      color: camera.isActive ? AppColors.successGreen : AppColors.dangerRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (camera.serialNumber != null && camera.serialNumber!.isNotEmpty)
                    _detailRow('Serial No.', camera.serialNumber!, textColor, textGrey),
                  if (camera.cameraBrand != null && camera.cameraBrand!.isNotEmpty)
                    _detailRow('Brand', camera.cameraBrand!, textColor, textGrey),
                  _detailRow('Owner', camera.ownerName, textColor, textGrey),
                  _detailRow('Contact', camera.contactNumber, textColor, textGrey),
                  _detailRow('Latitude', camera.latitude.toStringAsFixed(6), textColor, textGrey),
                  _detailRow('Longitude', camera.longitude.toStringAsFixed(6), textColor, textGrey),
                  _detailRow('Azimuth', '${camera.azimuthAngle.toStringAsFixed(0)}°', textColor, textGrey),
                  _detailRow('Range', '${camera.cameraRange.toStringAsFixed(0)} m', textColor, textGrey),
                  if (camera.installationDate != null)
                    _detailRow('Installed', _formatDate(camera.installationDate!), textColor, textGrey),
                  if (camera.surveyorName != null)
                    _detailRow('Surveyor', camera.surveyorName!, textColor, textGrey),
                  _detailRow('Registered', _formatDate(camera.createdAt), textColor, textGrey),
                  if (camera.notes != null && camera.notes!.isNotEmpty)
                    _detailRow('Notes', camera.notes!, textColor, textGrey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color textColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: TextStyle(color: labelColor, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: textColor, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

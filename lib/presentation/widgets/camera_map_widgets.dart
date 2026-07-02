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
    return Container(
      width: 190,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryNavy),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 10)),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.secondaryNavy,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4)),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    camera.cameraName,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    camera.cameraType.toUpperCase(),
                    style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: AppColors.textGrey),
                ),
              ],
            ),
            Text(
              camera.status,
              style: TextStyle(
                color: camera.isActive ? AppColors.successGreen : AppColors.dangerRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _detailRow('Owner', camera.ownerName),
            _detailRow('Contact', camera.contactNumber),
            _detailRow('Latitude', camera.latitude.toStringAsFixed(6)),
            _detailRow('Longitude', camera.longitude.toStringAsFixed(6)),
            _detailRow('Azimuth', '${camera.azimuthAngle.toStringAsFixed(0)}°'),
            _detailRow('Range', '${camera.cameraRange.toStringAsFixed(0)} m'),
            if (camera.surveyorName != null) _detailRow('Surveyor', camera.surveyorName!),
            _detailRow('Registered', _formatDate(camera.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.textWhite, fontSize: 13)),
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

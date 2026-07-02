import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/map_styles.dart';
import '../../core/utils/geo_utils.dart';
import '../../core/utils/map_marker_utils.dart';
import '../../data/models/camera.dart';
import '../providers/auth_provider.dart';
import '../providers/camera_provider.dart';
import '../widgets/camera_map_widgets.dart';
import 'camera_registration_screen.dart';
import 'role_selection_screen.dart';

class SurveyorDashboardScreen extends StatefulWidget {
  const SurveyorDashboardScreen({super.key});

  @override
  State<SurveyorDashboardScreen> createState() =>
      _SurveyorDashboardScreenState();
}

class _SurveyorDashboardScreenState extends State<SurveyorDashboardScreen> {
  Camera? _selectedCamera;
  BitmapDescriptor? _cameraMarkerIcon;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CameraProvider>(context, listen: false).loadCameras();
    });
    _createCameraMarkerIcon();
  }

  Future<void> _createCameraMarkerIcon() async {
    final icon = await createCameraMarkerIcon(AppColors.privateCamera);
    if (!mounted) return;
    setState(() => _cameraMarkerIcon = icon);
  }

  Set<Marker> _buildMarkers(List<Camera> cameras) {
    return cameras.map((camera) {
      return Marker(
        markerId: MarkerId('camera_${camera.id}'),
        position: LatLng(camera.latitude, camera.longitude),
        icon:
            _cameraMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        onTap: () => setState(() => _selectedCamera = camera),
      );
    }).toSet();
  }

  Set<Polygon> _buildCoveragePolygons(List<Camera> cameras) {
    return cameras.map((camera) {
      return Polygon(
        polygonId: PolygonId('coverage_${camera.id}'),
        points: GeoUtils.buildCoverageWedge(
          latitude: camera.latitude,
          longitude: camera.longitude,
          azimuthDegrees: camera.azimuthAngle,
          rangeMeters: camera.cameraRange,
        ),
        fillColor: AppColors.accentBlue.withValues(alpha: 0.15),
        strokeColor: AppColors.accentBlue.withValues(alpha: 0.6),
        strokeWidth: 1,
      );
    }).toSet();
  }

  Future<void> _openRegistration() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CameraRegistrationScreen()),
    );

    if (added == true && mounted) {
      await Provider.of<CameraProvider>(context, listen: false).loadCameras();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraProvider = Provider.of<CameraProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final cameras = cameraProvider.cameras;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Surveyor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            tooltip: 'Add Camera',
            onPressed: _openRegistration,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            style: MapStyles.darkMapStyle,
            onMapCreated: (_) {},
            initialCameraPosition: const CameraPosition(
              target: LatLng(28.6139, 77.2090),
              zoom: 11,
            ),
            markers: _buildMarkers(cameras),
            polygons: _buildCoveragePolygons(cameras),
            myLocationEnabled: true,
          ),
          if (_selectedCamera != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: CameraInfoPopup(
                camera: _selectedCamera!,
                onClose: () => setState(() => _selectedCamera = null),
              ),
            ),
          if (cameraProvider.isLoading)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondaryNavy.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Welcome, ${authProvider.userName ?? 'Surveyor'}. '
                'You have registered ${cameras.length} camera(s).',
                style: const TextStyle(color: AppColors.textWhite),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRegistration,
        icon: const Icon(Icons.add),
        label: const Text('Add Camera'),
      ),
    );
  }
}

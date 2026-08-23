import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/map_marker_utils.dart';
import '../../data/models/camera.dart';
import '../providers/auth_provider.dart';
import '../providers/camera_provider.dart';
import '../widgets/camera_map_widgets.dart';
import '../widgets/glass_container.dart';
import 'camera_registration_screen.dart';
import 'role_selection_screen.dart';

class SurveyorDashboardScreen extends StatefulWidget {
  const SurveyorDashboardScreen({super.key});

  @override
  State<SurveyorDashboardScreen> createState() =>
      _SurveyorDashboardScreenState();
}

class _SurveyorDashboardScreenState extends State<SurveyorDashboardScreen> {
  int _currentTabIndex = 0;
  Camera? _selectedCamera;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CameraProvider>(context, listen: false).loadCameras();
    });
  }

  List<Marker> _buildMarkers(List<Camera> cameras) {
    return cameras.map((camera) {
      final isSelected = _selectedCamera?.id == camera.id;
      final isGovt = camera.cameraType.toLowerCase() == 'government';
      final markerColor = isGovt ? AppColors.govtCamera : AppColors.privateCamera;

      return Marker(
        point: LatLng(camera.latitude, camera.longitude),
        width: 48,
        height: 48,
        child: CameraMarkerWidget(
          color: markerColor,
          azimuthAngle: camera.azimuthAngle,
          isSelected: isSelected,
          onTap: () {
            setState(() => _selectedCamera = camera);
            _mapController.move(
              LatLng(camera.latitude, camera.longitude),
              16,
            );
          },
        ),
      );
    }).toList();
  }

  List<CircleMarker> _buildCoverageCircles(List<Camera> cameras) {
    return cameras.map((camera) {
      return CircleMarker(
        point: LatLng(camera.latitude, camera.longitude),
        radius: camera.cameraRange,
        useRadiusInMeter: true,
        color: AppColors.accentBlue.withValues(alpha: 0.12),
        borderColor: AppColors.accentBlue.withValues(alpha: 0.35),
        borderStrokeWidth: 1,
      );
    }).toList();
  }

  void _focusCameraOnMap(Camera camera) {
    setState(() {
      _selectedCamera = camera;
      _currentTabIndex = 0;
    });
    _mapController.move(
      LatLng(camera.latitude, camera.longitude),
      16,
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Session', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to log out of field surveyor session?',
          style: TextStyle(color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final navigator = Navigator.of(context);
      await Provider.of<AuthProvider>(context, listen: false).logout();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraProvider = Provider.of<CameraProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final cameras = cameraProvider.cameras;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        centerTitle: true,
        backgroundColor: AppColors.glassNavBg,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => cameraProvider.loadCameras(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.dangerRed),
            onPressed: _logout,
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildMapTab(cameraProvider, authProvider, cameras),
            _buildMyCamerasTab(cameras),
            CameraRegistrationScreen(
              isEmbeddedTab: true,
              onSuccess: () => cameraProvider.loadCameras(),
            ),
            _buildProfileTab(authProvider, cameraProvider, cameras),
          ],
        ),
      ),
      bottomNavigationBar: GlassBottomNavBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        items: const [
          GlassNavItem(
            icon: Icons.map_outlined,
            activeIcon: Icons.map,
            label: 'Survey',
            activeColor: AppColors.accentBlue,
          ),
          GlassNavItem(
            icon: Icons.list_alt_outlined,
            activeIcon: Icons.list_alt,
            label: 'Cameras',
            activeColor: AppColors.govtCamera,
          ),
          GlassNavItem(
            icon: Icons.add_a_photo_outlined,
            activeIcon: Icons.add_a_photo,
            label: 'Register',
            activeColor: AppColors.successGreen,
          ),
          GlassNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            activeColor: AppColors.purpleAccent,
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentTabIndex) {
      case 0:
        return 'Survey Map View';
      case 1:
        return 'My Registered Cameras';
      case 2:
        return 'Register New Camera';
      case 3:
        return 'Surveyor Profile';
      default:
        return 'Surveyor Dashboard';
    }
  }

  // TAB 0: MAP VIEW
  Widget _buildMapTab(CameraProvider cameraProvider, AuthProvider authProvider, List<Camera> cameras) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(28.6139, 77.2090),
            initialZoom: 11,
            minZoom: 3,
            maxZoom: 19,
            onTap: (_, __) {
              if (_selectedCamera != null) {
                setState(() => _selectedCamera = null);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.visiontrack.police_app',
            ),
            CircleLayer(circles: _buildCoverageCircles(cameras)),
            MarkerLayer(markers: _buildMarkers(cameras)),
          ],
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
          const Center(
            child: CircularProgressIndicator(color: AppColors.accentBlue),
          ),
        // Welcome banner at bottom
        Positioned(
          bottom: 88,
          left: 16,
          right: 16,
          child: GlassContainer(
            borderRadius: 16,
            blur: 14,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.explore, color: AppColors.accentBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Welcome, ${authProvider.userName ?? 'Surveyor'}. '
                    '${cameras.length} camera(s) registered.',
                    style: const TextStyle(color: AppColors.textWhite, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // TAB 1: MY CAMERAS LIST
  Widget _buildMyCamerasTab(List<Camera> cameras) {
    return SafeArea(
      child: cameras.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off_outlined, size: 64, color: AppColors.textGrey),
                  SizedBox(height: 16),
                  Text(
                    'No cameras registered yet.',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Use the Register tab to add cameras.',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: cameras.length,
              itemBuilder: (context, index) {
                final camera = cameras[index];
                return GlassCard(
                  onTap: () => _focusCameraOnMap(camera),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.videocam,
                          color: AppColors.accentBlue,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              camera.cameraName,
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${camera.ownerName} • Range: ${camera.cameraRange.toStringAsFixed(0)}m',
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (camera.isActive
                                      ? AppColors.successGreen
                                      : AppColors.dangerRed)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              camera.status,
                              style: TextStyle(
                                color: camera.isActive
                                    ? AppColors.successGreen
                                    : AppColors.dangerRed,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Icon(
                            Icons.location_searching,
                            color: AppColors.accentBlue,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // TAB 3: PROFILE SECTION
  Widget _buildProfileTab(AuthProvider authProvider, CameraProvider cameraProvider, List<Camera> cameras) {
    final activeCameras = cameras.where((c) => c.isActive).length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          // Profile Header Card
          GlassContainer(
            borderRadius: 24,
            blur: 16,
            padding: const EdgeInsets.all(24),
            borderColor: AppColors.accentBlue.withValues(alpha: 0.4),
            backgroundColor: Colors.black.withValues(alpha: 0.35),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentBlue.withValues(alpha: 0.2),
                    border: Border.all(color: AppColors.accentBlue, width: 2),
                  ),
                  child: const Icon(
                    Icons.person_pin_circle,
                    size: 50,
                    color: AppColors.accentBlue,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  authProvider.userName ?? 'Field Surveyor',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'VisionTrack Field Operative',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.badge, color: AppColors.accentBlue, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'ROLE: FIELD SURVEYOR',
                        style: TextStyle(
                          color: AppColors.accentBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'REGISTERED',
                  cameras.length.toString(),
                  Icons.videocam,
                  AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'ACTIVE',
                  activeCameras.toString(),
                  Icons.check_circle,
                  AppColors.successGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Account Info
          GlassContainer(
            borderRadius: 20,
            blur: 14,
            padding: const EdgeInsets.all(20),
            backgroundColor: Colors.black.withValues(alpha: 0.3),
            borderColor: AppColors.glassBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Details',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.person_outline, 'Operative Name', authProvider.userName ?? 'N/A'),
                _buildInfoRow(Icons.badge_outlined, 'Role', 'SURVEY (Field Operative)'),
                _buildInfoRow(Icons.map_outlined, 'GIS Engine', 'Google Maps Platform'),
                _buildInfoRow(Icons.security_outlined, 'Session', 'Active (JWT Auth)'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _logout,
              icon: const Icon(Icons.power_settings_new),
              label: const Text(
                'LOGOUT SESSION',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassContainer(
      borderRadius: 16,
      blur: 12,
      padding: const EdgeInsets.all(16),
      backgroundColor: Colors.black.withValues(alpha: 0.3),
      borderColor: color.withValues(alpha: 0.4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

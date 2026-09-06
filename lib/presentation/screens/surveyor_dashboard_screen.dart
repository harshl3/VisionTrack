import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/map_marker_utils.dart';
import '../../data/models/camera.dart';
import '../providers/auth_provider.dart';
import '../providers/camera_provider.dart';
import '../providers/theme_provider.dart';
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
  LatLng? _userLiveLocation;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CameraProvider>(context, listen: false).loadCameras();
    });
  }

  Future<void> _goToLiveLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showSnackbar('Location permission denied. Please allow GPS.', isError: true);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userLiveLocation = latLng;
      });
      _mapController.move(latLng, 16);
      _showSnackbar('Centered on your live location');
    } catch (e) {
      _showSnackbar('Could not fetch live location: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: isError ? AppColors.dangerRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.dangerRed.withValues(alpha: 0.12),
                ),
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  color: AppColors.dangerRed,
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'End Field Session',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out of your field surveyor session?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textGrey : const Color(0xFF475569),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.dangerRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Log Out',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.glassNavBg : const Color(0xFF1E3A5F),
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
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.darkGradient
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8FAFC), Color(0xFFEEF2F6), Color(0xFFE2E8F0)],
                ),
        ),
        child: IndexedStack(
          index: _currentTabIndex,
          children: [
            _buildMapTab(cameraProvider, authProvider, cameras, isDark),
            _buildMyCamerasTab(cameras, isDark),
            CameraRegistrationScreen(
              isEmbeddedTab: true,
              onSuccess: () => cameraProvider.loadCameras(),
            ),
            _buildProfileTab(authProvider, cameraProvider, cameras, isDark),
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
  Widget _buildMapTab(
      CameraProvider cameraProvider,
      AuthProvider authProvider,
      List<Camera> cameras,
      bool isDark) {
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
            // Standard Natural Light OpenStreetMap Tiles - No "API Required"
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.visiontrack.police_app',
            ),
            // Authentic CCTV Directional Vision Cones
            PolygonLayer(polygons: buildCameraVisionCones(cameras)),
            // Camera Markers
            MarkerLayer(markers: [
              ..._buildMarkers(cameras),
              // Live User Location Marker
              if (_userLiveLocation != null)
                Marker(
                  point: _userLiveLocation!,
                  width: 36,
                  height: 36,
                  child: const LiveUserLocationMarker(),
                ),
            ]),
          ],
        ),
        // Selected Camera Info Popup
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
        // Loading Spinner
        if (cameraProvider.isLoading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.accentBlue),
          ),
        // Live Location Floating Button
        Positioned(
          bottom: 96,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'surveyor_live_location',
            onPressed: _isLocating ? null : _goToLiveLocation,
            backgroundColor: isDark ? AppColors.secondaryNavy : Colors.white,
            foregroundColor: AppColors.accentBlue,
            elevation: 6,
            tooltip: 'My Live Location',
            child: _isLocating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.accentBlue,
                    ),
                  )
                : const Icon(Icons.my_location_rounded),
          ),
        ),
        // Status pill top-left
        Positioned(
          top: 16,
          left: 16,
          child: GlassContainer(
            borderRadius: 12,
            blur: 10,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: isDark
                ? Colors.black.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam, color: AppColors.accentBlue, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${cameras.length} Active Cameras',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
  Widget _buildMyCamerasTab(List<Camera> cameras, bool isDark) {
    return SafeArea(
      child: cameras.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off_outlined,
                    size: 64,
                    color: isDark ? AppColors.textGrey : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No cameras registered yet.',
                    style: TextStyle(
                      color: isDark ? AppColors.textGrey : const Color(0xFF475569),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the Register tab to add cameras.',
                    style: TextStyle(
                      color: isDark ? AppColors.textGrey : Colors.grey.shade500,
                      fontSize: 13,
                    ),
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
                              style: TextStyle(
                                color: isDark ? AppColors.textWhite : const Color(0xFF1E293B),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${camera.ownerName} • Range: ${camera.cameraRange.toStringAsFixed(0)}m',
                              style: TextStyle(
                                color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
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
  Widget _buildProfileTab(
      AuthProvider authProvider,
      CameraProvider cameraProvider,
      List<Camera> cameras,
      bool isDark) {
    final activeCameras = cameras.where((c) => c.isActive).length;
    final themeProvider = Provider.of<ThemeProvider>(context);

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
            backgroundColor: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.85),
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textWhite : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.userEmail ?? 'surveyor@visiontrack.gov',
                  style: TextStyle(
                    color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.4)),
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

          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'TOTAL CAMERAS',
                  cameras.length.toString(),
                  Icons.videocam,
                  AppColors.accentBlue,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'ACTIVE ONLINE',
                  activeCameras.toString(),
                  Icons.check_circle,
                  AppColors.successGreen,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Theme Toggle
          GlassContainer(
            borderRadius: 16,
            blur: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.85),
            borderColor: isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0),
            child: Row(
              children: [
                Icon(
                  themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
                  color: themeProvider.isDark
                      ? AppColors.purpleAccent
                      : const Color(0xFFF59E0B),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        themeProvider.isDark ? 'Dark Mode' : 'Light Mode',
                        style: TextStyle(
                          color: isDark ? AppColors.textWhite : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Tap switch to toggle theme',
                        style: TextStyle(
                          color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: !themeProvider.isDark,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  activeThumbColor: const Color(0xFFF59E0B),
                  inactiveTrackColor: AppColors.purpleAccent.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
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

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, bool isDark) {
    return GlassContainer(
      borderRadius: 16,
      blur: 12,
      padding: const EdgeInsets.all(16),
      backgroundColor: isDark
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.85),
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
                  style: TextStyle(
                    color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? AppColors.textWhite : const Color(0xFF0F172A),
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
}

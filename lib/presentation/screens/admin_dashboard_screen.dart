import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/map_styles.dart';
import '../../core/utils/map_marker_utils.dart';
import '../../data/models/camera.dart';
import '../providers/auth_provider.dart';
import '../providers/camera_provider.dart';
import '../widgets/camera_map_widgets.dart';
import '../widgets/glass_container.dart';
import 'role_selection_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentTabIndex = 0;
  GoogleMapController? _mapController;
  Camera? _selectedCamera;
  BitmapDescriptor? _cameraMarkerIcon;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _minRangeCtrl = TextEditingController();
  final TextEditingController _maxRangeCtrl = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    _createCameraMarkerIcon();
  }

  Future<void> _loadData() async {
    final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
    await cameraProvider.loadSurveyors();
    await cameraProvider.loadCameras();
    _fitMapToCameras(cameraProvider.filteredCameras);
  }

  void _fitMapToCameras(List<Camera> cameras) {
    if (_mapController == null || cameras.isEmpty) return;

    if (cameras.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(cameras.first.latitude, cameras.first.longitude),
          15,
        ),
      );
      return;
    }

    double minLat = cameras.first.latitude;
    double maxLat = cameras.first.latitude;
    double minLng = cameras.first.longitude;
    double maxLng = cameras.first.longitude;

    for (final camera in cameras) {
      minLat = minLat < camera.latitude ? minLat : camera.latitude;
      maxLat = maxLat > camera.latitude ? maxLat : camera.latitude;
      minLng = minLng < camera.longitude ? minLng : camera.longitude;
      maxLng = maxLng > camera.longitude ? maxLng : camera.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80,
      ),
    );
  }

  Set<Marker> _buildMarkers(List<Camera> cameras) {
    return cameras.map((camera) {
      return Marker(
        markerId: MarkerId('camera_${camera.id}'),
        position: LatLng(camera.latitude, camera.longitude),
        anchor: const Offset(0.5, 0.5),
        rotation: camera.azimuthAngle,
        icon: _cameraMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        onTap: () {
          setState(() => _selectedCamera = camera);
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(camera.latitude, camera.longitude)),
          );
        },
      );
    }).toSet();
  }

  Future<void> _createCameraMarkerIcon() async {
    final icon = await createCameraMarkerIcon(AppColors.privateCamera);
    if (!mounted) return;
    setState(() => _cameraMarkerIcon = icon);
  }

  Set<Circle> _buildCoverageCircles(List<Camera> cameras) {
    return cameras.map((camera) {
      return Circle(
        circleId: CircleId('coverage_${camera.id}'),
        center: LatLng(camera.latitude, camera.longitude),
        radius: camera.cameraRange,
        fillColor: AppColors.accentBlue.withValues(alpha: 0.12),
        strokeColor: AppColors.accentBlue.withValues(alpha: 0.35),
        strokeWidth: 1,
      );
    }).toSet();
  }

  Future<void> _applyFilters() async {
    final provider = Provider.of<CameraProvider>(context, listen: false);
    provider.setSearchQuery(_searchCtrl.text.trim());
    provider.setRangeFilter(
      min: double.tryParse(_minRangeCtrl.text.trim()),
      max: double.tryParse(_maxRangeCtrl.text.trim()),
    );
    await provider.loadCameras();
    if (mounted) {
      _fitMapToCameras(provider.filteredCameras);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to terminate HQ Admin session?',
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
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    }
  }

  void _focusCameraOnMap(Camera camera) {
    setState(() {
      _selectedCamera = camera;
      _currentTabIndex = 0;
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(camera.latitude, camera.longitude),
        16,
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _minRangeCtrl.dispose();
    _maxRangeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraProvider = Provider.of<CameraProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final cameras = cameraProvider.filteredCameras;

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
            onPressed: _loadData,
            tooltip: 'Refresh Data',
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
            _buildMapViewTab(cameraProvider, cameras),
            _buildCameraRegistryTab(cameraProvider, cameras),
            _buildSurveyorsTeamTab(cameraProvider),
            _buildAdminProfileTab(authProvider, cameraProvider),
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
            label: 'Map View',
            activeColor: AppColors.accentBlue,
          ),
          GlassNavItem(
            icon: Icons.videocam_outlined,
            activeIcon: Icons.videocam,
            label: 'Cameras',
            activeColor: AppColors.govtCamera,
          ),
          GlassNavItem(
            icon: Icons.groups_outlined,
            activeIcon: Icons.groups,
            label: 'Team',
            activeColor: AppColors.purpleAccent,
          ),
          GlassNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            activeColor: AppColors.dangerRed,
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentTabIndex) {
      case 0:
        return 'GIS Surveillance Map';
      case 1:
        return 'Camera Registry Database';
      case 2:
        return 'Surveyor Field Team';
      case 3:
        return 'HQ Admin Profile';
      default:
        return 'Admin Dashboard';
    }
  }

  // TAB 0: GIS MAP & ANALYTICS
  Widget _buildMapViewTab(CameraProvider cameraProvider, List<Camera> cameras) {
    return Stack(
      children: [
        GoogleMap(
          style: MapStyles.darkMapStyle,
          onMapCreated: (controller) {
            _mapController = controller;
            _fitMapToCameras(cameras);
          },
          initialCameraPosition: const CameraPosition(
            target: LatLng(28.6139, 77.2090),
            zoom: 11,
          ),
          markers: _buildMarkers(cameras),
          circles: _buildCoverageCircles(cameras),
          myLocationEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
        Positioned(
          top: 16,
          right: 16,
          child: CameraStatsCards(
            totalCameras: cameraProvider.totalCameras,
            activeCameras: cameraProvider.activeCameras,
            recentlyAdded: cameraProvider.recentlyAddedCameras,
          ),
        ),
        if (_selectedCamera != null)
          Positioned(
            top: 16,
            left: 16,
            child: CameraInfoPopup(
              camera: _selectedCamera!,
              onClose: () => setState(() => _selectedCamera = null),
            ),
          ),
        if (cameraProvider.isLoading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.accentBlue),
          ),
      ],
    );
  }

  // TAB 1: CAMERA REGISTRY LIST
  Widget _buildCameraRegistryTab(CameraProvider cameraProvider, List<Camera> cameras) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: GlassTextField(
              controller: _searchCtrl,
              hintText: 'Search camera name, owner, contact...',
              prefixIcon: Icons.search,
              suffixIcon: IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color: AppColors.accentBlue,
                ),
                onPressed: () => setState(() => _showFilters = !_showFilters),
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
          ),
          if (_showFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                backgroundColor: Colors.black.withValues(alpha: 0.35),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GlassTextField(
                            controller: _minRangeCtrl,
                            hintText: 'Min Range (m)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GlassTextField(
                            controller: _maxRangeCtrl,
                            hintText: 'Max Range (m)',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Apply Filters'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              cameraProvider.clearFilters();
                              _searchCtrl.clear();
                              _minRangeCtrl.clear();
                              _maxRangeCtrl.clear();
                              await cameraProvider.loadCameras();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textGrey,
                              side: const BorderSide(color: AppColors.textGrey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Clear'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: cameras.isEmpty
                ? const Center(
                    child: Text(
                      'No matching cameras found in network.',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
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
                                size: 28,
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
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Owner: ${camera.ownerName} • ${camera.contactNumber}',
                                    style: const TextStyle(
                                      color: AppColors.textGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Range: ${camera.cameraRange.toStringAsFixed(0)}m',
                                        style: const TextStyle(
                                          color: AppColors.govtCamera,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Azimuth: ${camera.azimuthAngle.toStringAsFixed(0)}°',
                                        style: const TextStyle(
                                          color: AppColors.textGrey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
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
                                const SizedBox(height: 8),
                                const Icon(
                                  Icons.location_searching,
                                  color: AppColors.accentBlue,
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // TAB 2: SURVEYORS FIELD TEAM LIST
  Widget _buildSurveyorsTeamTab(CameraProvider cameraProvider) {
    final surveyors = cameraProvider.surveyors;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          const Text(
            'Registered Field Surveyors',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total Active Surveyors: ${surveyors.length}',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (surveyors.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text(
                  'No field surveyors registered yet.',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
            )
          else
            ...surveyors.map((surveyor) {
              final camerasCount = cameraProvider.cameras
                  .where((c) => c.createdBy == surveyor.id)
                  .length;
              return GlassCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.purpleAccent.withValues(alpha: 0.2),
                      child: Text(
                        surveyor.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.purpleAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            surveyor.name,
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            surveyor.email,
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.accentBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$camerasCount',
                            style: const TextStyle(
                              color: AppColors.accentBlue,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            'Cameras',
                            style: TextStyle(
                              color: AppColors.textGrey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // TAB 3: ADMIN PROFILE SECTION
  Widget _buildAdminProfileTab(AuthProvider authProvider, CameraProvider cameraProvider) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          // Profile Glass Card Header
          GlassContainer(
            borderRadius: 24,
            blur: 16,
            padding: const EdgeInsets.all(24),
            borderColor: AppColors.dangerRed.withValues(alpha: 0.4),
            backgroundColor: Colors.black.withValues(alpha: 0.35),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.dangerRed.withValues(alpha: 0.2),
                    border: Border.all(color: AppColors.dangerRed, width: 2),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 50,
                    color: AppColors.dangerRed,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  authProvider.userName ?? 'HQ Admin Commander',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Police Central Surveillance Operations',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.dangerRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.dangerRed.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_user, color: AppColors.dangerRed, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'ROLE: POLICE ADMIN',
                        style: TextStyle(
                          color: AppColors.dangerRed,
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

          // Overview Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildProfileStatCard(
                  'TOTAL CAMERAS',
                  cameraProvider.totalCameras.toString(),
                  Icons.videocam,
                  AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProfileStatCard(
                  'ACTIVE SURVEYORS',
                  cameraProvider.surveyors.length.toString(),
                  Icons.group,
                  AppColors.purpleAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // System Info & Settings Glass List
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
                  'System Environment',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                _buildProfileInfoRow(Icons.dns_outlined, 'Backend Protocol', 'Node.js / Express GIS API'),
                _buildProfileInfoRow(Icons.security_outlined, 'Auth Security', 'JWT Token Encrypted'),
                _buildProfileInfoRow(Icons.map_outlined, 'GIS Provider', 'Google Maps Platform SDK'),
                _buildProfileInfoRow(Icons.check_circle_outline, 'System Status', 'Operational (Online)'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout Action Button
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
                'LOGOUT ADMIN SESSION',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatCard(String label, String value, IconData icon, Color color) {
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

  Widget _buildProfileInfoRow(IconData icon, String title, String value) {
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
          Text(
            value,
            style: const TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

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
import 'role_selection_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentTabIndex = 0;
  final MapController _mapController = MapController();
  Camera? _selectedCamera;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _minRangeCtrl = TextEditingController();
  final TextEditingController _maxRangeCtrl = TextEditingController();
  bool _showFilters = false;

  // Area search state
  LatLng? _areaCenter;
  double _areaRadius = 500;
  bool _showAreaSearch = false;
  List<Camera> _areaFilteredCameras = [];

  // Live GPS state
  LatLng? _userLiveLocation;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
    await cameraProvider.loadSurveyors();
    await cameraProvider.loadCameras();
    if (mounted) {
      _fitMapToCameras(cameraProvider.filteredCameras);
    }
  }

  void _fitMapToCameras(List<Camera> cameras) {
    if (cameras.isEmpty) return;
    if (cameras.length == 1) {
      _mapController.move(LatLng(cameras.first.latitude, cameras.first.longitude), 15);
      return;
    }
    final points = cameras.map((c) => LatLng(c.latitude, c.longitude)).toList();
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(70)),
    );
  }


  void _applyAreaSearch(List<Camera> allCameras) {
    if (_areaCenter == null) return;
    const Distance distance = Distance();
    setState(() {
      _areaFilteredCameras = allCameras.where((c) {
        final d = distance.as(
          LengthUnit.Meter,
          LatLng(c.latitude, c.longitude),
          _areaCenter!,
        );
        return d <= _areaRadius;
      }).toList();
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
            _mapController.move(LatLng(camera.latitude, camera.longitude), 16);
          },
        ),
      );
    }).toList();
  }


  Future<void> _applyFilters() async {
    final provider = Provider.of<CameraProvider>(context, listen: false);
    provider.setSearchQuery(_searchCtrl.text.trim());
    provider.setRangeFilter(
      min: double.tryParse(_minRangeCtrl.text.trim()),
      max: double.tryParse(_maxRangeCtrl.text.trim()),
    );
    await provider.loadCameras();
    if (mounted) _fitMapToCameras(provider.filteredCameras);
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
                'Confirm Admin Logout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to terminate your Headquarters Admin command session?',
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
    _mapController.move(LatLng(camera.latitude, camera.longitude), 16);
  }

  void _showSnackbar(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    Color color = isError
        ? AppColors.dangerRed
        : isSuccess
            ? AppColors.successGreen
            : AppColors.accentBlue;
    IconData icon = isError
        ? Icons.error_outline
        : isSuccess
            ? Icons.check_circle_outline
            : Icons.info_outline;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _confirmDeleteCamera(Camera camera) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Camera'),
        content: Text(
          'Are you sure you want to permanently delete "${camera.cameraName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final provider = Provider.of<CameraProvider>(context, listen: false);
    final success = await provider.deleteCameraById(camera.id);
    if (success) {
      if (_selectedCamera?.id == camera.id) setState(() => _selectedCamera = null);
      _showSnackbar('Camera "${camera.cameraName}" deleted.', isSuccess: true);
    } else {
      _showSnackbar(provider.error ?? 'Failed to delete camera.', isError: true);
    }
  }

  Future<void> _toggleCameraStatus(Camera camera) async {
    final newStatus = camera.isActive ? 'OFFLINE' : 'ACTIVE';
    final provider = Provider.of<CameraProvider>(context, listen: false);
    final success = await provider.updateCameraStatus(camera.id, newStatus);
    if (success) {
      _showSnackbar(
        '${camera.cameraName} marked as $newStatus.',
        isSuccess: true,
      );
    } else {
      _showSnackbar(provider.error ?? 'Failed to update status.', isError: true);
    }
  }

  Future<void> _confirmDeleteSurveyor(SurveyorUser surveyor) async {
    final camerasCount = Provider.of<CameraProvider>(context, listen: false)
        .cameras
        .where((c) => c.createdBy == surveyor.id)
        .length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Surveyor'),
        content: Text(
          'Are you sure you want to remove surveyor "${surveyor.name}"?\n\n'
          '${camerasCount > 0 ? '⚠️ This surveyor has $camerasCount registered camera(s). Their cameras will remain in the system.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final provider = Provider.of<CameraProvider>(context, listen: false);
    final success = await provider.deleteSurveyor(surveyor.id);
    if (success) {
      _showSnackbar('Surveyor "${surveyor.name}" removed.', isSuccess: true);
    } else {
      _showSnackbar(provider.error ?? 'Failed to remove surveyor.', isError: true);
    }
  }

  void _showSurveyorDetailSheet(SurveyorUser surveyor, List<Camera> allCameras) {
    final surveyorCameras =
        allCameras.where((c) => c.createdBy == surveyor.id).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.purpleAccent.withValues(alpha: 0.2),
                child: Text(
                  surveyor.name.isNotEmpty ? surveyor.name[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    color: AppColors.purpleAccent,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                surveyor.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                surveyor.email,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ID: #${surveyor.id} • Field Surveyor',
                  style: const TextStyle(
                    color: AppColors.accentBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${surveyorCameras.length}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentBlue,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cameras Added',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${surveyorCameras.where((c) => c.isActive).length}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.successGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Active Online',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textGrey : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (surveyorCameras.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        _searchCtrl.text = surveyor.name;
                        _currentTabIndex = 1;
                      });
                      _applyFilters();
                    },
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('View Registered Cameras'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDeleteSurveyor(surveyor);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Surveyor Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dangerRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAreaSearchSheet(List<Camera> allCameras) {
    final mapCenter = _mapController.camera.center;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AreaSearchSheet(
        initialCenter: _areaCenter ?? mapCenter,
        initialRadius: _areaRadius,
        onSearch: (center, radius) {
          final effectiveCenter = center ?? _areaCenter ?? mapCenter;
          setState(() {
            _areaCenter = effectiveCenter;
            _areaRadius = radius;
            _showAreaSearch = true;
          });
          _applyAreaSearch(allCameras);
          _mapController.move(effectiveCenter, 14);
          Navigator.pop(context);
          _showSnackbar(
            'Found ${_areaFilteredCameras.length} cameras within ${(radius / 1000).toStringAsFixed(1)}km',
            isSuccess: true,
          );
        },
        onClear: () {
          setState(() {
            _areaCenter = null;
            _showAreaSearch = false;
            _areaFilteredCameras = [];
          });
          Navigator.pop(context);
        },
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        centerTitle: true,
        backgroundColor:
            isDark ? AppColors.glassNavBg : const Color(0xFF1E3A5F),
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
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0F4F8), Color(0xFFE2E8F0), Color(0xFFDDE9F5)],
          ),
        ),
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

  // TAB 0: MAP VIEW
  Widget _buildMapViewTab(CameraProvider cameraProvider, List<Camera> cameras) {
    final displayCams = _showAreaSearch ? _areaFilteredCameras : cameras;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              if (_selectedCamera != null) setState(() => _selectedCamera = null);
            },
          ),
          children: [
            // Standard Natural Light OpenStreetMap Tiles - No "API Required"
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.visiontrack.police_app',
            ),
            // Area search highlighted circle
            if (_areaCenter != null && _showAreaSearch)
              CircleLayer(circles: [
                CircleMarker(
                  point: _areaCenter!,
                  radius: _areaRadius,
                  useRadiusInMeter: true,
                  color: AppColors.warningOrange.withValues(alpha: 0.22),
                  borderColor: AppColors.warningOrange,
                  borderStrokeWidth: 2.5,
                ),
              ]),
            // CCTV Directional Vision Cones
            PolygonLayer(polygons: buildCameraVisionCones(displayCams)),
            // Camera & Location Markers
            MarkerLayer(markers: [
              ..._buildMarkers(displayCams),
              // Live User Location
              if (_userLiveLocation != null)
                Marker(
                  point: _userLiveLocation!,
                  width: 36,
                  height: 36,
                  child: const LiveUserLocationMarker(),
                ),
              // Area Search Center Pin
              if (_areaCenter != null && _showAreaSearch)
                Marker(
                  point: _areaCenter!,
                  width: 32,
                  height: 32,
                  child: const Center(
                    child: Icon(
                      Icons.location_on,
                      color: AppColors.warningOrange,
                      size: 32,
                    ),
                  ),
                ),
            ]),
          ],
        ),
        // Stats top right
        Positioned(
          top: 16,
          right: 16,
          child: CameraStatsCards(
            totalCameras: cameraProvider.totalCameras,
            activeCameras: cameraProvider.activeCameras,
            recentlyAdded: cameraProvider.recentlyAddedCameras,
          ),
        ),
        // Selected camera popup
        if (_selectedCamera != null)
          Positioned(
            top: 16,
            left: 16,
            child: CameraInfoPopup(
              camera: _selectedCamera!,
              onClose: () => setState(() => _selectedCamera = null),
            ),
          ),
        // Area search active indicator
        if (_showAreaSearch)
          Positioned(
            bottom: 160,
            left: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.travel_explore, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_areaFilteredCameras.length} cameras within ${(_areaRadius / 1000).toStringAsFixed(1)}km',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() {
                        _areaCenter = null;
                        _showAreaSearch = false;
                        _areaFilteredCameras = [];
                      }),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Dedicated Area Search FAB on Bottom-Left
        Positioned(
          bottom: 96,
          left: 16,
          child: FloatingActionButton.extended(
            heroTag: 'admin_area_search',
            onPressed: () => _showAreaSearchSheet(cameras),
            backgroundColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 6,
            icon: const Icon(Icons.travel_explore_rounded, size: 20),
            label: const Text(
              'Search Area',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ),
        // Dedicated Live GPS Location Button on Bottom-Right
        Positioned(
          bottom: 96,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'admin_live_location',
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
        if (cameraProvider.isLoading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.accentBlue),
          ),
      ],
    );
  }

  // TAB 1: CAMERA REGISTRY
  Widget _buildCameraRegistryTab(CameraProvider cameraProvider, List<Camera> cameras) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: GlassTextField(
              controller: _searchCtrl,
              hintText: 'Search name, serial, owner, brand...',
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
                backgroundColor: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.85),
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_off_outlined, size: 64,
                            color: isDark ? AppColors.textGrey : Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No matching cameras found.',
                          style: TextStyle(
                            color: isDark ? AppColors.textGrey : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: cameras.length,
                    itemBuilder: (context, index) {
                      final camera = cameras[index];
                      return _buildCameraCard(camera, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraCard(Camera camera, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 0 : 2,
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.videocam, color: AppColors.accentBlue, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    camera.cameraName,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (camera.serialNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'S/N: ${camera.serialNumber}',
                      style: TextStyle(
                        color: isDark ? AppColors.textGrey : Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${camera.ownerName} • ${camera.contactNumber}',
                    style: TextStyle(
                      color: isDark ? AppColors.textGrey : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${camera.cameraRange.toStringAsFixed(0)}m',
                        style: const TextStyle(
                          color: AppColors.govtCamera,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (camera.cameraBrand != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          camera.cameraBrand!,
                          style: TextStyle(
                            color: isDark ? AppColors.textGrey : Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (camera.isActive ? AppColors.successGreen : AppColors.dangerRed)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    camera.status,
                    style: TextStyle(
                      color: camera.isActive ? AppColors.successGreen : AppColors.dangerRed,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? AppColors.textGrey : Colors.grey.shade500,
                    size: 20,
                  ),
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'map') _focusCameraOnMap(camera);
                    if (value == 'toggle') _toggleCameraStatus(camera);
                    if (value == 'delete') _confirmDeleteCamera(camera);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'map',
                      child: Row(
                        children: [
                          const Icon(Icons.map_outlined, color: AppColors.accentBlue, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'View on Map',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            camera.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                            color: camera.isActive ? AppColors.warningOrange : AppColors.successGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            camera.isActive ? 'Mark Offline' : 'Mark Active',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, color: AppColors.dangerRed, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Delete Camera',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: SURVEYORS
  Widget _buildSurveyorsTeamTab(CameraProvider cameraProvider) {
    final surveyors = cameraProvider.surveyors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          Text(
            'Registered Field Surveyors',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textWhite : const Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${surveyors.length} surveyor(s)',
            style: TextStyle(
              color: isDark ? AppColors.textGrey : Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (surveyors.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  'No field surveyors registered yet.',
                  style: TextStyle(
                    color: isDark ? AppColors.textGrey : Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            ...surveyors.map((surveyor) {
              final camerasCount = cameraProvider.cameras
                  .where((c) => c.createdBy == surveyor.id)
                  .length;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isDark ? 0 : 2,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showSurveyorDetailSheet(surveyor, cameraProvider.cameras),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
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
                                style: TextStyle(
                                  color: isDark ? AppColors.textWhite : const Color(0xFF1E293B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                surveyor.email,
                                style: TextStyle(
                                  color: isDark ? AppColors.textGrey : Colors.grey.shade600,
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
                                'Cams',
                                style: TextStyle(color: AppColors.textGrey, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: isDark ? AppColors.textGrey : const Color(0xFF94A3B8),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // TAB 3: ADMIN PROFILE
  Widget _buildAdminProfileTab(AuthProvider authProvider, CameraProvider cameraProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          // Profile header
          GlassContainer(
            borderRadius: 24,
            blur: 16,
            padding: const EdgeInsets.all(24),
            borderColor: AppColors.dangerRed.withValues(alpha: 0.4),
            backgroundColor: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.7),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.dangerRed.withValues(alpha: 0.2),
                    border: Border.all(color: AppColors.dangerRed, width: 2),
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      size: 50, color: AppColors.dangerRed),
                ),
                const SizedBox(height: 14),
                Text(
                  authProvider.userName ?? 'HQ Admin Commander',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textWhite : const Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Police Central Surveillance Operations',
                  style: TextStyle(
                    color: isDark ? AppColors.textGrey : Colors.grey.shade600,
                    fontSize: 13,
                  ),
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

          // Stats
          Row(
            children: [
              Expanded(
                child: _buildProfileStatCard(
                  'TOTAL CAMERAS',
                  cameraProvider.totalCameras.toString(),
                  Icons.videocam,
                  AppColors.accentBlue,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProfileStatCard(
                  'ACTIVE SURVEYORS',
                  cameraProvider.surveyors.length.toString(),
                  Icons.group,
                  AppColors.purpleAccent,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Theme Toggle
          GlassContainer(
            borderRadius: 16,
            blur: 12,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            backgroundColor: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.7),
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
                          color: isDark ? AppColors.textWhite : const Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Tap to switch theme',
                        style: TextStyle(
                          color: isDark ? AppColors.textGrey : Colors.grey.shade500,
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

          const SizedBox(height: 16),


          const SizedBox(height: 24),

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

  Widget _buildProfileStatCard(
      String label, String value, IconData icon, Color color, bool isDark) {
    return GlassContainer(
      borderRadius: 16,
      blur: 12,
      padding: const EdgeInsets.all(16),
      backgroundColor: isDark
          ? Colors.black.withValues(alpha: 0.3)
          : Colors.white.withValues(alpha: 0.7),
      borderColor: color.withValues(alpha: 0.4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      color: isDark ? AppColors.textGrey : Colors.grey.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? AppColors.textWhite : const Color(0xFF1E293B),
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

// ── Area Search Bottom Sheet ──────────────────────────────────────────────────

class _AreaSearchSheet extends StatefulWidget {
  final LatLng? initialCenter;
  final double initialRadius;
  final void Function(LatLng? center, double radius) onSearch;
  final VoidCallback onClear;

  const _AreaSearchSheet({
    required this.initialCenter,
    required this.initialRadius,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<_AreaSearchSheet> createState() => _AreaSearchSheetState();
}

class _AreaSearchSheetState extends State<_AreaSearchSheet> {
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  late double _radius;

  @override
  void initState() {
    super.initState();
    _radius = widget.initialRadius;
    if (widget.initialCenter != null) {
      _latCtrl.text = widget.initialCenter!.latitude.toStringAsFixed(6);
      _lngCtrl.text = widget.initialCenter!.longitude.toStringAsFixed(6);
    }
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.my_location, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                'Search by Area',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E3A5F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Enter center coordinates and choose a search radius',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    labelText: 'Latitude',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _lngCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    labelText: 'Longitude',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  if (widget.initialCenter != null) {
                    _latCtrl.text = widget.initialCenter!.latitude.toStringAsFixed(6);
                    _lngCtrl.text = widget.initialCenter!.longitude.toStringAsFixed(6);
                  }
                },
                icon: const Icon(Icons.center_focus_strong, size: 16),
                label: const Text('Map Center', style: TextStyle(fontSize: 12)),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  try {
                    final pos = await Geolocator.getCurrentPosition(
                      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
                    );
                    _latCtrl.text = pos.latitude.toStringAsFixed(6);
                    _lngCtrl.text = pos.longitude.toStringAsFixed(6);
                  } catch (_) {}
                },
                icon: const Icon(Icons.my_location, size: 16),
                label: const Text('My GPS', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Radius: ${_radius >= 1000 ? '${(_radius / 1000).toStringAsFixed(1)} km' : '${_radius.toStringAsFixed(0)} m'}',
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF1E3A5F),
              fontWeight: FontWeight.w600,
            ),
          ),
          Slider(
            value: _radius,
            min: 100,
            max: 5000,
            divisions: 49,
            activeColor: theme.colorScheme.primary,
            inactiveColor: theme.colorScheme.primary.withValues(alpha: 0.2),
            onChanged: (v) => setState(() => _radius = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClear,
                  child: const Text('Clear Search'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    final lat = double.tryParse(_latCtrl.text.trim()) ?? widget.initialCenter?.latitude;
                    final lng = double.tryParse(_lngCtrl.text.trim()) ?? widget.initialCenter?.longitude;
                    if (lat != null && lng != null) {
                      widget.onSearch(LatLng(lat, lng), _radius);
                    }
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Search Area'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
import 'role_selection_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
        icon:
            _cameraMarkerIcon ??
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
        fillColor: AppColors.privateCamera.withValues(alpha: 0.18),
        strokeColor: AppColors.privateCamera.withValues(alpha: 0.7),
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
    final navigator = Navigator.of(context);
    await Provider.of<AuthProvider>(context, listen: false).logout();
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
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
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Log Out',
          ),
        ],
      ),
      drawer: Drawer(
        child: _buildSidebar(cameraProvider, authProvider, cameras),
      ),
      body: Stack(
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
            polygons: _buildCoveragePolygons(cameras),
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            top: 20,
            right: 20,
            child: CameraStatsCards(
              totalCameras: cameraProvider.totalCameras,
              activeCameras: cameraProvider.activeCameras,
              recentlyAdded: cameraProvider.recentlyAddedCameras,
            ),
          ),
          if (_selectedCamera != null)
            Positioned(
              top: 20,
              left: 20,
              child: CameraInfoPopup(
                camera: _selectedCamera!,
                onClose: () => setState(() => _selectedCamera = null),
              ),
            ),
          if (cameraProvider.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    CameraProvider cameraProvider,
    AuthProvider authProvider,
    List<Camera> cameras,
  ) {
    return Container(
      width: 320,
      color: AppColors.primaryNavy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'VisionTrack',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(onPressed: _logout, child: const Text('Log Out')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search owner, camera, contact...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () =>
                        setState(() => _showFilters = !_showFilters),
                  ),
                ),
                onSubmitted: (_) => _applyFilters(),
              ),
            ),
            if (_showFilters) _buildFilterPanel(cameraProvider),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: _applyFilters,
                child: const Text('Apply Filters'),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton(
                onPressed: () async {
                  cameraProvider.clearFilters();
                  _searchCtrl.clear();
                  _minRangeCtrl.clear();
                  _maxRangeCtrl.clear();
                  await cameraProvider.loadCameras();
                },
                child: const Text('Clear Filters'),
              ),
            ),
            const Divider(color: AppColors.secondaryNavy, height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'REGISTERED CAMERAS',
                style: TextStyle(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: cameras.isEmpty
                  ? const Center(
                      child: Text(
                        'No cameras found',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: cameras.length,
                      itemBuilder: (context, index) {
                        final camera = cameras[index];
                        return Card(
                          color: AppColors.secondaryNavy,
                          child: ListTile(
                            leading: const Icon(
                              Icons.videocam,
                              color: AppColors.privateCamera,
                            ),
                            title: Text(
                              camera.cameraName,
                              style: const TextStyle(
                                color: AppColors.textWhite,
                              ),
                            ),
                            subtitle: Text(
                              '${camera.ownerName} • ${camera.cameraRange.toStringAsFixed(0)}m',
                              style: const TextStyle(color: AppColors.textGrey),
                            ),
                            trailing: Text(
                              camera.status,
                              style: TextStyle(
                                color: camera.isActive
                                    ? AppColors.successGreen
                                    : AppColors.dangerRed,
                                fontSize: 12,
                              ),
                            ),
                            onTap: () {
                              setState(() => _selectedCamera = camera);
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLng(
                                  LatLng(camera.latitude, camera.longitude),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel(CameraProvider cameraProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minRangeCtrl,
                  decoration: const InputDecoration(labelText: 'Min Range (m)'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _maxRangeCtrl,
                  decoration: const InputDecoration(labelText: 'Max Range (m)'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: cameraProvider.selectedSurveyorId,
            decoration: const InputDecoration(labelText: 'Surveyor'),
            dropdownColor: AppColors.secondaryNavy,
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All Surveyors'),
              ),
              ...cameraProvider.surveyors.map(
                (s) => DropdownMenuItem<int?>(
                  value: s.id,
                  child: Text(s.name, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) {
              cameraProvider.setSurveyorFilter(value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: cameraProvider.fromDate ?? DateTime.now(),
                    );
                    if (date != null) {
                      cameraProvider.setDateFilter(
                        from: date,
                        to: cameraProvider.toDate,
                      );
                    }
                  },
                  child: Text(
                    cameraProvider.fromDate == null
                        ? 'From Date'
                        : 'From ${cameraProvider.fromDate!.day}/${cameraProvider.fromDate!.month}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: cameraProvider.toDate ?? DateTime.now(),
                    );
                    if (date != null) {
                      cameraProvider.setDateFilter(
                        from: cameraProvider.fromDate,
                        to: date,
                      );
                    }
                  },
                  child: Text(
                    cameraProvider.toDate == null
                        ? 'To Date'
                        : 'To ${cameraProvider.toDate!.day}/${cameraProvider.toDate!.month}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

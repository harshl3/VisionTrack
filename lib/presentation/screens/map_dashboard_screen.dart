import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'role_selection_screen.dart';
import 'camera_registration_screen.dart';

class MapDashboardScreen extends StatefulWidget {
  const MapDashboardScreen({super.key});

  @override
  State<MapDashboardScreen> createState() => _MapDashboardScreenState();
}

class _MapDashboardScreenState extends State<MapDashboardScreen> {
  GoogleMapController? mapController;
  final LatLng _center = const LatLng(28.6139, 77.2090); // Default Delhi
  
  Set<Marker> _markers = {};
  bool _emergencyMode = false;

  @override
  void initState() {
    super.initState();
    _loadDemoMarkers();
  }

  void _loadDemoMarkers() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('cam_1'),
          position: const LatLng(28.6139, 77.2090),
          infoWindow: const InfoWindow(title: 'Govt Camera - Active'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          onTap: () => _showCameraDetails('cam_1', 'Government Camera', 'Active'),
        )
      );
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _handleMapTap(LatLng location) {
    if (Provider.of<AuthProvider>(context, listen: false).role == 'SURVEY') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tapped at ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}. Drop camera here?')),
      );
    }
  }

  void _showCameraDetails(String id, String title, String status) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
              const SizedBox(height: 8),
              Text('Status: $status', style: const TextStyle(color: AppColors.successGreen, fontSize: 16)),
              const SizedBox(height: 16),
              const Text('Coverage Range: 50m\nDirection: North\nType: Street Facing', style: TextStyle(color: AppColors.textGrey, height: 1.5)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.videocam),
                label: const Text('View Live Feed (Simulation)'),
              ),
            ],
          ),
        );
      }
    );
  }

  void _toggleEmergency() {
    setState(() {
      _emergencyMode = !_emergencyMode;
      if (_emergencyMode) {
        mapController?.animateCamera(CameraUpdate.zoomTo(14));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('EMERGENCY MODE ACTIVATED! Locating nearest cameras...'), backgroundColor: AppColors.dangerRed),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency Mode Deactivated.'), backgroundColor: AppColors.textGrey),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_emergencyMode ? 'EMERGENCY OVERRIDE' : 'Live Surveillance Map'),
        backgroundColor: _emergencyMode ? AppColors.dangerRed : AppColors.primaryNavy,
        actions: [
          if (authProvider.role == 'SURVEY' || authProvider.role == 'POLICE')
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              tooltip: 'Register Camera',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CameraRegistrationScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              authProvider.logout();
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
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers,
            onTap: _handleMapTap,
            myLocationEnabled: true,
          ),
          if (_emergencyMode)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.dangerRed, width: 4),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 24,
            child: FloatingActionButton.extended(
              onPressed: _toggleEmergency,
              backgroundColor: _emergencyMode ? AppColors.textWhite : AppColors.dangerRed,
              icon: Icon(Icons.warning, color: _emergencyMode ? AppColors.dangerRed : Colors.white),
              label: Text(_emergencyMode ? 'CANCEL EMERGENCY' : 'EMERGENCY', style: TextStyle(color: _emergencyMode ? AppColors.dangerRed : Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/camera_provider.dart';
import '../widgets/glass_container.dart';

class CameraRegistrationScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final bool isEmbeddedTab;

  const CameraRegistrationScreen({
    super.key,
    this.onSuccess,
    this.isEmbeddedTab = false,
  });

  @override
  State<CameraRegistrationScreen> createState() =>
      _CameraRegistrationScreenState();
}

class _CameraRegistrationScreenState extends State<CameraRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerNameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _cameraNameCtrl = TextEditingController();
  final _cameraTypeCtrl = TextEditingController(text: 'STATIC');
  final _rangeCtrl = TextEditingController();
  final _azimuthCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  bool _isSaving = false;
  bool _isFetchingLocation = false;

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _contactCtrl.dispose();
    _cameraNameCtrl.dispose();
    _cameraTypeCtrl.dispose();
    _rangeCtrl.dispose();
    _azimuthCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentCoordinates() async {
    setState(() => _isFetchingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Location services are disabled on device.', isError: true);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage('Location permission denied.', isError: true);
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Location permission permanently denied. Enable in device settings.',
          isError: true,
        );
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      } catch (e) {
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          rethrow;
        }
      }

      _latCtrl.text = position.latitude.toStringAsFixed(6);
      _lngCtrl.text = position.longitude.toStringAsFixed(6);
      _showMessage('GPS Coordinates captured successfully!');
    } catch (e) {
      _showMessage('Failed to fetch location: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _saveCamera() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = Provider.of<CameraProvider>(context, listen: false);

    final success = await provider.addCamera({
      'owner_name': _ownerNameCtrl.text.trim(),
      'contact_number': _contactCtrl.text.trim(),
      'camera_name': _cameraNameCtrl.text.trim(),
      'camera_type': _cameraTypeCtrl.text.trim(),
      'latitude': double.parse(_latCtrl.text.trim()),
      'longitude': double.parse(_lngCtrl.text.trim()),
      'azimuth_angle': double.parse(_azimuthCtrl.text.trim()),
      'camera_range': double.parse(_rangeCtrl.text.trim()),
    });

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      _showMessage('Camera registered successfully into database.');
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
      if (!widget.isEmbeddedTab && Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        _resetForm();
      }
    } else {
      _showMessage(provider.error ?? 'Failed to save camera hardware.', isError: true);
    }
  }

  void _resetForm() {
    _ownerNameCtrl.clear();
    _contactCtrl.clear();
    _cameraNameCtrl.clear();
    _cameraTypeCtrl.text = 'STATIC';
    _rangeCtrl.clear();
    _azimuthCtrl.clear();
    _latCtrl.clear();
    _lngCtrl.clear();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppColors.dangerRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formBody = Container(
      decoration: const BoxDecoration(
        gradient: AppColors.darkGradient,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (widget.isEmbeddedTab) ...[
                const Text(
                  'Register Camera Hardware',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Add new CCTV stream parameters to GIS coverage network',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
                const SizedBox(height: 20),
              ],

              // Section 1: Owner Information
              GlassContainer(
                borderRadius: 20,
                blur: 14,
                padding: const EdgeInsets.all(20),
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                borderColor: AppColors.accentBlue.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(Icons.person, 'Owner Information'),
                    const SizedBox(height: 16),
                    GlassTextField(
                      controller: _ownerNameCtrl,
                      hintText: 'Full Owner Name *',
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Owner name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    GlassTextField(
                      controller: _contactCtrl,
                      hintText: 'Contact Phone Number *',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Contact number is required'
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 2: Camera Hardware Parameters
              GlassContainer(
                borderRadius: 20,
                blur: 14,
                padding: const EdgeInsets.all(20),
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                borderColor: AppColors.accentBlue.withValues(alpha: 0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(Icons.videocam, 'Hardware Specs & Orientation'),
                    const SizedBox(height: 16),
                    GlassTextField(
                      controller: _cameraNameCtrl,
                      hintText: 'Camera Identifier (e.g. Gate 1 Cam)',
                      prefixIcon: Icons.camera_alt_outlined,
                    ),
                    const SizedBox(height: 14),
                    GlassTextField(
                      controller: _cameraTypeCtrl,
                      hintText: 'Camera Type (STATIC, PTZ, DOME)',
                      prefixIcon: Icons.devices_other_outlined,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: GlassTextField(
                            controller: _rangeCtrl,
                            hintText: 'Range (meters) *',
                            prefixIcon: Icons.radar,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassTextField(
                            controller: _azimuthCtrl,
                            hintText: 'Azimuth (0-360°) *',
                            prefixIcon: Icons.compass_calibration,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final val = double.tryParse(v);
                              if (val == null || val < 0 || val > 360) return '0-360°';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section 3: GIS Location Coordinates
              GlassContainer(
                borderRadius: 20,
                blur: 14,
                padding: const EdgeInsets.all(20),
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                borderColor: AppColors.govtCamera.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(Icons.my_location, 'GIS GPS Coordinates'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GlassTextField(
                            controller: _latCtrl,
                            hintText: 'Latitude *',
                            prefixIcon: Icons.location_on_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassTextField(
                            controller: _lngCtrl,
                            hintText: 'Longitude *',
                            prefixIcon: Icons.explore_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.govtCamera,
                          side: const BorderSide(color: AppColors.govtCamera, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isFetchingLocation ? null : _fetchCurrentCoordinates,
                        icon: _isFetchingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.govtCamera,
                                ),
                              )
                            : const Icon(Icons.gps_fixed),
                        label: const Text(
                          'AUTO-FETCH CURRENT GPS LOCATION',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentBlue,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: AppColors.accentBlue.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveCamera,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_outlined),
                            SizedBox(width: 8),
                            Text(
                              'REGISTER CAMERA HARDWARE',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );

    if (widget.isEmbeddedTab) {
      return formBody;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Register Camera',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.glassBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: formBody,
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentBlue, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
      ],
    );
  }
}

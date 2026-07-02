import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../providers/camera_provider.dart';

class CameraRegistrationScreen extends StatefulWidget {
  const CameraRegistrationScreen({super.key});

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
        _showMessage('Location services are disabled.', isError: true);
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
          'Location permission permanently denied. Enable it in settings.',
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
      _showMessage('Coordinates fetched successfully.');
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
      _showMessage('Camera registered successfully.');
      Navigator.pop(context, true);
    } else {
      _showMessage(provider.error ?? 'Failed to save camera.', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.dangerRed : AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Camera')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle('Camera Owner Information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ownerNameCtrl,
              decoration: const InputDecoration(labelText: 'Owner Name *'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Owner name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactCtrl,
              decoration: const InputDecoration(labelText: 'Contact Number *'),
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Contact number is required'
                  : null,
            ),
            const SizedBox(height: 28),
            _sectionTitle('Camera Information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cameraNameCtrl,
              decoration: const InputDecoration(labelText: 'Camera Name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cameraTypeCtrl,
              decoration: const InputDecoration(
                labelText: 'Camera Type',
                hintText: 'STATIC, PTZ, DOME...',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _rangeCtrl,
              decoration: const InputDecoration(
                labelText: 'Camera Range (meters) *',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Range is required';
                if (double.tryParse(v) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _azimuthCtrl,
              decoration: const InputDecoration(
                labelText: 'Azimuth Angle (degrees) *',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Azimuth angle is required';
                final value = double.tryParse(v);
                if (value == null) return 'Enter a valid number';
                if (value < 0 || value > 360)
                  return 'Azimuth must be between 0 and 360';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latCtrl,
                    decoration: const InputDecoration(labelText: 'Latitude *'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Latitude is required';
                      if (double.tryParse(v) == null) return 'Invalid latitude';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lngCtrl,
                    decoration: const InputDecoration(labelText: 'Longitude *'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Longitude is required';
                      if (double.tryParse(v) == null)
                        return 'Invalid longitude';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _isFetchingLocation ? null : _fetchCurrentCoordinates,
              icon: _isFetchingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Fetch Current Coordinates'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
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
                  : const Text('Save Camera'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textWhite,
      ),
    );
  }
}

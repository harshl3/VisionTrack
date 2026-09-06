import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import 'map_location_picker_screen.dart';

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

enum _LocationMethod { manual, gps, map }

class _CameraRegistrationScreenState extends State<CameraRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serialCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _cameraNameCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _rangeCtrl = TextEditingController();
  final _azimuthCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _cameraType = 'STATIC';
  DateTime? _installationDate;
  _LocationMethod _locationMethod = _LocationMethod.gps;
  bool _isSaving = false;
  bool _isFetchingLocation = false;

  static const List<String> _cameraTypes = [
    'STATIC',
    'PTZ',
    'DOME',
    'BULLET',
    'FISHEYE',
    'GOVERNMENT',
    'PRIVATE',
  ];

  @override
  void dispose() {
    _serialCtrl.dispose();
    _ownerNameCtrl.dispose();
    _contactCtrl.dispose();
    _cameraNameCtrl.dispose();
    _brandCtrl.dispose();
    _rangeCtrl.dispose();
    _azimuthCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, {bool isError = false, bool isWarning = false}) {
    if (!mounted) return;
    Color bgColor;
    IconData icon;
    if (isError) {
      bgColor = const Color(0xFFEF4444);
      icon = Icons.error_outline;
    } else if (isWarning) {
      bgColor = const Color(0xFFF59E0B);
      icon = Icons.warning_amber_outlined;
    } else {
      bgColor = const Color(0xFF10B981);
      icon = Icons.check_circle_outline;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _fetchCurrentCoordinates() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackbar('Location services are disabled. Please enable GPS.', isWarning: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackbar('Location permission denied.', isError: true);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnackbar('Location permission permanently denied. Enable it in settings.', isError: true);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _latCtrl.text = pos.latitude.toStringAsFixed(7);
        _lngCtrl.text = pos.longitude.toStringAsFixed(7);
      });
      _showSnackbar('Current GPS coordinates fetched successfully!');
    } catch (e) {
      _showSnackbar('Failed to fetch location: $e', isError: true);
    } finally {
      setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _pickLocationFromMap() async {
    LatLng? initial;
    if (_latCtrl.text.isNotEmpty && _lngCtrl.text.isNotEmpty) {
      final lat = double.tryParse(_latCtrl.text);
      final lng = double.tryParse(_lngCtrl.text);
      if (lat != null && lng != null) initial = LatLng(lat, lng);
    }

    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(initialLocation: initial),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latCtrl.text = result.latitude.toStringAsFixed(7);
        _lngCtrl.text = result.longitude.toStringAsFixed(7);
      });
      _showSnackbar('Location picked from map!');
    }
  }

  Future<void> _pickInstallationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _installationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _installationDate = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    final azimuth = double.tryParse(_azimuthCtrl.text.trim());
    final range = double.tryParse(_rangeCtrl.text.trim());

    if (lat == null || lng == null) {
      _showSnackbar('Please provide valid latitude and longitude.', isError: true);
      return;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      _showSnackbar('Coordinates out of valid range.', isError: true);
      return;
    }
    if (azimuth == null || azimuth < 0 || azimuth > 360) {
      _showSnackbar('Azimuth angle must be between 0° and 360°.', isError: true);
      return;
    }
    if (range == null || range <= 0) {
      _showSnackbar('Camera range must be a positive number.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'owner_name': _ownerNameCtrl.text.trim(),
      'contact_number': _contactCtrl.text.trim(),
      'camera_name': _cameraNameCtrl.text.trim().isNotEmpty
          ? _cameraNameCtrl.text.trim()
          : _ownerNameCtrl.text.trim(),
      'camera_type': _cameraType,
      'latitude': lat,
      'longitude': lng,
      'azimuth_angle': azimuth,
      'camera_range': range,
    };

    if (_serialCtrl.text.trim().isNotEmpty) {
      payload['serial_number'] = _serialCtrl.text.trim();
    }
    if (_brandCtrl.text.trim().isNotEmpty) {
      payload['camera_brand'] = _brandCtrl.text.trim();
    }
    if (_installationDate != null) {
      payload['installation_date'] =
          _installationDate!.toIso8601String().split('T').first;
    }
    if (_notesCtrl.text.trim().isNotEmpty) {
      payload['notes'] = _notesCtrl.text.trim();
    }

    final provider = Provider.of<CameraProvider>(context, listen: false);
    final success = await provider.addCamera(payload);

    setState(() => _isSaving = false);

    if (success) {
      _showSnackbar('Camera registered successfully!');
      _resetForm();
      widget.onSuccess?.call();
    } else {
      final error = provider.error ?? 'Failed to register camera';
      // Extract message from Exception format
      final msg = error.replaceAll('Exception: ', '');
      _showSnackbar(msg, isError: true);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _serialCtrl.clear();
    _ownerNameCtrl.clear();
    _contactCtrl.clear();
    _cameraNameCtrl.clear();
    _brandCtrl.clear();
    _rangeCtrl.clear();
    _azimuthCtrl.clear();
    _latCtrl.clear();
    _lngCtrl.clear();
    _notesCtrl.clear();
    setState(() {
      _cameraType = 'STATIC';
      _installationDate = null;
      _locationMethod = _LocationMethod.gps;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark
        ? const Color(0xFF070B19)
        : const Color(0xFFF0F4F8);

    return Container(
      color: bg,
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              // ── Header ──────────────────────────────────────────
              _SectionHeader(
                icon: Icons.videocam_outlined,
                title: 'Register New Camera',
                subtitle: 'All required fields must be filled',
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // ── SECTION 1: Identification ────────────────────────
              _FormSection(
                title: 'Camera Identification',
                isDark: isDark,
                children: [
                  _FormField(
                    controller: _serialCtrl,
                    label: 'Serial Number *',
                    hint: 'e.g. CAM-2024-00123',
                    icon: Icons.qr_code,
                    isDark: isDark,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Serial number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _FormField(
                    controller: _cameraNameCtrl,
                    label: 'Camera Name / Label',
                    hint: 'e.g. Main Gate Cam 1',
                    icon: Icons.label_outline,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _FormField(
                    controller: _brandCtrl,
                    label: 'Brand / Make',
                    hint: 'e.g. Hikvision, Dahua, CP Plus',
                    icon: Icons.business_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  // Camera Type Dropdown
                  _DropdownField(
                    value: _cameraType,
                    items: _cameraTypes,
                    label: 'Camera Type',
                    icon: Icons.category_outlined,
                    isDark: isDark,
                    onChanged: (v) => setState(() => _cameraType = v ?? 'STATIC'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── SECTION 2: Owner Info ────────────────────────────
              _FormSection(
                title: 'Owner Information',
                isDark: isDark,
                children: [
                  _FormField(
                    controller: _ownerNameCtrl,
                    label: 'Owner Name *',
                    hint: 'Full name of camera owner',
                    icon: Icons.person_outline,
                    isDark: isDark,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Owner name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  _FormField(
                    controller: _contactCtrl,
                    label: 'Contact Number *',
                    hint: 'e.g. +91 98765 43210',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    isDark: isDark,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Contact number is required' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── SECTION 3: Location ──────────────────────────────
              _FormSection(
                title: 'Camera Location',
                isDark: isDark,
                children: [
                  // 3-option location method picker
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        _LocationMethodBtn(
                          label: 'Manual',
                          icon: Icons.edit_outlined,
                          selected: _locationMethod == _LocationMethod.manual,
                          isDark: isDark,
                          onTap: () =>
                              setState(() => _locationMethod = _LocationMethod.manual),
                        ),
                        _LocationMethodBtn(
                          label: 'GPS Auto',
                          icon: Icons.gps_fixed,
                          selected: _locationMethod == _LocationMethod.gps,
                          isDark: isDark,
                          onTap: () {
                            setState(() => _locationMethod = _LocationMethod.gps);
                            _fetchCurrentCoordinates();
                          },
                        ),
                        _LocationMethodBtn(
                          label: 'Pick Map',
                          icon: Icons.map_outlined,
                          selected: _locationMethod == _LocationMethod.map,
                          isDark: isDark,
                          onTap: () {
                            setState(() => _locationMethod = _LocationMethod.map);
                            _pickLocationFromMap();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_locationMethod == _LocationMethod.gps && _isFetchingLocation)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Fetching GPS coordinates...',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _FormField(
                          controller: _latCtrl,
                          label: 'Latitude *',
                          hint: '28.6139',
                          icon: Icons.south_america_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          isDark: isDark,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final d = double.tryParse(v.trim());
                            if (d == null) return 'Invalid';
                            if (d < -90 || d > 90) return 'Range: -90 to 90';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FormField(
                          controller: _lngCtrl,
                          label: 'Longitude *',
                          hint: '77.2090',
                          icon: Icons.east_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          isDark: isDark,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final d = double.tryParse(v.trim());
                            if (d == null) return 'Invalid';
                            if (d < -180 || d > 180) return 'Range: -180 to 180';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── SECTION 4: Technical Specs ───────────────────────
              _FormSection(
                title: 'Technical Specifications',
                isDark: isDark,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _FormField(
                          controller: _azimuthCtrl,
                          label: 'Azimuth Angle (°) *',
                          hint: '0 – 360',
                          icon: Icons.explore_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          isDark: isDark,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final d = double.tryParse(v.trim());
                            if (d == null) return 'Invalid';
                            if (d < 0 || d > 360) return '0-360';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FormField(
                          controller: _rangeCtrl,
                          label: 'Range (meters) *',
                          hint: 'e.g. 50',
                          icon: Icons.radar,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          isDark: isDark,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final d = double.tryParse(v.trim());
                            if (d == null || d <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Installation Date
                  GestureDetector(
                    onTap: _pickInstallationDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _installationDate != null
                                  ? 'Installed: ${_installationDate!.day.toString().padLeft(2, '0')}/'
                                      '${_installationDate!.month.toString().padLeft(2, '0')}/'
                                      '${_installationDate!.year}'
                                  : 'Installation Date (optional)',
                              style: TextStyle(
                                color: _installationDate != null
                                    ? (isDark ? Colors.white : const Color(0xFF1E3A5F))
                                    : (isDark ? Colors.white38 : Colors.grey.shade500),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: isDark ? Colors.white38 : Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── SECTION 5: Notes ─────────────────────────────────
              _FormSection(
                title: 'Additional Notes',
                isDark: isDark,
                children: [
                  _FormField(
                    controller: _notesCtrl,
                    label: 'Notes / Remarks (optional)',
                    hint: 'e.g. Camera covers main entrance and 10m radius...',
                    icon: Icons.notes_outlined,
                    isDark: isDark,
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Submit Button ────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  child: _isSaving
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Registering Camera...',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_outlined, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'REGISTER CAMERA',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable sub-widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E3A5F),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;

  const _FormSection({
    required this.title,
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF1E293B),
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 20),
        labelStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.grey.shade600,
          fontSize: 13,
        ),
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : Colors.grey.shade400,
          fontSize: 13,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFFCBD5E1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFFCBD5E1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final String label;
  final IconData icon;
  final bool isDark;
  final void Function(String?) onChanged;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.label,
    required this.icon,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map((t) => DropdownMenuItem(
                value: t,
                child: Text(
                  t,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 14,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
      dropdownColor: isDark ? const Color(0xFF111827) : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary, size: 20),
        labelStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.grey.shade600,
          fontSize: 13,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFFCBD5E1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFFCBD5E1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
      style: TextStyle(
        color: isDark ? Colors.white : const Color(0xFF1E293B),
      ),
      icon: Icon(
        Icons.expand_more,
        color: isDark ? Colors.white54 : Colors.grey.shade500,
      ),
    );
  }
}

class _LocationMethodBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _LocationMethodBtn({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

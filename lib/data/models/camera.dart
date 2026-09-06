class Camera {
  final int id;
  final String? serialNumber;
  final String ownerName;
  final String contactNumber;
  final String cameraName;
  final String cameraType;
  final String? cameraBrand;
  final double latitude;
  final double longitude;
  final double azimuthAngle;
  final double cameraRange;
  final DateTime? installationDate;
  final String? notes;
  final String status;
  final int? createdBy;
  final String? surveyorName;
  final DateTime createdAt;

  const Camera({
    required this.id,
    this.serialNumber,
    required this.ownerName,
    required this.contactNumber,
    required this.cameraName,
    required this.cameraType,
    this.cameraBrand,
    required this.latitude,
    required this.longitude,
    required this.azimuthAngle,
    required this.cameraRange,
    this.installationDate,
    this.notes,
    required this.status,
    this.createdBy,
    this.surveyorName,
    required this.createdAt,
  });

  factory Camera.fromJson(Map<String, dynamic> json) {
    return Camera(
      id: json['id'] as int,
      serialNumber: json['serial_number'] as String?,
      ownerName: (json['owner_name'] ?? '') as String,
      contactNumber: (json['contact_number'] ?? json['contact_details'] ?? '') as String,
      cameraName: (json['camera_name'] ?? json['owner_name'] ?? 'Camera') as String,
      cameraType: (json['camera_type'] ?? json['type'] ?? 'STATIC') as String,
      cameraBrand: json['camera_brand'] as String?,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      azimuthAngle: _toDouble(json['azimuth_angle'] ?? json['direction']),
      cameraRange: _toDouble(json['camera_range'] ?? json['coverage_range']),
      installationDate: json['installation_date'] != null
          ? DateTime.tryParse(json['installation_date'].toString())
          : null,
      notes: json['notes'] as String?,
      status: (json['status'] ?? 'ACTIVE') as String,
      createdBy: json['created_by'] as int?,
      surveyorName: json['surveyor_name'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (serialNumber != null) 'serial_number': serialNumber,
      'owner_name': ownerName,
      'contact_number': contactNumber,
      'camera_name': cameraName,
      'camera_type': cameraType,
      if (cameraBrand != null) 'camera_brand': cameraBrand,
      'latitude': latitude,
      'longitude': longitude,
      'azimuth_angle': azimuthAngle,
      'camera_range': cameraRange,
      if (installationDate != null)
        'installation_date': installationDate!.toIso8601String().split('T').first,
      if (notes != null) 'notes': notes,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  bool get isActive => status.toUpperCase() == 'ACTIVE';
}

class SurveyorUser {
  final int id;
  final String name;
  final String email;

  const SurveyorUser({
    required this.id,
    required this.name,
    required this.email,
  });

  factory SurveyorUser.fromJson(Map<String, dynamic> json) {
    return SurveyorUser(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

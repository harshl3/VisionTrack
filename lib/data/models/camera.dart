class Camera {
  final int id;
  final String ownerName;
  final String contactNumber;
  final String cameraName;
  final String cameraType;
  final double latitude;
  final double longitude;
  final double azimuthAngle;
  final double cameraRange;
  final String status;
  final int? createdBy;
  final String? surveyorName;
  final DateTime createdAt;

  const Camera({
    required this.id,
    required this.ownerName,
    required this.contactNumber,
    required this.cameraName,
    required this.cameraType,
    required this.latitude,
    required this.longitude,
    required this.azimuthAngle,
    required this.cameraRange,
    required this.status,
    this.createdBy,
    this.surveyorName,
    required this.createdAt,
  });

  factory Camera.fromJson(Map<String, dynamic> json) {
    return Camera(
      id: json['id'] as int,
      ownerName: (json['owner_name'] ?? '') as String,
      contactNumber: (json['contact_number'] ?? json['contact_details'] ?? '') as String,
      cameraName: (json['camera_name'] ?? json['owner_name'] ?? 'Camera') as String,
      cameraType: (json['camera_type'] ?? json['type'] ?? 'STATIC') as String,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      azimuthAngle: _toDouble(json['azimuth_angle'] ?? json['direction']),
      cameraRange: _toDouble(json['camera_range'] ?? json['coverage_range']),
      status: (json['status'] ?? 'ACTIVE') as String,
      createdBy: json['created_by'] as int?,
      surveyorName: json['surveyor_name'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner_name': ownerName,
      'contact_number': contactNumber,
      'camera_name': cameraName,
      'camera_type': cameraType,
      'latitude': latitude,
      'longitude': longitude,
      'azimuth_angle': azimuthAngle,
      'camera_range': cameraRange,
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

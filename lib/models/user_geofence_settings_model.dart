import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserGeofenceSettings {
  final String id;
  final String userId;
  final String? adminId;
  final bool enabled;
  final LatLng center;
  final double radius;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserGeofenceSettings({
    required this.id,
    required this.userId,
    this.adminId,
    required this.enabled,
    required this.center,
    required this.radius,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserGeofenceSettings.fromJson(Map<String, dynamic> json) {
    // Handle type conversion for latitude and longitude
    double latitude = 0.0;
    double longitude = 0.0;
    double radius = 500.0;

    // Convert latitude to double
    if (json['latitude'] != null) {
      latitude = json['latitude'] is int
          ? (json['latitude'] as int).toDouble()
          : json['latitude'] as double;
    }

    // Convert longitude to double
    if (json['longitude'] != null) {
      longitude = json['longitude'] is int
          ? (json['longitude'] as int).toDouble()
          : json['longitude'] as double;
    }

    // Convert radius to double
    if (json['radius'] != null) {
      radius = json['radius'] is int
          ? (json['radius'] as int).toDouble()
          : json['radius'] as double;
    }

    return UserGeofenceSettings(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      adminId: json['admin_id'],
      enabled: json['enabled'] ?? false,
      center: LatLng(latitude, longitude),
      radius: radius,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'admin_id': adminId,
      'enabled': enabled,
      'latitude': center.latitude,
      'longitude': center.longitude,
      'radius': radius,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserGeofenceSettings copyWith({
    String? id,
    String? userId,
    String? adminId,
    bool? enabled,
    LatLng? center,
    double? radius,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserGeofenceSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      adminId: adminId ?? this.adminId,
      enabled: enabled ?? this.enabled,
      center: center ?? this.center,
      radius: radius ?? this.radius,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

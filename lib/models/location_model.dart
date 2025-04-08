class LocationModel {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double? altitude;
  final double? speed;
  final DateTime timestamp;

  LocationModel({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude,
    this.speed,
    required this.timestamp,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      accuracy: _parseDouble(json['accuracy']),
      altitude:
          json['altitude'] != null ? _parseDouble(json['altitude']) : null,
      speed: json['speed'] != null ? _parseDouble(json['speed']) : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  // Helper method to parse values that might be int or double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // For inserting into Supabase (without id as it will be generated)
  Map<String, dynamic> toInsertJson(String userId) {
    return {
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

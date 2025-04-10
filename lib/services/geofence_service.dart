import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vibration/vibration.dart';
// Removed fluttertoast import as toast notifications are no longer used
import '../models/user_geofence_settings_model.dart';
import 'supabase_service.dart';

class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();

  factory GeofenceService() {
    return _instance;
  }

  GeofenceService._internal();

  // Geofence properties
  LatLng? _center;
  double _radiusInMeters = 500; // Default radius is 500 meters
  bool _isMonitoring = false;
  Timer? _monitoringTimer;
  String? _userId; // Current user ID for user-specific geofence

  // Callback for when user leaves the geofence
  Function(Position position, double distanceFromCenter)? onGeofenceExit;

  // Callback for when user re-enters the geofence
  Function(Position position)? onGeofenceEnter;

  // Last known state (inside or outside geofence)
  bool _wasInsideGeofence = true;

  // User-specific geofence settings
  UserGeofenceSettings? _userGeofenceSettings;

  // Getters
  LatLng? get center => _center;
  double get radiusInMeters => _radiusInMeters;
  bool get isMonitoring => _isMonitoring;

  // Set up a new geofence
  void setupGeofence({
    required LatLng center,
    double radiusInMeters = 500,
    Function(Position position, double distanceFromCenter)? onExit,
    Function(Position position)? onEnter,
    String? userId,
  }) {
    _center = center;
    _radiusInMeters = radiusInMeters;
    onGeofenceExit = onExit;
    onGeofenceEnter = onEnter;
    _userId = userId;

    debugPrint(
        'Geofence set up at ${center.latitude}, ${center.longitude} with radius ${radiusInMeters}m');
  }

  // Load user-specific geofence settings
  Future<bool> loadUserGeofenceSettings(String userId) async {
    try {
      final settings = await SupabaseService().getUserGeofenceSettings(userId);

      if (settings != null && settings.enabled) {
        _userGeofenceSettings = settings;
        _center = settings.center;
        _radiusInMeters = settings.radius;
        _userId = userId;

        debugPrint(
            'Loaded user geofence settings: ${settings.center.latitude}, ${settings.center.longitude} with radius ${settings.radius}m');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error loading user geofence settings: $e');
      return false;
    }
  }

  // Start monitoring the geofence
  Future<bool> startMonitoring() async {
    if (_center == null) {
      debugPrint('Cannot start monitoring: Geofence center not set');
      return false;
    }

    if (_isMonitoring) {
      debugPrint('Already monitoring geofence');
      return true;
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return false;
      }

      // Check for location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return false;
      }

      // Start monitoring timer (check every 10 seconds)
      _monitoringTimer =
          Timer.periodic(const Duration(seconds: 10), (timer) async {
        await _checkGeofence();
      });

      _isMonitoring = true;
      _wasInsideGeofence = true; // Assume starting inside the geofence

      // Do an immediate check
      await _checkGeofence();

      debugPrint('Geofence monitoring started');
      return true;
    } catch (e) {
      debugPrint('Error starting geofence monitoring: $e');
      return false;
    }
  }

  // Stop monitoring the geofence
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _isMonitoring = false;
    debugPrint('Geofence monitoring stopped');
  }

  // Check if the current location is within the geofence
  Future<void> _checkGeofence() async {
    if (_center == null) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Calculate distance from center
      double distanceInMeters = Geolocator.distanceBetween(_center!.latitude,
          _center!.longitude, position.latitude, position.longitude);

      bool isInsideGeofence = distanceInMeters <= _radiusInMeters;

      // If user was inside but now outside, trigger exit callback
      if (_wasInsideGeofence && !isInsideGeofence) {
        debugPrint(
            'User left geofence. Distance: ${distanceInMeters.toStringAsFixed(2)}m');

        // Vibrate the phone
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 1000);
        }

        // Toast notifications have been removed as requested

        // Call the exit callback if provided
        onGeofenceExit?.call(position, distanceInMeters);
      }
      // If user was outside but now inside, trigger enter callback
      else if (!_wasInsideGeofence && isInsideGeofence) {
        debugPrint('User entered geofence');

        // Toast notifications have been removed as requested

        // Call the enter callback if provided
        onGeofenceEnter?.call(position);
      }

      // Update the state
      _wasInsideGeofence = isInsideGeofence;
    } catch (e) {
      debugPrint('Error checking geofence: $e');
    }
  }

  // Check if a specific position is within the geofence
  bool isPositionInGeofence(Position position) {
    if (_center == null) return false;

    double distanceInMeters = Geolocator.distanceBetween(_center!.latitude,
        _center!.longitude, position.latitude, position.longitude);

    return distanceInMeters <= _radiusInMeters;
  }

  // Get the distance from the geofence center
  double getDistanceFromCenter(Position position) {
    if (_center == null) return double.infinity;

    return Geolocator.distanceBetween(_center!.latitude, _center!.longitude,
        position.latitude, position.longitude);
  }

  // Update the geofence radius
  void updateRadius(double radiusInMeters) {
    _radiusInMeters = radiusInMeters;
    debugPrint('Geofence radius updated to ${radiusInMeters}m');
  }

  // Update the geofence center
  void updateCenter(LatLng center) {
    _center = center;
    debugPrint(
        'Geofence center updated to ${center.latitude}, ${center.longitude}');
  }
}

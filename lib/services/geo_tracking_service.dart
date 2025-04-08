import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'supabase_service.dart';
import 'background_location_service.dart';

class GeoTrackingService {
  static final GeoTrackingService _instance = GeoTrackingService._internal();

  factory GeoTrackingService() {
    return _instance;
  }

  GeoTrackingService._internal();

  bool _isTrackingEnabled = false;
  final SupabaseService _supabaseService = SupabaseService();
  final BackgroundLocationService _backgroundService =
      BackgroundLocationService();

  // Last saved location
  Position? _lastPosition;
  Timer? _foregroundTimer;

  // Initialize geo tracking service
  Future<void> initialize() async {
    // Initialize the background service
    await _backgroundService.initialize();

    // Check if tracking was enabled before
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isTrackingEnabled = prefs.getBool('geo_tracking_enabled') ?? false;

    // If tracking is enabled, start the foreground timer
    if (_isTrackingEnabled) {
      _startForegroundTracking();
    }
  }

  // Start tracking location
  Future<void> startTracking() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(msg: "Location services are disabled");
        return;
      }

      // Check for location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(msg: "Location permissions are denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(
          msg:
              "Location permissions are permanently denied, we cannot request permissions",
        );
        return;
      }

      // Request background location permission if needed
      if (permission == LocationPermission.whileInUse) {
        Fluttertoast.showToast(
          msg:
              "Background location permission is required for tracking when the app is closed",
        );
        permission = await Geolocator.requestPermission();
      }

      // Get initial position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _lastPosition = position;

      // Save initial position to Supabase
      await _supabaseService.saveLocation(position);

      // Start the background service
      bool started = await _backgroundService.startTracking();

      if (started) {
        _isTrackingEnabled = true;

        // Start foreground tracking
        _startForegroundTracking();

        Fluttertoast.showToast(msg: "Geo tracking started");
      } else {
        Fluttertoast.showToast(msg: "Failed to start background tracking");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error starting geo tracking: $e");
    }
  }

  // Start foreground tracking (more frequent updates when app is open)
  void _startForegroundTracking() {
    // Cancel existing timer if any
    _foregroundTimer?.cancel();

    // Create a new timer that fires every minute
    _foregroundTimer =
        Timer.periodic(const Duration(minutes: 1), (timer) async {
      try {
        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          debugPrint('Location services are disabled');
          return;
        }

        // Check for location permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          debugPrint('Location permissions are denied');
          return;
        }

        // Get current position
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        _lastPosition = position;

        // Save to Supabase
        await _supabaseService.saveLocation(position);

        debugPrint(
            'Foreground location saved: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        debugPrint('Error getting location in foreground: $e');
      }
    });
  }

  // Stop tracking location
  Future<void> stopTracking() async {
    try {
      // Stop the background service
      bool stopped = await _backgroundService.stopTracking();

      // Stop foreground tracking
      _foregroundTimer?.cancel();
      _foregroundTimer = null;

      if (stopped) {
        _isTrackingEnabled = false;
        Fluttertoast.showToast(msg: "Geo tracking stopped");
      } else {
        Fluttertoast.showToast(msg: "Failed to stop background tracking");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error stopping geo tracking: $e");
    }
  }

  // Get current location
  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Check if geo tracking is enabled
  bool isGeoTrackingEnabled() {
    return _isTrackingEnabled;
  }

  // Get the last known position
  Position? getLastPosition() {
    return _lastPosition;
  }

  // Check if the background service is running
  Future<bool> isBackgroundServiceRunning() async {
    return await _backgroundService.isTrackingEnabled();
  }
}

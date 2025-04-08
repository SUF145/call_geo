import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class GeoTrackingService {
  static final GeoTrackingService _instance = GeoTrackingService._internal();

  factory GeoTrackingService() {
    return _instance;
  }

  GeoTrackingService._internal();

  bool _isTrackingEnabled = false;
  LocationSettings? _locationSettings;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Initialize geo tracking service
  Future<void> initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isTrackingEnabled = prefs.getBool('geo_tracking_enabled') ?? false;

    if (_isTrackingEnabled) {
      await startTracking();
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

      // Set up location settings
      _locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      // Start listening to location updates
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      ).listen((Position position) {
        _saveLocationData(position);
      });

      _isTrackingEnabled = true;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('geo_tracking_enabled', true);

      Fluttertoast.showToast(msg: "Geo tracking started");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error starting geo tracking: $e");
    }
  }

  // Stop tracking location
  Future<void> stopTracking() async {
    try {
      if (_positionStreamSubscription != null) {
        await _positionStreamSubscription!.cancel();
        _positionStreamSubscription = null;
      }

      _isTrackingEnabled = false;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('geo_tracking_enabled', false);

      Fluttertoast.showToast(msg: "Geo tracking stopped");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error stopping geo tracking: $e");
    }
  }

  // Save location data
  void _saveLocationData(Position position) async {
    // In a real app, you would save this to your database
    // Using debugPrint instead of print for better logging
    debugPrint("Location: ${position.latitude}, ${position.longitude}");
    debugPrint("Accuracy: ${position.accuracy}");
    debugPrint("Altitude: ${position.altitude}");
    debugPrint("Speed: ${position.speed}");
    debugPrint("Time: ${DateTime.now()}");
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
}

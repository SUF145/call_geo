import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'supabase_service.dart';

// Background task names
const String periodicLocationTaskName = 'com.callgeo.periodicLocationTracking';
const String oneOffLocationTaskName = 'com.callgeo.oneOffLocationTracking';

// This is the callback that will be called by Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('Background task executed: $task');

    try {
      // Initialize Supabase
      await SupabaseService.initialize();
      final supabaseService = SupabaseService();

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return Future.value(false);
      }

      // Check for location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are denied');
        return Future.value(false);
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Save to Supabase
      bool saved = await supabaseService.saveLocation(position);

      if (saved) {
        debugPrint(
            'Background location saved: ${position.latitude}, ${position.longitude}');

        // Save last location to shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('last_latitude', position.latitude);
        await prefs.setDouble('last_longitude', position.longitude);
        await prefs.setString(
            'last_location_time', DateTime.now().toIso8601String());

        return Future.value(true);
      } else {
        debugPrint('Failed to save location to Supabase');
        return Future.value(false);
      }
    } catch (e) {
      debugPrint('Error in background task: $e');
      return Future.value(false);
    }
  });
}

class BackgroundLocationService {
  static final BackgroundLocationService _instance =
      BackgroundLocationService._internal();

  factory BackgroundLocationService() {
    return _instance;
  }

  BackgroundLocationService._internal();

  // Initialize the background service
  Future<void> initialize() async {
    try {
      // Initialize Workmanager
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true,
      );

      // Check if tracking was enabled before
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isTrackingEnabled = prefs.getBool('geo_tracking_enabled') ?? false;

      if (isTrackingEnabled) {
        await startTracking();
      }

      debugPrint('Background location service initialized');
    } catch (e) {
      debugPrint('Error initializing background location service: $e');
    }
  }

  // Start tracking
  Future<bool> startTracking() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(msg: "Location services are disabled");
        return false;
      }

      // Check for location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(msg: "Location permissions are denied");
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(
          msg:
              "Location permissions are permanently denied, we cannot request permissions",
        );
        return false;
      }

      // Request background location permission if needed
      if (permission == LocationPermission.whileInUse) {
        Fluttertoast.showToast(
          msg:
              "Background location permission is required for tracking when the app is closed",
        );
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always) {
          return false;
        }
      }

      // Register a periodic task (minimum interval is 15 minutes)
      await Workmanager().registerPeriodicTask(
        periodicLocationTaskName,
        periodicLocationTaskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      // Also register a one-off task to get immediate location
      await Workmanager().registerOneOffTask(
        oneOffLocationTaskName,
        oneOffLocationTaskName,
        initialDelay: const Duration(seconds: 5),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      // Save the state
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('geo_tracking_enabled', true);

      debugPrint('Background location tracking started');
      Fluttertoast.showToast(msg: "Background location tracking started");
      return true;
    } catch (e) {
      debugPrint('Error starting background location tracking: $e');
      Fluttertoast.showToast(msg: "Error starting background tracking: $e");
      return false;
    }
  }

  // Stop tracking
  Future<bool> stopTracking() async {
    try {
      // Cancel all tasks
      await Workmanager().cancelAll();

      // Save the state
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('geo_tracking_enabled', false);

      debugPrint('Background location tracking stopped');
      Fluttertoast.showToast(msg: "Background location tracking stopped");
      return true;
    } catch (e) {
      debugPrint('Error stopping background location tracking: $e');
      Fluttertoast.showToast(msg: "Error stopping background tracking: $e");
      return false;
    }
  }

  // Check if tracking is enabled
  Future<bool> isTrackingEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('geo_tracking_enabled') ?? false;
  }

  // Get last known location from shared preferences
  Future<Map<String, dynamic>?> getLastKnownLocation() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      double? latitude = prefs.getDouble('last_latitude');
      double? longitude = prefs.getDouble('last_longitude');
      String? timestamp = prefs.getString('last_location_time');

      if (latitude != null && longitude != null && timestamp != null) {
        return {
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': timestamp,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting last known location: $e');
      return null;
    }
  }
}

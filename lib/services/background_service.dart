import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'supabase_service.dart';

// Background task name
const String locationTaskName = 'com.callgeo.locationTracking';

class BackgroundLocationService {
  static final BackgroundLocationService _instance =
      BackgroundLocationService._internal();

  factory BackgroundLocationService() {
    return _instance;
  }

  BackgroundLocationService._internal();

  // Initialize the background service
  Future<void> initialize() async {
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
  }

  // Start tracking
  Future<void> startTracking() async {
    try {
      // Register a periodic task
      await Workmanager().registerPeriodicTask(
        locationTaskName,
        locationTaskName,
        frequency: const Duration(minutes: 15), // Minimum allowed is 15 minutes
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      // Save the state
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('geo_tracking_enabled', true);

      debugPrint('Background location tracking started');
      return;
    } catch (e) {
      debugPrint('Error starting background location tracking: $e');
      return;
    }
  }

  // Stop tracking
  Future<void> stopTracking() async {
    try {
      // Cancel the task
      await Workmanager().cancelByUniqueName(locationTaskName);

      // Save the state
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('geo_tracking_enabled', false);

      debugPrint('Background location tracking stopped');
      return;
    } catch (e) {
      debugPrint('Error stopping background location tracking: $e');
      return;
    }
  }

  // Check if tracking is enabled
  Future<bool> isTrackingEnabled() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('geo_tracking_enabled') ?? false;
  }
}

// This is the callback that will be called by Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Initialize Supabase
    await SupabaseService.initialize();
    final supabaseService = SupabaseService();

    try {
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
      await supabaseService.saveLocation(position);

      debugPrint(
          'Background location saved: ${position.latitude}, ${position.longitude}');
      return Future.value(true);
    } catch (e) {
      debugPrint('Error in background task: $e');
      return Future.value(false);
    }
  });
}

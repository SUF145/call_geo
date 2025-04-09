import 'dart:async';
// import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../models/location_model.dart';
import 'supabase_service.dart';

/// Callback function that will be called in the background isolate
@pragma('vm:entry-point')
void locationTrackingCallback() {
  // Initialize communication channel for the background isolate
  const MethodChannel backgroundChannel =
      MethodChannel('com.example.call_geo/location_background');

  // Handle location updates from the native side
  backgroundChannel.setMethodCallHandler((call) async {
    if (call.method == 'onLocationUpdate') {
      try {
        final Map<dynamic, dynamic> locationData = call.arguments;
        debugPrint('Location update received in background: $locationData');

        // Initialize Supabase client
        await _initializeSupabase();

        // Save location to database
        await _saveLocationToDatabase(locationData);
      } catch (e) {
        debugPrint('Error handling location update: $e');
      }
    }
    return null;
  });

  // Signal to the native side that the callback has been initialized
  backgroundChannel.invokeMethod('initialized');
}

// Initialize Supabase client in the background isolate
Future<void> _initializeSupabase() async {
  try {
    // Check if Supabase is already initialized
    try {
      final currentSession = Supabase.instance.client.auth.currentSession;
      if (currentSession != null) {
        debugPrint('Supabase already initialized with active session');
        return;
      }
    } catch (e) {
      // Supabase not initialized yet
      debugPrint('Supabase not initialized: $e');
    }

    // Get stored credentials from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final supabaseUrl = prefs.getString('supabase_url') ?? '';
    final supabaseKey = prefs.getString('supabase_key') ?? '';

    if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
      // Initialize Supabase with the stored credentials
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );

      // Try to restore session from stored refresh token if available
      final refreshToken = prefs.getString('supabase_refresh_token');
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          await Supabase.instance.client.auth.setSession(refreshToken);
          debugPrint('Session restored successfully');
        } catch (e) {
          debugPrint('Error restoring session: $e');
        }
      }
    }
  } catch (e) {
    debugPrint('Error initializing Supabase in background: $e');
  }
}

// Save location to database
Future<void> _saveLocationToDatabase(Map<dynamic, dynamic> locationData) async {
  try {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      debugPrint('No authenticated user found');
      return;
    }

    final location = LocationModel(
      id: '',
      userId: user.id,
      latitude: locationData['latitude'],
      longitude: locationData['longitude'],
      accuracy: locationData['accuracy'] ?? 0.0,
      altitude: locationData['altitude'] ?? 0.0,
      speed: locationData['speed'] ?? 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          (locationData['time'] as int).toInt()),
    );

    await supabase.from('locations').insert(location.toJson());
    debugPrint('Location saved to database');
  } catch (e) {
    debugPrint('Error saving location to database: $e');
  }
}

class LocationTrackingService {
  static const MethodChannel _channel =
      MethodChannel('com.example.call_geo/location');
  // Storage keys for SharedPreferences
  static const String _keyTrackingEnabled = 'tracking_enabled';
  static const String _keyCallbackHandle = 'callback_handle';

  final SupabaseService _supabaseService = SupabaseService();

  // Start location tracking service
  Future<bool> startLocationTracking() async {
    try {
      // Check and request permissions
      if (!await _checkAndRequestPermissions()) {
        debugPrint('Location permissions not granted');
        return false;
      }

      // Store Supabase credentials for background use
      await _storeSupabaseCredentials();

      // Register the callback
      final CallbackHandle? handle =
          PluginUtilities.getCallbackHandle(locationTrackingCallback);
      if (handle == null) {
        debugPrint('Failed to get callback handle');
        return false;
      }

      // Save callback handle to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyTrackingEnabled, true);
      await prefs.setInt(_keyCallbackHandle, handle.toRawHandle());

      // Start the foreground service
      final result = await _channel.invokeMethod<bool>('startLocationService', {
        'callbackHandle': handle.toRawHandle(),
      });

      return result ?? false;
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      return false;
    }
  }

  // Stop location tracking service
  Future<bool> stopLocationTracking() async {
    try {
      // Update shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyTrackingEnabled, false);

      // Stop the foreground service
      final result = await _channel.invokeMethod<bool>('stopLocationService');
      return result ?? false;
    } catch (e) {
      debugPrint('Error stopping location tracking: $e');
      return false;
    }
  }

  // Check if location tracking is enabled
  Future<bool> isLocationTrackingEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyTrackingEnabled) ?? false;
    } catch (e) {
      debugPrint('Error checking if location tracking is enabled: $e');
      return false;
    }
  }

  // Check and request necessary permissions
  Future<bool> _checkAndRequestPermissions() async {
    // Check location permissions
    final locationStatus = await Permission.location.status;
    if (!locationStatus.isGranted) {
      final result = await Permission.location.request();
      if (!result.isGranted) {
        return false;
      }
    }

    // Check background location permission on Android 10+
    if (await _isAndroid10OrHigher()) {
      final backgroundStatus = await Permission.locationAlways.status;
      if (!backgroundStatus.isGranted) {
        final result = await Permission.locationAlways.request();
        if (!result.isGranted) {
          return false;
        }
      }
    }

    // Check notification permission on Android 13+
    if (await _isAndroid13OrHigher()) {
      final notificationStatus = await Permission.notification.status;
      if (!notificationStatus.isGranted) {
        final result = await Permission.notification.request();
        if (!result.isGranted) {
          return false;
        }
      }
    }

    return true;
  }

  // Check if device is running Android 10 or higher
  Future<bool> _isAndroid10OrHigher() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt >= 29;
  }

  // Check if device is running Android 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt >= 33;
  }

  // Store Supabase credentials for background use
  Future<void> _storeSupabaseCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Store Supabase URL and key
      // We need to hardcode these values since we can't access them directly from the client
      final supabaseUrl = const String.fromEnvironment('SUPABASE_URL',
          defaultValue: 'https://ixpwcfkbmwxnwfkgwsqn.supabase.co');
      final supabaseKey = const String.fromEnvironment('SUPABASE_KEY',
          defaultValue:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4cHdjZmtibXd4bndma2d3c3FuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTI2NTI1NzcsImV4cCI6MjAyODIyODU3N30.Rl5Vy-5gu-hF5UBOIgPT_Q4RFIhsA3XTxNXHPPELGHM');

      await prefs.setString('supabase_url', supabaseUrl);
      await prefs.setString('supabase_key', supabaseKey);

      // Store current session refresh token if available
      final session = _supabaseService.supabase.auth.currentSession;
      if (session != null && session.refreshToken != null) {
        await prefs.setString('supabase_refresh_token', session.refreshToken!);
      }
    } catch (e) {
      debugPrint('Error storing Supabase credentials: $e');
    }
  }
}

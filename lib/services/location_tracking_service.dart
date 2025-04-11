import 'dart:async';
// import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:uuid/uuid.dart';
import 'firebase_messaging_service_new.dart';
import 'firebase_cloud_messaging_v1.dart';

import '../models/location_model.dart';
import '../models/user_geofence_settings_model.dart';
import 'supabase_service.dart';

// Store the last time we showed a geofence alert to avoid spamming
DateTime? _lastGeofenceAlertTime;

/// Callback function that will be called in the background isolate
@pragma('vm:entry-point')
void locationTrackingCallback() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase client first
  try {
    await _initializeSupabase();
    debugPrint('Supabase initialized in background isolate');
  } catch (e) {
    debugPrint('Error initializing Supabase in background isolate: $e');
  }

  // Initialize communication channel for the background isolate
  const MethodChannel backgroundChannel =
      MethodChannel('com.example.call_geo/location_background');

  // Handle location updates from the native side
  backgroundChannel.setMethodCallHandler((call) async {
    if (call.method == 'onLocationUpdate') {
      try {
        final Map<dynamic, dynamic> locationData = call.arguments;
        debugPrint('Location update received in background: $locationData');

        // Create a Position object from the location data
        final Position position = Position(
          latitude: locationData['latitude'] as double,
          longitude: locationData['longitude'] as double,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
              (locationData['time'] as int).toInt()),
          accuracy: locationData['accuracy'] as double,
          altitude: locationData['altitude'] as double,
          heading: 0.0,
          speed: locationData['speed'] as double,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );

        // Save location to database
        await _saveLocationToDatabase(locationData);

        // Check if user is within geofence
        await _checkGeofence(position);
      } catch (e) {
        debugPrint('Error handling location update: $e');
      }
    }
    return null;
  });

  // We don't need to signal back to native side as it's causing an exception
  // backgroundChannel.invokeMethod('initialized');
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

    // Generate a UUID for the location
    final uuid = Uuid();
    final locationId = uuid.v4();

    final location = LocationModel(
      id: locationId, // Use the generated UUID
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

// Check if the user is within their geofence
Future<void> _checkGeofence(Position position) async {
  try {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      debugPrint('No authenticated user found for geofence check');
      return;
    }

    debugPrint('Checking geofence for user ${user.id}');

    // Load user's geofence settings
    final response = await supabase
        .from('user_geofence_settings')
        .select()
        .eq('user_id', user.id)
        .eq('enabled', true)
        .maybeSingle();

    if (response == null) {
      debugPrint('No geofence settings found for user ${user.id}');
      return;
    }

    // Parse geofence settings
    final settings = UserGeofenceSettings.fromJson(response);
    debugPrint(
        'Found geofence settings for user ${user.id}: ${settings.center.latitude}, ${settings.center.longitude}, radius: ${settings.radius}, enabled: ${settings.enabled}');

    if (!settings.enabled) {
      debugPrint('Geofence is disabled for user ${user.id}');
      return;
    }

    // Calculate distance from geofence center
    final double distanceInMeters = Geolocator.distanceBetween(
      settings.center.latitude,
      settings.center.longitude,
      position.latitude,
      position.longitude,
    );

    final bool isInsideGeofence = distanceInMeters <= settings.radius;
    debugPrint(
        'User is ${isInsideGeofence ? "inside" : "outside"} geofence. Distance: ${distanceInMeters.toStringAsFixed(2)}m');

    // If user is outside geofence, show alert
    if (!isInsideGeofence) {
      // Check if we should show an alert (only once per minute)
      final now = DateTime.now();
      if (_lastGeofenceAlertTime == null ||
          now.difference(_lastGeofenceAlertTime!).inMinutes >= 1) {
        _lastGeofenceAlertTime = now;
        debugPrint('Showing geofence alert - user is outside allowed area');

        // Get the admin who created this user's geofence
        final SupabaseService supabaseService = SupabaseService();
        final adminUser = await supabaseService.getCreatorAdmin(user.id);

        debugPrint('Admin user details: ${adminUser?.toJson()}');

        // Get user's name for the admin notification
        final userData = await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .single();

        final String userName = userData['full_name'] ?? 'User';

        // Check if the current user is the admin or the user who left the geofence
        final currentUser = supabase.auth.currentUser;
        final bool isCurrentUserAdmin = adminUser != null &&
            currentUser != null &&
            currentUser.id == adminUser.id;
        final bool isCurrentUserTheUser =
            currentUser != null && currentUser.id == user.id;

        debugPrint('Current user ID: ${currentUser?.id}');
        debugPrint('User who left geofence: ${user.id}');
        debugPrint('Admin ID: ${adminUser?.id}');
        debugPrint('Is current user admin? $isCurrentUserAdmin');
        debugPrint(
            'Is current user the one who left geofence? $isCurrentUserTheUser');

        // Show appropriate notification based on who is logged in
        if (isCurrentUserTheUser) {
          // Show notification to the user who left the geofence
          debugPrint('Showing notification to the user who left the geofence');
          await _showGeofenceAlert(distanceInMeters,
              isForAdmin: false, userName: null, userId: null);
        } else if (isCurrentUserAdmin) {
          // Show notification to the admin
          debugPrint('Showing notification to the admin about user ${user.id}');
          await _showGeofenceAlert(distanceInMeters,
              isForAdmin: true, userName: userName, userId: user.id);
        } else {
          debugPrint(
              'Current user is neither the admin nor the user who left the geofence');
        }

        // Also send a notification to the admin's device (this will only show if the admin is logged in on another device)
        if (adminUser != null && !isCurrentUserAdmin) {
          debugPrint(
              'Sending notification to admin device for ${adminUser.id}');

          try {
            debugPrint('Admin user ID: ${adminUser.id}');
            debugPrint('Admin email: ${adminUser.email}');
            debugPrint('Admin role: ${adminUser.role}');

            // Initialize Firebase if needed
            try {
              await Firebase.initializeApp();
              debugPrint(
                  'Firebase initialized successfully in location service');
            } catch (e) {
              debugPrint('Error initializing Firebase: $e');
              // Continue anyway, as Firebase might already be initialized
            }

            // Create the admin notification message
            final String title = "User Outside Geofence Alert";
            final String message =
                "$userName is outside their allowed area! They are approximately ${distanceInMeters.toStringAsFixed(0)} meters from the boundary.";

            // Use Firebase Messaging Service to send a notification to the admin's device
            final FirebaseMessagingService firebaseMessagingService =
                FirebaseMessagingService();
            await firebaseMessagingService.initialize();

            // Get the admin's device token directly from the database
            try {
              // Get the admin's device token using a direct query
              final adminTokens = await supabaseService.supabase
                  .from('device_tokens')
                  .select()
                  .eq('user_id', adminUser.id);

              debugPrint('Admin token query response: $adminTokens');

              if (adminTokens.isEmpty) {
                debugPrint('No device tokens found for admin: ${adminUser.id}');

                // Try to get all tokens to see what's in the database
                final allTokens = await supabaseService.supabase
                    .from('device_tokens')
                    .select();
                debugPrint('All tokens in the table: $allTokens');
                debugPrint('Total tokens in the table: ${allTokens.length}');

                // Try to send the notification anyway
                final bool success =
                    await firebaseMessagingService.sendNotificationToUser(
                  adminUser.id,
                  title,
                  message,
                  isAdminNotification: true,
                  targetUserId: user.id,
                );

                if (success) {
                  debugPrint(
                      'Cross-device notification sent to admin ${adminUser.id}');
                } else {
                  debugPrint(
                      'Failed to send cross-device notification to admin ${adminUser.id}');
                }
              } else {
                // We have the admin's token, send the notification directly using FCM V1 API
                final List<String> tokens = adminTokens
                    .map<String>((data) => data['token'] as String)
                    .toList();
                debugPrint(
                    'Found ${tokens.length} tokens for admin ${adminUser.id}: $tokens');

                // Use the Firebase Cloud Messaging V1 API directly
                final FirebaseCloudMessagingV1 fcmV1 =
                    FirebaseCloudMessagingV1();

                // Send to each token individually
                bool anySuccess = false;
                for (final token in tokens) {
                  debugPrint('Sending direct notification to token: $token');
                  final bool tokenSuccess = await fcmV1.sendNotificationToToken(
                    token,
                    title,
                    message,
                    {
                      'is_admin_notification': 'true',
                      'user_id': user.id,
                    },
                  );

                  if (tokenSuccess) {
                    anySuccess = true;
                    debugPrint(
                        'Successfully sent notification to token: $token');
                  } else {
                    debugPrint('Failed to send notification to token: $token');
                  }
                }

                if (anySuccess) {
                  debugPrint(
                      'Cross-device notification sent to admin ${adminUser.id}');
                } else {
                  debugPrint(
                      'Failed to send cross-device notification to admin ${adminUser.id}');
                }
              }
            } catch (e) {
              debugPrint('Error sending notification to admin: $e');
            }
          } catch (e) {
            debugPrint('Error sending cross-device notification: $e');
          }
        }
      } else {
        debugPrint('Skipping geofence alert - already shown recently');
      }
    }
  } catch (e) {
    debugPrint('Error checking geofence: $e');
  }
}

// Show alert when user is outside geofence
Future<void> _showGeofenceAlert(
  double distanceFromCenter, {
  bool isForAdmin = false,
  String? userName,
  String? userId,
}) async {
  try {
    // Vibrate the device
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 1000);
    }

    // Prepare the message based on whether this is for admin or user
    String message;
    String title;

    if (isForAdmin && userName != null) {
      // Admin notification
      title = "User Outside Geofence Alert";
      message =
          "$userName is outside their allowed area! They are approximately ${distanceFromCenter.toStringAsFixed(0)} meters from the boundary.";
      debugPrint('Showing ADMIN notification for user $userName ($userId)');
    } else {
      // User notification
      title = "Geofence Alert";
      message =
          "You are outside the allowed area! Please return immediately. You are approximately ${distanceFromCenter.toStringAsFixed(0)} meters from the boundary.";
      debugPrint('Showing USER notification');
    }

    // Send a notification using the platform channel
    const MethodChannel backgroundChannel =
        MethodChannel('com.example.call_geo/location_background');

    try {
      // Log the notification parameters
      debugPrint('Sending notification with parameters:');
      debugPrint('  - distance: $distanceFromCenter');
      debugPrint('  - message: $message');
      debugPrint('  - title: $title');
      debugPrint('  - is_admin_notification: $isForAdmin');
      debugPrint('  - user_id: $userId');

      // Create a map of parameters, ensuring userId is only included for admin notifications
      final Map<String, dynamic> params = {
        'distance': distanceFromCenter,
        'message': message,
        'title': title,
        'is_admin_notification': isForAdmin,
      };

      // Only include userId for admin notifications
      if (isForAdmin && userId != null) {
        params['user_id'] = userId;
      }

      // Invoke the method to show the notification
      final result =
          await backgroundChannel.invokeMethod('showGeofenceAlert', params);

      debugPrint('Notification result: $result');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  } catch (e) {
    debugPrint('Error showing geofence alert: $e');
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
          defaultValue: 'https://gwipwoxbulgdfjgirtle.supabase.co');
      final supabaseKey = const String.fromEnvironment('SUPABASE_KEY',
          defaultValue:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3aXB3b3hidWxnZGZqZ2lydGxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQwOTc0ODksImV4cCI6MjA1OTY3MzQ4OX0.a-r2-tqe8f9KHEkD_2yn2Uo3hYz2LdimjprI6nU_7gE');

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

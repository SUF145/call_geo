import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'supabase_service.dart';

// The callback function should always be a top-level function
@pragma('vm:entry-point')
void startLocationTracking() {
  // Set up the task handler
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

// Location task handler
class LocationTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  Timer? _timer;

  // Initialize Supabase
  Future<void> _initializeSupabase() async {
    try {
      await SupabaseService.initialize();
      debugPrint('Supabase initialized in background service');
    } catch (e) {
      debugPrint('Error initializing Supabase in background service: $e');
    }
  }

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    debugPrint('Background location service started');

    // Initialize Supabase
    await _initializeSupabase();

    // Start periodic location updates
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _getCurrentLocationAndSave();
    });

    // Get initial location
    await _getCurrentLocationAndSave();
  }

  Future<void> _getCurrentLocationAndSave() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _sendPort?.send('Location services are disabled');
        debugPrint('Location services are disabled');
        return;
      }

      // Check for location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _sendPort?.send('Location permissions are denied');
        debugPrint('Location permissions are denied');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Save to Supabase
      final supabaseService = SupabaseService();
      bool saved = await supabaseService.saveLocation(position);

      if (saved) {
        // Send data to the main isolate
        _sendPort?.send({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
        });

        debugPrint(
            'Background location saved: ${position.latitude}, ${position.longitude}');
      } else {
        debugPrint('Failed to save location to Supabase');
      }
    } catch (e) {
      _sendPort?.send('Error getting location: $e');
      debugPrint('Error getting location in background service: $e');
    }
  }

  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Handle events if needed
    debugPrint('Background service event received');
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Cancel timer when the service is destroyed
    _timer?.cancel();
    _sendPort?.send('Location tracking stopped');
    debugPrint('Background location service destroyed');
  }

  void onButtonPressed(String id) {
    // Handle button press events if needed
    debugPrint('Button pressed in notification: $id');
    if (id == 'stopService') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // This method is required by the TaskHandler interface
    // It's called periodically based on the interval set in ForegroundTaskOptions
    debugPrint('Repeat event in background service');
    await _getCurrentLocationAndSave();
  }
}

// Foreground location service
class ForegroundLocationService {
  static final ForegroundLocationService _instance =
      ForegroundLocationService._internal();

  factory ForegroundLocationService() {
    return _instance;
  }

  ForegroundLocationService._internal();

  // Initialize the foreground task
  Future<void> initialize() async {
    // Configure the task first
    await _configureTask();

    // Check if tracking was enabled before
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTrackingEnabled = prefs.getBool('geo_tracking_enabled') ?? false;

    if (isTrackingEnabled) {
      await startLocationTracking();
    }
  }

  // Start location tracking
  Future<bool> startLocationTracking() async {
    try {
      // Check for location permissions first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          Fluttertoast.showToast(
              msg: "Location permissions are required for background tracking");
          return false;
        }
      }

      // Check if background location permission is granted
      if (permission != LocationPermission.always) {
        Fluttertoast.showToast(
            msg: "Background location permission is required");
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always) {
          return false;
        }
      }

      // Check if the service is already running
      if (await FlutterForegroundTask.isRunningService) {
        debugPrint('Foreground service is already running');
        return true;
      }

      // Configure the foreground task again to ensure it's properly set up
      await _configureTask();

      // Request notification permissions if needed
      await FlutterForegroundTask.requestNotificationPermission();

      // Start the foreground service
      debugPrint('Starting foreground service...');
      bool success = await FlutterForegroundTask.startService(
        notificationTitle: 'Location Tracking',
        notificationText: 'Tracking your location in the background',
        callback: startLocationTracking,
      );

      debugPrint('Foreground service start result: $success');

      if (success) {
        // Save the state
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('geo_tracking_enabled', true);
        Fluttertoast.showToast(msg: "Background tracking started");
      } else {
        Fluttertoast.showToast(msg: "Failed to start background tracking");
      }

      return success;
    } catch (e) {
      debugPrint('Error starting foreground service: $e');
      Fluttertoast.showToast(msg: "Error starting background tracking: $e");
      return false;
    }
  }

  // Stop location tracking
  Future<bool> stopLocationTracking() async {
    try {
      // Check if the service is running
      if (!await FlutterForegroundTask.isRunningService) {
        debugPrint('Foreground service is not running');
        return true;
      }

      // Stop the foreground service
      debugPrint('Stopping foreground service...');
      bool success = await FlutterForegroundTask.stopService();

      debugPrint('Foreground service stop result: $success');

      if (success) {
        // Save the state
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('geo_tracking_enabled', false);
        Fluttertoast.showToast(msg: "Background tracking stopped");
      } else {
        Fluttertoast.showToast(msg: "Failed to stop background tracking");
      }

      return success;
    } catch (e) {
      debugPrint('Error stopping foreground service: $e');
      Fluttertoast.showToast(msg: "Error stopping background tracking: $e");
      return false;
    }
  }

  // Check if location tracking is enabled
  Future<bool> isLocationTrackingEnabled() async {
    try {
      bool isRunning = await FlutterForegroundTask.isRunningService;
      debugPrint('Foreground service running status: $isRunning');
      return isRunning;
    } catch (e) {
      debugPrint('Error checking if foreground service is running: $e');
      return false;
    }
  }

  // Configure the foreground task
  Future<void> _configureTask() async {
    try {
      // Android notification settings
      final AndroidNotificationOptions androidNotificationOptions =
          AndroidNotificationOptions(
        channelId: 'location_tracking_channel',
        channelName: 'Location Tracking',
        channelDescription:
            'This channel is used for location tracking notifications',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
        iconData: NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          NotificationButton(id: 'stopService', text: 'Stop Tracking'),
        ],
      );

      // iOS notification settings
      final IOSNotificationOptions iosNotificationOptions =
          IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      );

      // Foreground task options
      final ForegroundTaskOptions foregroundTaskOptions = ForegroundTaskOptions(
        interval: 60000, // 1 minute in milliseconds
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      );

      // Configure the foreground task
      FlutterForegroundTask.init(
        androidNotificationOptions: androidNotificationOptions,
        iosNotificationOptions: iosNotificationOptions,
        foregroundTaskOptions: foregroundTaskOptions,
      );

      debugPrint('Foreground task configured successfully');
    } catch (e) {
      debugPrint('Error configuring foreground task: $e');
    }
  }
}

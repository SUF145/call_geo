import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

/// A service to detect location spoofing on Android devices.
/// This service interfaces with native Android code to detect various
/// forms of location spoofing.
class LocationSpoofingService {
  static const MethodChannel _channel =
      MethodChannel('com.example.call_geo/enhanced_location');

  /// Singleton instance
  static final LocationSpoofingService _instance = LocationSpoofingService._internal();

  /// Factory constructor to return the singleton instance
  factory LocationSpoofingService() {
    return _instance;
  }

  /// Private constructor for singleton pattern
  LocationSpoofingService._internal();

  /// Starts the enhanced location tracking service with spoofing detection.
  /// 
  /// Returns true if the service was started successfully.
  Future<bool> startEnhancedLocationTracking() async {
    try {
      final bool result = await _channel.invokeMethod('startEnhancedLocationTracking');
      debugPrint('Enhanced location tracking started: $result');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error starting enhanced location tracking: ${e.message}');
      return false;
    }
  }

  /// Stops the enhanced location tracking service.
  /// 
  /// Returns true if the service was stopped successfully.
  Future<bool> stopEnhancedLocationTracking() async {
    try {
      final bool result = await _channel.invokeMethod('stopEnhancedLocationTracking');
      debugPrint('Enhanced location tracking stopped: $result');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error stopping enhanced location tracking: ${e.message}');
      return false;
    }
  }

  /// Checks if the enhanced location tracking service is running.
  /// 
  /// Returns true if the service is running.
  Future<bool> isEnhancedLocationTrackingRunning() async {
    try {
      final bool result = await _channel.invokeMethod('isEnhancedLocationTrackingRunning');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error checking if enhanced location tracking is running: ${e.message}');
      return false;
    }
  }

  /// Performs a one-time check for location spoofing.
  /// 
  /// This checks if mock location is enabled in developer settings
  /// and if any known spoofing apps are installed.
  /// 
  /// Returns a map with the results of the checks.
  Future<Map<String, dynamic>> checkLocationSpoofing() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('checkLocationSpoofing');
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      debugPrint('Error checking location spoofing: ${e.message}');
      return {
        'error': e.message,
        'mockLocationEnabled': false,
        'spoofingAppsInstalled': false,
      };
    }
  }

  /// Shows an alert dialog if location spoofing is detected.
  /// 
  /// This is a convenience method to show a user-friendly alert
  /// when spoofing is detected.
  Future<void> showSpoofingAlertIfDetected(BuildContext context) async {
    final spoofingCheck = await checkLocationSpoofing();
    
    final bool mockLocationEnabled = spoofingCheck['mockLocationEnabled'] ?? false;
    final bool spoofingAppsInstalled = spoofingCheck['spoofingAppsInstalled'] ?? false;
    
    if (mockLocationEnabled || spoofingAppsInstalled) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Location Spoofing Detected'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'We\'ve detected that your device may be using fake location data.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (mockLocationEnabled)
                    const Text('• Mock location is enabled in developer settings'),
                  if (spoofingAppsInstalled)
                    const Text('• Location spoofing apps are installed on your device'),
                  const SizedBox(height: 16),
                  const Text(
                    'Please disable mock locations and remove any location spoofing apps to continue using location features.',
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }
}

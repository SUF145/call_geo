import 'package:flutter/material.dart';
import '../services/location_spoofing_service.dart';
import '../theme/app_theme.dart';

/// A demo screen to showcase the location spoofing detection features.
class LocationSpoofingDemoScreen extends StatefulWidget {
  const LocationSpoofingDemoScreen({super.key});

  @override
  State<LocationSpoofingDemoScreen> createState() =>
      _LocationSpoofingDemoScreenState();
}

class _LocationSpoofingDemoScreenState
    extends State<LocationSpoofingDemoScreen> {
  final LocationSpoofingService _spoofingService = LocationSpoofingService();
  bool _isLoading = false;
  bool _isTrackingEnabled = false;
  Map<String, dynamic>? _spoofingCheckResult;

  @override
  void initState() {
    super.initState();
    _checkTrackingStatus();
    _checkForSpoofing();
  }

  /// Check if enhanced location tracking is running
  Future<void> _checkTrackingStatus() async {
    final isEnabled =
        await _spoofingService.isEnhancedLocationTrackingRunning();
    setState(() {
      _isTrackingEnabled = isEnabled;
    });
  }

  /// Perform a one-time check for location spoofing
  Future<void> _checkForSpoofing() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _spoofingService.checkLocationSpoofing();
      setState(() {
        _spoofingCheckResult = result;
        _isLoading = false;
      });

      // Show alert if spoofing is detected
      if (result['mockLocationEnabled'] == true ||
          result['spoofingAppsInstalled'] == true) {
        if (mounted) {
          _spoofingService.showSpoofingAlertIfDetected(context);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _spoofingCheckResult = {'error': e.toString()};
      });
    }
  }

  /// Toggle enhanced location tracking
  Future<void> _toggleTracking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool success;
      if (_isTrackingEnabled) {
        success = await _spoofingService.stopEnhancedLocationTracking();
      } else {
        success = await _spoofingService.startEnhancedLocationTracking();
      }

      if (success) {
        setState(() {
          _isTrackingEnabled = !_isTrackingEnabled;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Spoofing Detection'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Enhanced tracking service card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Enhanced Location Tracking',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Status: ${_isTrackingEnabled ? 'Running' : 'Stopped'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isTrackingEnabled
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Enhanced tracking includes continuous spoofing detection, speed anomaly detection, and cross-verification with network location.',
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _toggleTracking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isTrackingEnabled
                                  ? Colors.red
                                  : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              _isTrackingEnabled
                                  ? 'Stop Enhanced Tracking'
                                  : 'Start Enhanced Tracking',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Information card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'About Location Spoofing Detection',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'This feature detects attempts to fake your location using:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('• Mock location developer settings'),
                          Text('• Location spoofing apps'),
                          Text('• Unrealistic movement speeds'),
                          Text('• Mismatches between GPS and network location'),
                          SizedBox(height: 16),
                          Text(
                            'When spoofing is detected, the location will be marked as potentially spoofed in our database.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Build a status row with an icon indicating the status
  Widget _buildStatusRow(String label, bool value) {
    return Row(
      children: [
        Icon(
          value ? Icons.error : Icons.check_circle,
          color: value ? Colors.red : Colors.green,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ${value ? 'Yes' : 'No'}',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: value ? Colors.red : null,
          ),
        ),
      ],
    );
  }

  /// Check if any form of spoofing is detected
  bool _isSpoofingDetected() {
    if (_spoofingCheckResult == null) return false;

    return (_spoofingCheckResult!['mockLocationEnabled'] == true) ||
        (_spoofingCheckResult!['spoofingAppsInstalled'] == true);
  }
}

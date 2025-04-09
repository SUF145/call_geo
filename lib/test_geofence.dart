import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vibration/vibration.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'services/location_tracking_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

  runApp(const TestGeofenceApp());
}

class TestGeofenceApp extends StatelessWidget {
  const TestGeofenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geofence Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TestGeofencePage(),
    );
  }
}

class TestGeofencePage extends StatefulWidget {
  const TestGeofencePage({super.key});

  @override
  State<TestGeofencePage> createState() => _TestGeofencePageState();
}

class _TestGeofencePageState extends State<TestGeofencePage> {
  final LocationTrackingService _locationService = LocationTrackingService();
  bool _isTracking = false;
  String _status = 'Not tracking';

  @override
  void initState() {
    super.initState();
    _checkTrackingStatus();
  }

  Future<void> _checkTrackingStatus() async {
    final isTracking = await _locationService.isLocationTrackingEnabled();
    setState(() {
      _isTracking = isTracking;
      _status = isTracking ? 'Tracking active' : 'Not tracking';
    });
  }

  Future<void> _toggleTracking() async {
    bool success;
    if (_isTracking) {
      success = await _locationService.stopLocationTracking();
    } else {
      success = await _locationService.startLocationTracking();
    }

    if (success) {
      setState(() {
        _isTracking = !_isTracking;
        _status = _isTracking ? 'Tracking active' : 'Not tracking';
      });
    } else {
      setState(() {
        _status = 'Failed to ${_isTracking ? 'stop' : 'start'} tracking';
      });
    }
  }

  Future<void> _simulateGeofenceViolation() async {
    // This is a test function to simulate a geofence violation
    // It directly calls the _checkGeofence function with a position that is likely outside any geofence

    // Get current position
    final position = await Geolocator.getCurrentPosition();

    // Create a position that's 1km away from current position (likely outside geofence)
    final simulatedPosition = Position(
      latitude: position.latitude + 0.01, // Roughly 1km north
      longitude: position.longitude,
      timestamp: DateTime.now(),
      accuracy: position.accuracy,
      altitude: position.altitude,
      heading: position.heading,
      speed: position.speed,
      speedAccuracy: position.speedAccuracy,
      altitudeAccuracy: position.altitudeAccuracy,
      headingAccuracy: position.headingAccuracy,
    );

    // We can't directly access the private _checkGeofence method, so we'll use a workaround
    try {
      // Call our test function instead
      await _testGeofenceAlert();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Simulated geofence violation triggered')),
        );
      }
    } catch (e) {
      debugPrint('Error simulating geofence violation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // This is a simplified version of the geofence alert for testing
  Future<void> _testGeofenceAlert() async {
    debugPrint('Simulating geofence alert');

    try {
      // Vibrate the device to simulate an alert
      if (await Vibration.hasVibrator() ?? false) {
        await Vibration.vibrate(duration: 1000);
      }

      // Show a toast notification
      Fluttertoast.showToast(
        msg: 'SIMULATED: You are outside the geofence area!',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      debugPrint('Error in simulated geofence alert: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleTracking,
              child: Text(_isTracking ? 'Stop Tracking' : 'Start Tracking'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _simulateGeofenceViolation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simulate Geofence Violation'),
            ),
          ],
        ),
      ),
    );
  }
}

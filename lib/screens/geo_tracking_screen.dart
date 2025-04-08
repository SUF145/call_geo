import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/geo_tracking_service.dart';
import 'location_history_screen.dart';
import 'geofence_screen.dart';

class GeoTrackingScreen extends StatefulWidget {
  const GeoTrackingScreen({super.key});

  @override
  State<GeoTrackingScreen> createState() => GeoTrackingScreenState();
}

class GeoTrackingScreenState extends State<GeoTrackingScreen> {
  final GeoTrackingService _geoTrackingService = GeoTrackingService();

  bool _hasLocationPermission = false;
  bool _isTrackingEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _checkTrackingStatus();
  }

  Future<void> _checkTrackingStatus() async {
    _isTrackingEnabled = _geoTrackingService.isGeoTrackingEnabled();

    // Also check if the background service is actually running
    bool isServiceRunning =
        await _geoTrackingService.isBackgroundServiceRunning();

    if (_isTrackingEnabled != isServiceRunning) {
      setState(() {
        _isTrackingEnabled = isServiceRunning;
      });
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    // Check location permission using Geolocator
    LocationPermission permission = await Geolocator.checkPermission();
    bool hasPermission = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    setState(() {
      _hasLocationPermission = hasPermission;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geo Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await _checkTrackingStatus();
              await _checkPermissions();
              setState(() {
                _isLoading = false;
              });
            },
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _hasLocationPermission
                  ? _buildTrackingControls()
                  : _buildPermissionsRequest(),
            ),
    );
  }

  Widget _buildPermissionsRequest() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.location_off,
          size: 80,
          color: Colors.red,
        ),
        const SizedBox(height: 24),
        const Text(
          'Location Permission Required',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'To use geo tracking, you need to grant location permission.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () async {
            // Request location permission using Geolocator
            LocationPermission permission =
                await Geolocator.requestPermission();

            if (permission == LocationPermission.whileInUse ||
                permission == LocationPermission.always) {
              // Try to request background permission if needed
              if (permission == LocationPermission.whileInUse) {
                await Geolocator.requestPermission();
              }
            }

            await _checkPermissions();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text(
            'Grant Location Permission',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          _isTrackingEnabled ? Icons.location_on : Icons.location_on_outlined,
          size: 80,
          color: _isTrackingEnabled ? Colors.green : Colors.grey,
        ),
        const SizedBox(height: 24),
        Text(
          _isTrackingEnabled ? 'Tracking Active' : 'Tracking Inactive',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _isTrackingEnabled ? Colors.green : Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          _isTrackingEnabled
              ? 'Your location is being tracked in the background every 15 minutes. This will continue even when the app is closed or killed.'
              : 'Start tracking to monitor your location in the background.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 32),
        FutureBuilder<bool>(
          future: _geoTrackingService.isBackgroundServiceRunning(),
          builder: (context, snapshot) {
            final bool isServiceRunning = snapshot.data ?? false;

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isServiceRunning ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Background Service: ${isServiceRunning ? "Running" : "Stopped"}',
                  style: TextStyle(
                    color: isServiceRunning ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () async {
            setState(() {
              _isLoading = true;
            });

            if (_isTrackingEnabled) {
              await _geoTrackingService.stopTracking();
            } else {
              // Check for background location permission
              LocationPermission permission =
                  await Geolocator.checkPermission();
              bool hasBackgroundPermission =
                  permission == LocationPermission.always;

              if (!hasBackgroundPermission) {
                if (mounted) {
                  _showBackgroundLocationDialog();
                }
                setState(() {
                  _isLoading = false;
                });
                return;
              }

              await _geoTrackingService.startTracking();
            }

            // Check the actual status after operation
            await _checkTrackingStatus();

            setState(() {
              _isLoading = false;
            });
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: _isTrackingEnabled ? Colors.red : Colors.green,
          ),
          child: Text(
            _isTrackingEnabled ? 'Stop Tracking' : 'Start Tracking',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 4,
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'About Geo Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This feature tracks your location in the background and saves it for later viewing. It will continue to work even when the app is closed.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Location History Button
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LocationHistoryScreen(),
              ),
            );
          },
          icon: const Icon(Icons.history),
          label: const Text('Location History'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 0),
          ),
        ),

        const SizedBox(height: 16),

        // Geofence Button
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const GeofenceScreen(),
              ),
            );
          },
          icon: const Icon(Icons.fence),
          label: const Text('Geofence Settings'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            minimumSize: const Size(double.infinity, 0),
            backgroundColor: Colors.orange,
          ),
        ),
      ],
    );
  }

  void _showBackgroundLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background Location Required'),
        content: const Text(
          'To track your location in the background, you need to grant "Allow all the time" permission for location.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.requestPermission();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }
}

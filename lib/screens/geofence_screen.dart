import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/geofence_service.dart';
import 'dart:async';

class GeofenceScreen extends StatefulWidget {
  const GeofenceScreen({super.key});

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
  final GeofenceService _geofenceService = GeofenceService();
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _radiusController = TextEditingController(text: '500');
  
  bool _isLoading = true;
  bool _isGeofenceEnabled = false;
  bool _isEditingGeofence = false;
  double _geofenceRadius = 500; // Default radius in meters
  LatLng? _geofenceCenter;
  
  // Map circles for geofence visualization
  final Set<Circle> _circles = {};
  
  // Default camera position (will be updated with current location)
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(0, 0),
    zoom: 14,
  );
  
  @override
  void initState() {
    super.initState();
    _loadGeofenceSettings();
  }
  
  // Load saved geofence settings
  Future<void> _loadGeofenceSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current location for initial camera position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      _initialCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 14,
      );
      
      // Load saved geofence settings
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isEnabled = prefs.getBool('geofence_enabled') ?? false;
      double? lat = prefs.getDouble('geofence_lat');
      double? lng = prefs.getDouble('geofence_lng');
      double radius = prefs.getDouble('geofence_radius') ?? 500;
      
      if (lat != null && lng != null) {
        _geofenceCenter = LatLng(lat, lng);
        _geofenceRadius = radius;
        _radiusController.text = radius.toString();
        
        // Update the circle visualization
        _updateGeofenceCircle();
        
        // If geofence was enabled, restart monitoring
        if (isEnabled) {
          _geofenceService.setupGeofence(
            center: _geofenceCenter!,
            radiusInMeters: _geofenceRadius,
            onExit: _handleGeofenceExit,
            onEnter: _handleGeofenceEnter,
          );
          
          bool success = await _geofenceService.startMonitoring();
          setState(() {
            _isGeofenceEnabled = success;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading geofence settings: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Save geofence settings
  Future<void> _saveGeofenceSettings() async {
    if (_geofenceCenter == null) return;
    
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('geofence_enabled', _isGeofenceEnabled);
      await prefs.setDouble('geofence_lat', _geofenceCenter!.latitude);
      await prefs.setDouble('geofence_lng', _geofenceCenter!.longitude);
      await prefs.setDouble('geofence_radius', _geofenceRadius);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geofence settings saved'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error saving geofence settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save geofence settings'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Set up geofence at the specified location
  void _setupGeofence(LatLng center) {
    // Show dialog to set radius
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Restricted Area'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Tap on the map to set the center of the restricted area.'),
            const SizedBox(height: 16),
            TextField(
              controller: _radiusController,
              decoration: const InputDecoration(
                labelText: 'Radius (meters)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isEditingGeofence = false;
              });
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              setState(() {
                _geofenceCenter = center;
                _isEditingGeofence = false;
              });

              // Update the radius from the text controller
              try {
                _geofenceRadius = double.parse(_radiusController.text);
              } catch (e) {
                _geofenceRadius = 500; // Default to 500m if parsing fails
                _radiusController.text = '500';
              }

              // Continue with setting up the geofence
              _continueGeofenceSetup(center);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  // Continue setting up the geofence after dialog
  void _continueGeofenceSetup(LatLng center) {
    // Add a circle to visualize the geofence
    _updateGeofenceCircle();

    // Set up the geofence service
    _geofenceService.setupGeofence(
      center: center,
      radiusInMeters: _geofenceRadius,
      onExit: _handleGeofenceExit,
      onEnter: _handleGeofenceEnter,
    );

    // Save the settings
    _saveGeofenceSettings();
  }

  // Update the geofence circle visualization
  void _updateGeofenceCircle() {
    if (_geofenceCenter == null) return;
    
    setState(() {
      _circles.clear();
      _circles.add(
        Circle(
          circleId: const CircleId('geofence'),
          center: _geofenceCenter!,
          radius: _geofenceRadius,
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ),
      );
    });
  }

  // Handle when user exits the geofence
  void _handleGeofenceExit(Position position, double distanceFromCenter) {
    // Show a dialog to alert the user
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Warning!'),
          content: Text(
            'You have left the restricted area! You are ${distanceFromCenter.toStringAsFixed(0)} meters away from the center.'
          ),
          backgroundColor: Colors.red[100],
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // Handle when user re-enters the geofence
  void _handleGeofenceEnter(Position position) {
    // Show a snackbar to inform the user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are back in the allowed area'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Toggle geofence editing mode
  void _toggleGeofenceEditing() {
    setState(() {
      _isEditingGeofence = !_isEditingGeofence;
    });
    
    if (_isEditingGeofence) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tap on the map to set the geofence center'),
        ),
      );
    }
  }

  // Toggle geofence monitoring
  Future<void> _toggleGeofenceMonitoring() async {
    if (_geofenceCenter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a geofence area first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_isGeofenceEnabled) {
      // Stop monitoring
      _geofenceService.stopMonitoring();
      setState(() {
        _isGeofenceEnabled = false;
      });
      
      // Save the settings
      await _saveGeofenceSettings();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geofence monitoring stopped'),
        ),
      );
    } else {
      // Start monitoring
      bool success = await _geofenceService.startMonitoring();
      setState(() {
        _isGeofenceEnabled = success;
      });
      
      // Save the settings
      await _saveGeofenceSettings();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geofence monitoring started'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start geofence monitoring'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Settings'),
        actions: [
          // Save button
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveGeofenceSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _initialCameraPosition,
                  circles: _circles,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  compassEnabled: true,
                  mapToolbarEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                  onTap: _isEditingGeofence
                      ? (LatLng position) {
                          _setupGeofence(position);
                        }
                      : null,
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      if (_geofenceCenter != null)
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Geofence Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Center: ${_geofenceCenter!.latitude.toStringAsFixed(6)}, ${_geofenceCenter!.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Radius: ${_geofenceRadius.toStringAsFixed(0)} meters',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: ${_isGeofenceEnabled ? 'Active' : 'Inactive'}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _isGeofenceEnabled ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _toggleGeofenceEditing,
                              icon: Icon(_isEditingGeofence ? Icons.cancel : Icons.edit_location),
                              label: Text(_isEditingGeofence ? 'Cancel' : 'Set Geofence'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: _isEditingGeofence ? Colors.red : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _toggleGeofenceMonitoring,
                              icon: Icon(_isGeofenceEnabled ? Icons.location_off : Icons.location_on),
                              label: Text(_isGeofenceEnabled ? 'Disable' : 'Enable'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: _isGeofenceEnabled ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  
  @override
  void dispose() {
    _radiusController.dispose();
    super.dispose();
  }
}

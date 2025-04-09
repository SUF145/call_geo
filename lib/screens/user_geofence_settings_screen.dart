import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../models/user_geofence_settings_model.dart';
import '../services/supabase_service.dart';

class UserGeofenceSettingsScreen extends StatefulWidget {
  final UserModel user;
  final String adminId;
  final UserGeofenceSettings? initialSettings;

  const UserGeofenceSettingsScreen({
    Key? key,
    required this.user,
    required this.adminId,
    this.initialSettings,
  }) : super(key: key);

  @override
  State<UserGeofenceSettingsScreen> createState() =>
      _UserGeofenceSettingsScreenState();
}

class _UserGeofenceSettingsScreenState
    extends State<UserGeofenceSettingsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  GoogleMapController? _mapController;
  final TextEditingController _radiusController =
      TextEditingController(text: '500');

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

  @override
  void dispose() {
    _radiusController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // Move camera to a specific position
  Future<void> _moveCameraToPosition(LatLng position) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(position, 15),
      );
    }
  }

  // Load saved geofence settings
  Future<void> _loadGeofenceSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current location for initial camera position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      _initialCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 14,
      );

      // First check if we have initialSettings from the constructor
      if (widget.initialSettings != null) {
        debugPrint(
            'Loading initial settings: ${widget.initialSettings!.center.latitude}, ${widget.initialSettings!.center.longitude}, radius: ${widget.initialSettings!.radius}, enabled: ${widget.initialSettings!.enabled}');
        _geofenceCenter = widget.initialSettings!.center;
        _geofenceRadius = widget.initialSettings!.radius;
        _isGeofenceEnabled = widget.initialSettings!.enabled;
        _radiusController.text = _geofenceRadius.toString();

        // Update the circle visualization
        _updateGeofenceCircle();

        // Move camera to geofence center when map is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _moveCameraToPosition(_geofenceCenter!);
          }
        });
      } else {
        // If no initialSettings, try to fetch the latest settings from the database
        debugPrint(
            'No initial settings, fetching from database for user: ${widget.user.id}');
        final latestSettings =
            await _supabaseService.getUserGeofenceSettings(widget.user.id);
        if (latestSettings != null) {
          debugPrint(
              'Found settings in database: ${latestSettings.center.latitude}, ${latestSettings.center.longitude}, radius: ${latestSettings.radius}, enabled: ${latestSettings.enabled}');
          _geofenceCenter = latestSettings.center;
          _geofenceRadius = latestSettings.radius;
          _isGeofenceEnabled = latestSettings.enabled;
          _radiusController.text = _geofenceRadius.toString();

          // Update the circle visualization
          _updateGeofenceCircle();

          // Move camera to geofence center when map is ready
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _moveCameraToPosition(_geofenceCenter!);
            }
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
  Future<bool> _saveGeofenceSettings() async {
    if (_geofenceCenter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a geofence area first'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save geofence settings for this user
      final success = await _supabaseService.saveUserGeofenceSettings(
        userId: widget.user.id,
        adminId: widget.adminId,
        enabled: _isGeofenceEnabled,
        center: _geofenceCenter!,
        radius: _geofenceRadius,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Geofence settings saved'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Return true to indicate success
        setState(() {
          _isLoading = false;
        });
        return true;
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save geofence settings'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving geofence settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
    return false;
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Parse the radius value
              final radius = double.tryParse(_radiusController.text);
              if (radius != null && radius > 0) {
                setState(() {
                  _geofenceRadius = radius;
                  _geofenceCenter = center;
                  _isEditingGeofence = false;
                });
                Navigator.of(context).pop();
                _continueGeofenceSetup(center);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid radius'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  // Continue setting up the geofence after dialog
  Future<void> _continueGeofenceSetup(LatLng center) async {
    // Add a circle to visualize the geofence
    _updateGeofenceCircle();

    // Move camera to center on the geofence
    await _moveCameraToPosition(center);

    // Save the settings
    final success = await _saveGeofenceSettings();
    if (success) {
      // Pop with result to refresh the parent screen
      // if (mounted) {
      //   Navigator.of(context).pop(true);
      // }
    }
  }

  // Update the geofence circle visualization
  void _updateGeofenceCircle() {
    setState(() {
      _circles.clear();

      // Only add the circle if geofence is enabled and center is set
      if (_geofenceCenter != null && _isGeofenceEnabled) {
        _circles.add(
          Circle(
            circleId: const CircleId('geofence'),
            center: _geofenceCenter!,
            radius: _geofenceRadius,
            fillColor: Colors.blue.withAlpha(51), // 0.2 opacity = 51/255
            strokeColor: Colors.blue,
            strokeWidth: 2,
          ),
        );
      }
    });
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

    final bool newEnabledState = !_isGeofenceEnabled;

    setState(() {
      _isGeofenceEnabled = newEnabledState;
    });

    // Update the circle visualization to show/hide based on new state
    _updateGeofenceCircle();

    // Save the settings
    final success = await _saveGeofenceSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newEnabledState
              ? 'Geofence monitoring enabled for ${widget.user.fullName}'
              : 'Geofence monitoring disabled for ${widget.user.fullName}'),
          backgroundColor: newEnabledState ? Colors.green : Colors.orange,
        ),
      );

      if (success) {
        // Pop with result to refresh the parent screen
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          // Only navigate if we haven't already popped
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Geofence Settings for ${widget.user.fullName}'),
          actions: [
            if (_geofenceCenter != null)
              IconButton(
                icon: Icon(_isGeofenceEnabled
                    ? Icons.location_on
                    : Icons.location_off),
                onPressed: _toggleGeofenceMonitoring,
                tooltip:
                    _isGeofenceEnabled ? 'Disable Geofence' : 'Enable Geofence',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: _initialCameraPosition,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    circles: _circles,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onTap: _isEditingGeofence ? _setupGeofence : null,
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Geofence Settings for ${widget.user.fullName}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _geofenceCenter == null
                                  ? 'No geofence set'
                                  : 'Geofence radius: ${_geofenceRadius.toStringAsFixed(0)} meters',
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isEditingGeofence = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Tap on the map to set geofence center'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.edit_location),
                                  label: const Text('Set Geofence'),
                                ),
                                if (_geofenceCenter != null)
                                  ElevatedButton.icon(
                                    onPressed: _toggleGeofenceMonitoring,
                                    icon: Icon(_isGeofenceEnabled
                                        ? Icons.location_off
                                        : Icons.location_on),
                                    label: Text(_isGeofenceEnabled
                                        ? 'Disable'
                                        : 'Enable'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isGeofenceEnabled
                                          ? Colors.orange
                                          : Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/geo_tracking_service.dart';
import '../services/supabase_service.dart';
import '../theme/space_theme.dart';
import '../widgets/space_background.dart';
import '../widgets/cosmic_button.dart';
import '../widgets/cosmic_card.dart';
import 'location_history_screen.dart';

class UserLocationScreen extends StatefulWidget {
  const UserLocationScreen({super.key});

  @override
  State<UserLocationScreen> createState() => _UserLocationScreenState();
}

class _UserLocationScreenState extends State<UserLocationScreen> {
  final GeoTrackingService _geoTrackingService = GeoTrackingService();
  final SupabaseService _supabaseService = SupabaseService();
  
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isTrackingEnabled = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _checkTrackingStatus();
    _getCurrentLocation();
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
  
  Future<void> _checkTrackingStatus() async {
    _isTrackingEnabled = _geoTrackingService.isGeoTrackingEnabled();
    
    // Also check if the background service is actually running
    bool isServiceRunning = await _geoTrackingService.isBackgroundServiceRunning();
    
    if (_isTrackingEnabled != isServiceRunning) {
      setState(() {
        _isTrackingEnabled = isServiceRunning;
      });
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      setState(() {
        _currentPosition = position;
      });
      
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }
  }
  
  Future<void> _toggleTracking() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (_isTrackingEnabled) {
        await _geoTrackingService.stopTracking();
      } else {
        // Check for background location permission
        LocationPermission permission = await Geolocator.checkPermission();
        bool hasBackgroundPermission = permission == LocationPermission.always;
        
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
    } catch (e) {
      debugPrint('Error toggling tracking: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showBackgroundLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Background Location Required',
          style: SpaceTheme.textTheme.headlineSmall,
        ),
        content: Text(
          'This app needs background location permission to track your location even when the app is closed.',
          style: SpaceTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: SpaceTheme.marsRed),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.requestPermission();
              
              // Check if permission was granted
              LocationPermission permission = await Geolocator.checkPermission();
              if (permission == LocationPermission.always && mounted) {
                _toggleTracking();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SpaceTheme.cosmicPurple,
            ),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'User Location',
          style: SpaceTheme.textTheme.headlineMedium,
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: SpaceBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Map view with cosmic overlay
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // Google Map
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _buildMapView(),
                    ),
                    
                    // Cosmic map overlay
                    Positioned.fill(
                      child: IgnorePointer(
                        child: SvgPicture.asset(
                          'assets/images/map_overlay.svg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    
                    // Rocket icon
                    Positioned(
                      right: 20,
                      top: 20,
                      child: SvgPicture.asset(
                        'assets/images/rocket.svg',
                        width: 60,
                        height: 60,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Controls section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Foreground service toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Foreground service',
                            style: SpaceTheme.textTheme.titleLarge,
                          ),
                          Switch(
                            value: _isTrackingEnabled,
                            onChanged: (value) => _toggleTracking(),
                            activeColor: SpaceTheme.cosmicPurple,
                            activeTrackColor: SpaceTheme.nebulaPink.withAlpha(100),
                          ),
                        ],
                      ),
                      
                      // View location history button
                      CosmicButton(
                        text: 'View Location History',
                        icon: Icons.history,
                        color: SpaceTheme.pulsarBlue,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LocationHistoryScreen(),
                            ),
                          );
                        },
                        isGlowing: true,
                      ),
                      
                      // Current location info
                      if (_currentPosition != null)
                        CosmicCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Location',
                                style: SpaceTheme.textTheme.titleLarge?.copyWith(
                                  color: SpaceTheme.nebulaPink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                                style: SpaceTheme.textTheme.bodyMedium,
                              ),
                              Text(
                                'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                style: SpaceTheme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMapView() {
    return _currentPosition == null
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
                
                // Set custom map style
                _mapController!.setMapStyle('''
                  [
                    {
                      "featureType": "all",
                      "elementType": "geometry",
                      "stylers": [
                        { "color": "#242f3e" }
                      ]
                    },
                    {
                      "featureType": "all",
                      "elementType": "labels.text.stroke",
                      "stylers": [
                        { "color": "#242f3e" },
                        { "lightness": -80 }
                      ]
                    },
                    {
                      "featureType": "all",
                      "elementType": "labels.text.fill",
                      "stylers": [
                        { "color": "#746855" },
                        { "lightness": 20 }
                      ]
                    },
                    {
                      "featureType": "water",
                      "elementType": "geometry",
                      "stylers": [
                        { "color": "#17263c" }
                      ]
                    }
                  ]
                ''');
              });
            },
            markers: _currentPosition == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('currentLocation'),
                      position: LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      infoWindow: const InfoWindow(
                        title: 'Current Location',
                      ),
                    ),
                  },
          );
  }
}

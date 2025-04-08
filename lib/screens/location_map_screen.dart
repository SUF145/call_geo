import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

class LocationMapScreen extends StatefulWidget {
  final List<LocationModel>? initialLocations;

  const LocationMapScreen({super.key, this.initialLocations});

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final Completer<GoogleMapController> _controller = Completer();

  List<LocationModel> _locations = [];
  bool _isLoading = true;

  // Map markers and polylines
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // Default camera position (will be updated with actual data)
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(0, 0),
    zoom: 14,
  );

  // Method to create a custom marker with a number
  Future<BitmapDescriptor> _createMarkerWithNumber(
      int number, Color backgroundColor) async {
    // Create a TextPainter to draw the number on the marker
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: number.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();

    // Create a PictureRecorder to record the drawing operations
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Draw a circle with the specified background color
    final Paint paint = Paint()..color = backgroundColor;
    canvas.drawCircle(const Offset(24, 24), 24, paint);

    // Draw the number in the center of the circle
    textPainter.paint(
      canvas,
      Offset(
        24 - textPainter.width / 2,
        24 - textPainter.height / 2,
      ),
    );

    // Convert the drawing to an image
    final ui.Image image = await pictureRecorder.endRecording().toImage(48, 48);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return BitmapDescriptor.defaultMarker;
    }

    // Convert the ByteData to Uint8List
    final Uint8List uint8List = byteData.buffer.asUint8List();

    // Create a BitmapDescriptor from the Uint8List
    // Note: Using .fromBytes for compatibility with older versions
    // For newer versions, you can use BitmapDescriptor.bytes(uint8List)
    return BitmapDescriptor.fromBytes(uint8List);
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialLocations != null) {
      _locations = widget.initialLocations!;
      _isLoading = true;
      _processLocations().then((_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    } else {
      _loadLocationHistory();
    }
  }

  Future<void> _loadLocationHistory() async {
    setState(() {
      _isLoading = true;
    });

    final locations = await _supabaseService.getLocationHistory();

    setState(() {
      _locations = locations;
    });

    await _processLocations();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processLocations() async {
    if (_locations.isEmpty) return;

    // Clear existing markers and polylines
    _markers.clear();
    _polylines.clear();

    // Create a list of LatLng points for the polyline
    List<LatLng> polylineCoordinates = [];

    // Process locations in chronological order (oldest first)
    final sortedLocations = List<LocationModel>.from(_locations)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Add markers for each location
    for (int i = 0; i < sortedLocations.length; i++) {
      final location = sortedLocations[i];
      final latLng = LatLng(location.latitude, location.longitude);

      // Add to polyline coordinates
      polylineCoordinates.add(latLng);

      // Determine marker color based on position in sequence
      Color markerColor;
      if (i == 0) {
        markerColor = Colors.green; // Start point
      } else if (i == sortedLocations.length - 1) {
        markerColor = Colors.red; // End point
      } else {
        markerColor = Colors.blue; // Middle points
      }

      // Create custom marker with number
      final BitmapDescriptor customMarker =
          await _createMarkerWithNumber(i + 1, markerColor);

      // Create a marker for this location
      final marker = Marker(
        markerId: MarkerId('location_$i'),
        position: latLng,
        infoWindow: InfoWindow(
          title: 'Location ${i + 1}',
          snippet:
              DateFormat('MMM dd, yyyy - hh:mm a').format(location.timestamp),
        ),
        icon: customMarker,
      );

      setState(() {
        _markers.add(marker);
      });
    }

    // Create a polyline to connect all points
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
    );

    _polylines.add(polyline);

    // Set initial camera position to the most recent location
    if (sortedLocations.isNotEmpty) {
      final lastLocation = sortedLocations.last;
      _initialCameraPosition = CameraPosition(
        target: LatLng(lastLocation.latitude, lastLocation.longitude),
        zoom: 14,
      );

      // Move camera to the initial position
      _moveCamera();
    }
  }

  Future<void> _moveCamera() async {
    if (_controller.isCompleted) {
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
          CameraUpdate.newCameraPosition(_initialCameraPosition));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locations.isEmpty
              ? const Center(
                  child: Text(
                    'No location history found',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: _initialCameraPosition,
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: true,
                      compassEnabled: true,
                      mapToolbarEnabled: true,
                      trafficEnabled: false,
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                        _moveCamera();
                      },
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Location History',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total Points: ${_locations.length}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              if (_locations.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'First: ${DateFormat('MMM dd, yyyy - hh:mm a').format(_locations.first.timestamp)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Last: ${DateFormat('MMM dd, yyyy - hh:mm a').format(_locations.last.timestamp)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

class LocationHistoryScreen extends StatefulWidget {
  const LocationHistoryScreen({super.key});

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadLocationHistory();
  }

  Future<void> _loadLocationHistory() async {
    setState(() {
      _isLoading = true;
    });

    final locations = await _supabaseService.getLocationHistory();

    if (mounted) {
      setState(() {
        _locations = locations;
      });

      await _processLocations();

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
        markerColor = Colors.green; // Start point (oldest)
      } else if (i == sortedLocations.length - 1) {
        markerColor = Colors.red; // End point (newest)
      } else {
        markerColor = Colors.blue; // Middle points
      }

      // Create custom marker with number (chronological order, starting from 1)
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

      if (mounted) {
        setState(() {
          _markers.add(marker);
        });
      }
    }

    // Create a polyline to connect all points
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
    );

    if (mounted) {
      setState(() {
        _polylines.add(polyline);
      });
    }

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

  // Method to create a custom marker with a number
  Future<BitmapDescriptor> _createMarkerWithNumber(
      int number, Color backgroundColor) async {
    // Create a TextPainter to draw the number on the marker
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: number.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
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
    canvas.drawCircle(const Offset(24, 24), 16, paint);

    // Draw border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(const Offset(24, 24), 16, borderPaint);

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
    return BitmapDescriptor.bytes(uint8List);
  }

  void _clearLocationHistory() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Location History'),
        content: const Text(
          'Are you sure you want to delete all location history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Close the dialog first
              Navigator.of(dialogContext).pop();
              // Then perform the deletion
              _performClearLocationHistory();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _performClearLocationHistory() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final success = await _supabaseService.clearLocationHistory();

    if (!mounted) return;

    if (success) {
      _loadLocationHistory();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to clear location history'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLocationHistory,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _locations.isEmpty ? null : _clearLocationHistory,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locations.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Map view takes up top half of the screen
                    Expanded(
                      flex: 1,
                      child: _buildMapView(),
                    ),
                    // Divider between map and list
                    Container(
                      height: 4,
                      color: Colors.grey.shade300,
                    ),
                    // List view takes up bottom half of the screen
                    Expanded(
                      flex: 1,
                      child: _buildListView(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Location History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start tracking to record your location history',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadLocationHistory,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
        ),
        // Floating action buttons for map controls
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Button to center on most recent location
              if (_locations.isNotEmpty)
                FloatingActionButton.small(
                  heroTag: 'centerOnLatest',
                  onPressed: () {
                    // Find the most recent location
                    final sortedLocations = List<LocationModel>.from(_locations)
                      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                    final latestLocation = sortedLocations.first;

                    // Move camera to this location
                    if (_controller.isCompleted) {
                      _controller.future.then((controller) {
                        controller.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(latestLocation.latitude,
                                latestLocation.longitude),
                            15,
                          ),
                        );
                      });
                    }
                  },
                  backgroundColor: Colors.red,
                  tooltip: 'Center on latest location',
                  child: const Icon(Icons.location_on),
                ),
              const SizedBox(height: 8),
              // Button to show full path
              if (_polylines.isNotEmpty)
                FloatingActionButton.small(
                  heroTag: 'showFullPath',
                  onPressed: () {
                    if (_controller.isCompleted && _polylines.isNotEmpty) {
                      _controller.future.then((controller) {
                        // Get all points from the polyline
                        final points = _polylines.first.points;
                        if (points.isNotEmpty) {
                          // Create bounds that include all points
                          final bounds = LatLngBounds(
                            southwest: points.reduce((value, element) => LatLng(
                                  value.latitude < element.latitude
                                      ? value.latitude
                                      : element.latitude,
                                  value.longitude < element.longitude
                                      ? value.longitude
                                      : element.longitude,
                                )),
                            northeast: points.reduce((value, element) => LatLng(
                                  value.latitude > element.latitude
                                      ? value.latitude
                                      : element.latitude,
                                  value.longitude > element.longitude
                                      ? value.longitude
                                      : element.longitude,
                                )),
                          );

                          // Animate camera to show all points with padding
                          controller.animateCamera(
                            CameraUpdate.newLatLngBounds(bounds, 50),
                          );
                        }
                      });
                    }
                  },
                  backgroundColor: Colors.blue,
                  tooltip: 'Show full path',
                  child: const Icon(Icons.route),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    // Sort locations by timestamp (newest first for list view)
    final sortedLocations = List<LocationModel>.from(_locations)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      children: [
        // Header with count
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Location History (${sortedLocations.length} points)',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Newest to Oldest',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        // List of locations
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadLocationHistory,
            child: ListView.builder(
              itemCount: sortedLocations.length,
              itemBuilder: (context, index) {
                final location = sortedLocations[index];
                final isNewest = index == 0;
                final isOldest = index == sortedLocations.length - 1;

                // Calculate the index for the chronological order (for matching map markers)
                final chronologicalIndex = sortedLocations.length - index;

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: isNewest || isOldest ? 3 : 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isNewest
                          ? Colors.red
                          : isOldest
                              ? Colors.green
                              : Colors.blue,
                      child: Text(
                        '$chronologicalIndex',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('MMM dd, yyyy - hh:mm a')
                                .format(location.timestamp),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isNewest)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Latest',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                          ),
                        if (isOldest)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'First',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.green),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}',
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.speed,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Accuracy: ${location.accuracy.toStringAsFixed(1)}m',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade700),
                            ),
                            if (location.speed != null) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.directions_run,
                                  size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Speed: ${(location.speed! * 3.6).toStringAsFixed(1)} km/h', // Convert m/s to km/h
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      // Center map on this location when tapped
                      if (_controller.isCompleted) {
                        _controller.future.then((controller) {
                          controller.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(location.latitude, location.longitude),
                              16,
                            ),
                          );
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

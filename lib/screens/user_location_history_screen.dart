import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../models/location_model.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../widgets/date_grouped_location_list.dart';
import '../widgets/map_view.dart';

class UserLocationHistoryScreen extends StatefulWidget {
  final UserModel user;

  const UserLocationHistoryScreen({
    super.key,
    required this.user,
  });

  @override
  State<UserLocationHistoryScreen> createState() =>
      _UserLocationHistoryScreenState();
}

class _UserLocationHistoryScreenState extends State<UserLocationHistoryScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final Completer<GoogleMapController> _controller = Completer();

  List<LocationModel> _locations = [];
  List<LocationModel>? _filteredLocations;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocationHistory();
  }

  Future<void> _loadLocationHistory() async {
    setState(() {
      _isLoading = true;
    });

    final locations =
        await _supabaseService.getUserLocationHistory(widget.user.id);

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

    // Sort locations by timestamp (newest first)
    final sortedLocations = List<LocationModel>.from(_locations)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Set the initial filtered locations to the most recent day's locations
    if (sortedLocations.isNotEmpty) {
      final mostRecentDate =
          DateFormat('yyyy-MM-dd').format(sortedLocations.first.timestamp);
      _filteredLocations = sortedLocations.where((location) {
        final locationDate =
            DateFormat('yyyy-MM-dd').format(location.timestamp);
        return locationDate == mostRecentDate;
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location History for ${widget.user.fullName}'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLocationHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No location history found',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _loadLocationHistory,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
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

  Widget _buildDateGroupedListView() {
    return DateGroupedLocationList(
      locations: _locations,
      onDateSelected: (locationsForDate) {
        setState(() {
          _filteredLocations = locationsForDate;
        });
      },
      onLocationTap: (location) {
        // When a location is tapped, center the map on it
        _controller.future.then((controller) {
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(location.latitude, location.longitude),
              18,
            ),
          );
        });
      },
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        MapView(
          locations: _locations,
          filteredLocations: _filteredLocations,
          showUserPath: true,
          initialZoom: 15,
          key: const ValueKey('user_location_map'),
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
              // Button to show all locations
              FloatingActionButton.small(
                heroTag: 'showAllLocations',
                onPressed: () {
                  setState(() {
                    _filteredLocations = null; // Show all locations
                  });
                },
                backgroundColor: Colors.blue,
                tooltip: 'Show all locations',
                child: const Icon(Icons.map),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return _buildDateGroupedListView();
  }
}

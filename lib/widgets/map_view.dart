import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';

class MapView extends StatefulWidget {
  final List<LocationModel> locations;
  final bool showUserPath;
  final double initialZoom;
  final LocationModel? highlightedLocation;
  final List<LocationModel>? filteredLocations;

  const MapView({
    Key? key,
    required this.locations,
    this.showUserPath = true,
    this.initialZoom = 14.0,
    this.highlightedLocation,
    this.filteredLocations,
  }) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _updateMapData();
  }

  @override
  void didUpdateWidget(MapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locations != widget.locations ||
        oldWidget.filteredLocations != widget.filteredLocations ||
        oldWidget.highlightedLocation != widget.highlightedLocation) {
      _updateMapData();
    }
  }

  void _updateMapData() {
    // Use filtered locations if available, otherwise use all locations
    final locationsToShow = widget.filteredLocations ?? widget.locations;
    if (locationsToShow.isEmpty) return;

    // Create markers for each location
    final markers = <Marker>{};
    final points = <LatLng>[];

    // Sort locations by timestamp (oldest first)
    final sortedLocations = List<LocationModel>.from(locationsToShow)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Add markers and collect points for polyline
    for (int i = 0; i < sortedLocations.length; i++) {
      final location = sortedLocations[i];
      final position = LatLng(location.latitude, location.longitude);
      points.add(position);

      // Create marker
      final isHighlighted = widget.highlightedLocation?.id == location.id;
      final marker = Marker(
        markerId: MarkerId(location.id.isEmpty ? 'loc_$i' : location.id),
        position: position,
        infoWindow: InfoWindow(
          title: 'Location ${i + 1}',
          snippet: '${location.timestamp.toLocal()}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isHighlighted ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
        ),
        // Add a label with the index number
        zIndex: isHighlighted ? 2 : 1,
      );

      markers.add(marker);
    }

    // Create polyline if showing path
    final polylines = <Polyline>{};
    if (widget.showUserPath && points.length > 1) {
      final polyline = Polyline(
        polylineId: const PolylineId('user_path'),
        points: points,
        color: Colors.blue,
        width: 5,
      );
      polylines.add(polyline);
    }

    setState(() {
      _markers = markers;
      _polylines = polylines;
    });

    // Move camera to the most recent location or highlighted location
    if (_mapController != null) {
      final targetLocation = widget.highlightedLocation ?? sortedLocations.last;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(targetLocation.latitude, targetLocation.longitude),
          widget.initialZoom,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use filtered locations if available, otherwise use all locations
    final locationsToShow = widget.filteredLocations ?? widget.locations;
    if (locationsToShow.isEmpty) {
      return const Center(child: Text('No location data available'));
    }

    // Get the most recent location for initial camera position
    final initialLocation = locationsToShow.reduce(
      (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
    );

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(initialLocation.latitude, initialLocation.longitude),
        zoom: widget.initialZoom,
      ),
      markers: _markers,
      polylines: _polylines,
      mapType: MapType.normal,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      onMapCreated: (controller) {
        // Only set the controller if it hasn't been set yet
        if (_mapController == null) {
          _mapController = controller;
          _updateMapData();
        }
      },
    );
  }
}

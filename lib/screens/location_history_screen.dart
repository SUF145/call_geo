import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'location_map_screen.dart';

class LocationHistoryScreen extends StatefulWidget {
  const LocationHistoryScreen({super.key});

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<LocationModel> _locations = [];
  bool _isLoading = true;
  bool _isMapView = false;

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

    setState(() {
      _locations = locations;
      _isLoading = false;
    });
  }

  Future<void> _clearLocationHistory() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Location History'),
        content: const Text(
          'Are you sure you want to delete all location history? This action cannot be undone.',
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
              setState(() {
                _isLoading = true;
              });

              final success = await _supabaseService.clearLocationHistory();

              if (success) {
                _loadLocationHistory();
              } else {
                if (mounted) {
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
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _toggleView() {
    setState(() {
      _isMapView = !_isMapView;
    });
  }

  void _openMapForLocation(LocationModel location) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationMapScreen(
          initialLocations: [location],
        ),
      ),
    );
  }

  void _openFullMapView() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationMapScreen(
          initialLocations: _locations,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location History'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: _toggleView,
            tooltip: _isMapView ? 'Show List View' : 'Show Map View',
          ),
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
              : _isMapView
                  ? LocationMapScreen(initialLocations: _locations)
                  : _buildLocationList(),
      floatingActionButton: !_isMapView && _locations.isNotEmpty
          ? FloatingActionButton(
              onPressed: _openFullMapView,
              tooltip: 'View All on Map',
              child: const Icon(Icons.map),
            )
          : null,
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

  Widget _buildLocationList() {
    return RefreshIndicator(
      onRefresh: _loadLocationHistory,
      child: ListView.builder(
        itemCount: _locations.length,
        itemBuilder: (context, index) {
          final location = _locations[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.location_on),
              ),
              title: Text(
                'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Accuracy: ${location.accuracy.toStringAsFixed(2)} meters'),
                  Text(
                      'Time: ${DateFormat('MMM dd, yyyy - HH:mm:ss').format(location.timestamp)}'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.map),
                onPressed: () => _openMapForLocation(location),
                tooltip: 'View on Map',
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

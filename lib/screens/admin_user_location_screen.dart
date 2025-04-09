import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/location_model.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../widgets/map_view.dart';
import '../widgets/date_grouped_location_list.dart';

class AdminUserLocationScreen extends StatefulWidget {
  final String userId;

  const AdminUserLocationScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<AdminUserLocationScreen> createState() =>
      _AdminUserLocationScreenState();
}

class _AdminUserLocationScreenState extends State<AdminUserLocationScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<LocationModel> _locations = [];
  List<LocationModel>? _filteredLocations;
  UserModel? _user;
  bool _isLoading = true;
  bool _showMap = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user profile
      final userData = await _supabaseService.supabase
          .from('profiles')
          .select()
          .eq('id', widget.userId)
          .single();

      _user = UserModel.fromJson(userData);

      // Get user's location history
      final locations =
          await _supabaseService.getUserLocationHistory(widget.userId);

      if (mounted) {
        setState(() {
          _locations = locations;
        });

        await _processLocations();

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        // This would be used if we had a map controller
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _user != null ? '${_user!.fullName}\'s Location' : 'User Location'),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
            tooltip: _showMap ? 'Show List View' : 'Show Map View',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locations.isEmpty
              ? const Center(child: Text('No location data available'))
              : Column(
                  children: [
                    // Map view (top half)
                    Expanded(
                      flex: 1,
                      child: _showMap
                          ? MapView(
                              locations: _locations,
                              filteredLocations: _filteredLocations,
                              showUserPath: true,
                              initialZoom: 15,
                              key: const ValueKey('admin_top_map'),
                            )
                          : _buildDateGroupedListView(),
                    ),

                    // Divider
                    const Divider(height: 1, thickness: 1),

                    // Location list (bottom half)
                    Expanded(
                      flex: 1,
                      child: _showMap
                          ? _buildDateGroupedListView()
                          : MapView(
                              locations: _locations,
                              filteredLocations: _filteredLocations,
                              showUserPath: true,
                              initialZoom: 15,
                              key: const ValueKey('admin_bottom_map'),
                            ),
                    ),
                  ],
                ),
    );
  }
}

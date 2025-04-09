import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';
import '../widgets/map_view.dart';
import '../widgets/location_list.dart';

class AdminUserLocationScreen extends StatefulWidget {
  final String userId;

  const AdminUserLocationScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<AdminUserLocationScreen> createState() => _AdminUserLocationScreenState();
}

class _AdminUserLocationScreenState extends State<AdminUserLocationScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<LocationModel> _locations = [];
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
      final locations = await _supabaseService.getUserLocationHistory(widget.userId);
      
      if (mounted) {
        setState(() {
          _locations = locations;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user != null 
          ? '${_user!.fullName}\'s Location' 
          : 'User Location'),
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
                              showUserPath: true,
                              initialZoom: 15,
                            )
                          : LocationList(
                              locations: _locations,
                              onLocationTap: (location) {
                                setState(() {
                                  _showMap = true;
                                });
                              },
                            ),
                    ),
                    
                    // Divider
                    const Divider(height: 1, thickness: 1),
                    
                    // Location list (bottom half)
                    Expanded(
                      flex: 1,
                      child: _showMap
                          ? LocationList(
                              locations: _locations,
                              onLocationTap: (location) {
                                // Scroll to the location on the map
                              },
                            )
                          : MapView(
                              locations: _locations,
                              showUserPath: true,
                              initialZoom: 15,
                            ),
                    ),
                  ],
                ),
    );
  }
}

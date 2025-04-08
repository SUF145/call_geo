import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_geofence_settings_model.dart';
import '../services/supabase_service.dart';
import 'add_user_screen.dart';
import 'user_geofence_settings_screen.dart';
import 'user_location_history_screen.dart';

class UserManagementScreen extends StatefulWidget {
  final String adminId;

  const UserManagementScreen({
    Key? key,
    required this.adminId,
  }) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _usersWithSettings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    final usersWithSettings =
        await _supabaseService.getUsersWithGeofenceSettings(widget.adminId);

    setState(() {
      _usersWithSettings = usersWithSettings;
      _isLoading = false;
    });
  }

  Future<void> _manageGeofence(
      UserModel user, UserGeofenceSettings? settings) async {
    // Get the latest settings for this user before navigating
    final latestSettings =
        await _supabaseService.getUserGeofenceSettings(user.id);

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserGeofenceSettingsScreen(
          user: user,
          adminId: widget.adminId,
          initialSettings:
              latestSettings, // Use the latest settings from the database
        ),
      ),
    );

    // Always refresh the list when returning from the settings screen
    // This ensures we have the latest data
    _loadUsers();
  }

  Future<void> _viewLocationHistory(UserModel user) async {
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserLocationHistoryScreen(
          user: user,
        ),
      ),
    );
  }

  Future<void> _editUser(UserModel user) async {
    // Show dialog to edit user details
    final TextEditingController nameController =
        TextEditingController(text: user.fullName);
    final TextEditingController emailController =
        TextEditingController(text: user.email);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await _supabaseService.updateUser(
        userId: user.id,
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
      );

      if (success) {
        _loadUsers(); // Refresh the list
      }
    }

    nameController.dispose();
    emailController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _usersWithSettings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No users found',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddUserScreen(adminId: widget.adminId),
                            ),
                          );

                          if (result == true) {
                            _loadUsers();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add User'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _usersWithSettings.length,
                        itemBuilder: (context, index) {
                          final user =
                              _usersWithSettings[index]['user'] as UserModel;
                          final settings = _usersWithSettings[index]
                              ['geofence_settings'] as UserGeofenceSettings?;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: Text(user.fullName),
                                  subtitle: Text(user.email),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _editUser(user),
                                        tooltip: 'Edit User',
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          settings?.enabled == true
                                              ? Icons.location_on
                                              : Icons.location_off,
                                          color: settings?.enabled == true
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                        onPressed: () =>
                                            _manageGeofence(user, settings),
                                        tooltip: 'Manage Geofence',
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.map,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () =>
                                            _viewLocationHistory(user),
                                        tooltip: 'View Location History',
                                      ),
                                    ],
                                  ),
                                ),
                                if (settings?.enabled == true)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 16.0,
                                      right: 16.0,
                                      bottom: 8.0,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.fence,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Geofence active: ${settings!.radius.toStringAsFixed(0)}m radius',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddUserScreen(adminId: widget.adminId),
                            ),
                          );

                          if (result == true) {
                            _loadUsers();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add User'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

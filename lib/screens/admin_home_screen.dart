import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'user_management_screen.dart';
import 'geofence_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final UserModel admin;

  const AdminHomeScreen({
    Key? key,
    required this.admin,
  }) : super(key: key);

  Future<void> _signOut(BuildContext context) async {
    await SupabaseService().signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _deleteAdminAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Admin Account'),
        content: const Text(
          'Are you sure you want to delete your admin account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await SupabaseService().deleteAdminAccount(admin.id);

      if (success && context.mounted) {
        await SupabaseService().signOut();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug information
    debugPrint('Building AdminHomeScreen');
    debugPrint('Admin user: ${admin.email}');
    debugPrint('Admin role: ${admin.role}');
    debugPrint('Is admin: ${admin.isAdmin}');

    // Force check if user is admin
    if (!admin.isAdmin) {
      debugPrint('WARNING: User is not an admin but is in AdminHomeScreen!');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Name: ${admin.fullName}'),
                    Text('Email: ${admin.email}'),
                    Text('Mobile: ${admin.mobileNumber ?? "Not provided"}'),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _deleteAdminAccount(context),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Delete Admin Account',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Admin Features',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'User Management',
              'Add and manage users',
              Icons.people,
              Colors.blue,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        UserManagementScreen(adminId: admin.id),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              'Geofence Settings',
              'Configure restricted areas',
              Icons.fence,
              Colors.orange,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GeofenceScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 60,
                color: color,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

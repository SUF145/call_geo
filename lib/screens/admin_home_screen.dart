import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/firebase_messaging_service_new.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'user_management_screen.dart';
import 'geofence_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  final UserModel admin;

  const AdminHomeScreen({
    Key? key,
    required this.admin,
  }) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late UserModel admin;

  @override
  void initState() {
    super.initState();
    admin = widget.admin;
    _saveAdminFCMToken();
  }

  Future<void> _saveAdminFCMToken() async {
    try {
      final firebaseMessagingService = FirebaseMessagingService();
      await firebaseMessagingService.initialize();
      final token = await firebaseMessagingService.getToken();
      if (token != null) {
        debugPrint('Manually saving FCM token for admin ${admin.id}: $token');
        await firebaseMessagingService.saveTokenForUser(admin.id, token);
      }
    } catch (e) {
      debugPrint('Error saving admin FCM token: $e');
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await SupabaseService().signOut();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  Future<void> _removeAdminPrivileges(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin Privileges'),
        content: const Text(
          'Are you sure you want to remove your admin privileges? You will be signed out and your account will be converted to a regular user account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove Privileges'),
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

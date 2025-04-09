import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/user_model.dart';
import '../models/location_model.dart';
import '../models/user_geofence_settings_model.dart';
import 'firebase_messaging_service_new.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  final supabase = Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url:
          'https://gwipwoxbulgdfjgirtle.supabase.co', // Replace with your Supabase URL
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3aXB3b3hidWxnZGZqZ2lydGxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQwOTc0ODksImV4cCI6MjA1OTY3MzQ4OX0.a-r2-tqe8f9KHEkD_2yn2Uo3hYz2LdimjprI6nU_7gE', // Replace with your Supabase Anon Key
    );
  }

  // Check if admin exists
  Future<bool> adminExists() async {
    try {
      debugPrint('Checking if admin exists...');
      // Check the profiles table for admin users
      final result = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'admin')
          .limit(1);

      final exists = result.isNotEmpty;
      debugPrint('Admin check result: $exists');
      return exists;
    } catch (e) {
      debugPrint('Error checking if admin exists: $e');
      // Rethrow the error so it can be handled by the FutureBuilder
      rethrow;
    }
  }

  // Admin Sign Up
  Future<UserModel?> adminSignUp({
    required String email,
    required String password,
    required String fullName,
    required String mobileNumber,
  }) async {
    try {
      debugPrint('Starting admin signup for: $email');
      // First check if an admin already exists
      final adminExistsResult = await adminExists();
      debugPrint('Admin exists check result: $adminExistsResult');

      if (adminExistsResult) {
        debugPrint('Admin already exists, aborting signup');
        Fluttertoast.showToast(
          msg: "An admin account already exists",
          toastLength: Toast.LENGTH_LONG,
        );
        return null;
      }

      debugPrint('Creating auth user for admin');
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        debugPrint('Auth user created with ID: ${response.user!.id}');
        // Create admin profile in the database
        // Explicitly set the role to 'admin' to ensure it's recognized correctly
        final profileData = {
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'mobile_number': mobileNumber,
          'role':
              'admin', // This must match the value expected in UserModel.fromJson
          'created_at': DateTime.now().toIso8601String(),
        };

        debugPrint('Creating admin profile with data: $profileData');
        await supabase.from('profiles').insert(profileData);

        final userModel = UserModel(
          id: response.user!.id,
          email: email,
          fullName: fullName,
          mobileNumber: mobileNumber,
          role: UserRole.admin,
        );

        debugPrint(
            'Admin user created successfully with role: ${userModel.role}');
        debugPrint('Is admin: ${userModel.isAdmin}');

        return userModel;
      }

      debugPrint('Auth user creation failed - user is null');
      return null;
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error during admin sign up: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
      return null;
    }
  }

  // Add User (by Admin)
  Future<UserModel?> addUser({
    required String email,
    required String password,
    required String fullName,
    required String adminId,
  }) async {
    try {
      // Create auth user through regular signup
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user != null) {
        // Create user profile in the database
        await supabase.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'full_name': fullName,
          'role': 'user',
          'created_by': adminId,
          'created_at': DateTime.now().toIso8601String(),
        });

        return UserModel(
          id: response.user!.id,
          email: email,
          fullName: fullName,
          role: UserRole.user,
          createdBy: adminId,
        );
      }
      return null;
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error adding user: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
      return null;
    }
  }

  // Sign In (for both admin and regular users)
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Signing in with email: $email');
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        debugPrint('Auth successful for user ID: ${response.user!.id}');
        // Get user profile from the database
        final userData = await supabase
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .single();

        debugPrint('User profile data: $userData');
        final userModel = UserModel.fromJson(userData);
        debugPrint('User role from DB: ${userData['role']}');
        debugPrint('User role in model: ${userModel.role}');
        debugPrint('Is admin: ${userModel.isAdmin}');

        // Save the FCM token to Supabase
        final firebaseMessagingService = FirebaseMessagingService();
        await firebaseMessagingService.initialize();

        return userModel;
      }
      debugPrint('Auth failed - user is null');
      return null;
    } catch (e) {
      debugPrint('Error during sign in: $e');
      Fluttertoast.showToast(
        msg: "Error during sign in: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
      return null;
    }
  }

  // Get all users created by an admin
  Future<List<UserModel>> getUsersByAdmin(String adminId) async {
    try {
      final result = await supabase
          .from('profiles')
          .select()
          .eq('created_by', adminId)
          .eq('role', 'user');

      return result.map((json) => UserModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting users by admin: $e');
      return [];
    }
  }

  // Update user details
  Future<bool> updateUser({
    required String userId,
    String? fullName,
    String? email,
    String? role,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (fullName != null) updates['full_name'] = fullName;
      if (email != null) updates['email'] = email;
      if (role != null) updates['role'] = role;

      if (updates.isEmpty) return true; // Nothing to update

      debugPrint('Updating user $userId with data: $updates');
      await supabase.from('profiles').update(updates).eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      Fluttertoast.showToast(
        msg: "Error updating user: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
      return false;
    }
  }

  // Promote user to admin
  Future<bool> promoteToAdmin(String userId) async {
    try {
      debugPrint('Promoting user $userId to admin role');

      // Update the user's role to admin
      final success = await updateUser(userId: userId, role: 'admin');

      if (success) {
        // Get the user's email
        final userData = await supabase
            .from('profiles')
            .select('email')
            .eq('id', userId)
            .single();

        debugPrint('User successfully promoted to admin');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error promoting user to admin: $e');
      Fluttertoast.showToast(
        msg: "Error promoting user to admin: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
      return false;
    }
  }

  // Delete admin account
  Future<bool> deleteAdminAccount(String adminId) async {
    try {
      // First check if this is an admin account
      final userData = await supabase
          .from('profiles')
          .select('role, email')
          .eq('id', adminId)
          .single();

      if (userData['role'] != 'admin') {
        Fluttertoast.showToast(
          msg: "Only admin accounts can be deleted",
          toastLength: Toast.LENGTH_LONG,
        );
        return false;
      }

      debugPrint('Removing admin privileges for user: ${userData['email']}');

      await supabase.from('profiles').update({
        'created_by': null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('created_by', adminId);
      await supabase.from('profiles').delete().eq('id', adminId);

      return true;
    } catch (e) {
      debugPrint('Error removing admin privileges: $e');
      Fluttertoast.showToast(
        msg: "Error removing admin privileges: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error during sign out: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  // Get Current User
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = supabase.auth.currentUser;
      debugPrint('Current auth user: ${user?.email}');

      if (user != null) {
        try {
          final userData = await supabase
              .from('profiles')
              .select()
              .eq('id', user.id)
              .single();

          debugPrint('User profile data: $userData');
          final userModel = UserModel.fromJson(userData);
          debugPrint('User role from DB: ${userData['role']}');
          debugPrint('User role in model: ${userModel.role}');
          debugPrint('Is admin: ${userModel.isAdmin}');

          return userModel;
        } catch (e) {
          debugPrint('Error getting user profile: $e');

          // If the profile doesn't exist, create one
          debugPrint('Error message: ${e.toString()}');
          if (e.toString().contains('no rows') ||
              e.toString().contains('0 rows')) {
            debugPrint('Creating profile for user ${user.id}');
            return await _createUserProfile(user);
          }
          rethrow;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  // Create a profile for a user
  Future<UserModel?> _createUserProfile(User user) async {
    try {
      final email = user.email ?? '';
      final fullName =
          user.userMetadata?['full_name'] ?? email.split('@').first;

      // Create profile in the database
      final profileData = {
        'id': user.id,
        'email': email,
        'full_name': fullName,
        'role': 'user', // Default role is user
        'created_at': DateTime.now().toIso8601String(),
      };

      debugPrint('Creating user profile with data: $profileData');
      await supabase.from('profiles').insert(profileData);

      return UserModel(
        id: user.id,
        email: email,
        fullName: fullName,
        role: UserRole.user,
      );
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      return null;
    }
  }

  // Save location to Supabase
  Future<bool> saveLocation(Position position) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final uuid = Uuid();
      final locationData = {
        'id': uuid.v4(),
        'user_id': user.id,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await supabase.from('locations').insert(locationData);
      return true;
    } catch (e) {
      debugPrint('Error saving location: $e');
      return false;
    }
  }

  // Get user geofence settings
  Future<UserGeofenceSettings?> getUserGeofenceSettings(String userId) async {
    try {
      debugPrint('Fetching geofence settings for user: $userId');
      final result = await supabase
          .from('user_geofence_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (result == null) {
        debugPrint('No geofence settings found for user: $userId');
        return null;
      }

      final settings = UserGeofenceSettings.fromJson(result);
      debugPrint(
          'Found geofence settings for user $userId: ${settings.center.latitude}, ${settings.center.longitude}, radius: ${settings.radius}, enabled: ${settings.enabled}');
      return settings;
    } catch (e) {
      debugPrint('Error getting user geofence settings: $e');
      return null;
    }
  }

  // Save user geofence settings
  Future<bool> saveUserGeofenceSettings({
    required String userId,
    required String adminId,
    required bool enabled,
    required LatLng center,
    required double radius,
  }) async {
    try {
      debugPrint(
          'Saving geofence settings for user $userId: ${center.latitude}, ${center.longitude}, radius: $radius, enabled: $enabled');

      // Check if settings already exist for this user
      final existingSettings = await supabase
          .from('user_geofence_settings')
          .select('id')
          .eq('user_id', userId);

      final now = DateTime.now().toIso8601String();

      if (existingSettings.isNotEmpty) {
        debugPrint('Updating existing geofence settings for user $userId');
        // Update existing settings
        await supabase.from('user_geofence_settings').update({
          'admin_id': adminId,
          'enabled': enabled,
          'latitude': center.latitude,
          'longitude': center.longitude,
          'radius': radius,
          'updated_at': now,
        }).eq('user_id', userId);
      } else {
        debugPrint('Creating new geofence settings for user $userId');
        // Create new settings
        await supabase.from('user_geofence_settings').insert({
          'user_id': userId,
          'admin_id': adminId,
          'enabled': enabled,
          'latitude': center.latitude,
          'longitude': center.longitude,
          'radius': radius,
          'created_at': now,
          'updated_at': now,
        });
      }

      debugPrint('Successfully saved geofence settings for user $userId');
      return true;
    } catch (e) {
      debugPrint('Error saving user geofence settings: $e');
      return false;
    }
  }

  // Toggle user geofence settings
  Future<bool> toggleUserGeofenceSettings({
    required String userId,
    required bool enabled,
  }) async {
    try {
      // Check if settings exist for this user
      final existingSettings = await supabase
          .from('user_geofence_settings')
          .select('id')
          .eq('user_id', userId);

      if (existingSettings.isEmpty) {
        debugPrint('No geofence settings found for user $userId');
        return false;
      }

      // Update enabled status
      await supabase.from('user_geofence_settings').update({
        'enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      return true;
    } catch (e) {
      debugPrint('Error toggling user geofence settings: $e');
      return false;
    }
  }

  // Get all users with their geofence settings
  Future<List<Map<String, dynamic>>> getUsersWithGeofenceSettings(
      String adminId) async {
    try {
      // Get all users created by this admin
      final users = await getUsersByAdmin(adminId);

      // Get geofence settings for each user
      List<Map<String, dynamic>> usersWithSettings = [];

      for (var user in users) {
        // Get geofence settings for this user
        final settings = await getUserGeofenceSettings(user.id);

        usersWithSettings.add({
          'user': user,
          'geofence_settings': settings,
        });
      }

      return usersWithSettings;
    } catch (e) {
      debugPrint('Error getting users with geofence settings: $e');
      return [];
    }
  }

  // Get current user's location history
  Future<List<LocationModel>> getLocationHistory() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      return await getUserLocationHistory(user.id);
    } catch (e) {
      debugPrint('Error getting location history: $e');
      return [];
    }
  }

  // Get a specific user's location history
  Future<List<LocationModel>> getUserLocationHistory(String userId) async {
    try {
      debugPrint('Fetching location history for user: $userId');
      final data = await supabase
          .from('locations')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false);

      final locations = data
          .map<LocationModel>((item) => LocationModel.fromJson(item))
          .toList();

      debugPrint(
          'Found ${locations.length} location records for user: $userId');
      return locations;
    } catch (e) {
      debugPrint('Error getting user location history: $e');
      return [];
    }
  }

  // Get the admin who created a user
  Future<UserModel?> getCreatorAdmin(String userId) async {
    try {
      debugPrint('Fetching creator admin for user: $userId');
      final userData = await supabase
          .from('profiles')
          .select('created_by')
          .eq('id', userId)
          .single();

      final String? adminId = userData['created_by'];

      if (adminId == null) {
        debugPrint('No creator admin found for user: $userId');
        return null;
      }

      final adminData = await supabase
          .from('profiles')
          .select()
          .eq('id', adminId)
          .eq('role', 'admin')
          .maybeSingle();

      if (adminData == null) {
        debugPrint('Admin not found or not an admin anymore: $adminId');
        return null;
      }

      return UserModel.fromJson(adminData);
    } catch (e) {
      debugPrint('Error getting creator admin: $e');
      return null;
    }
  }

  // Delete all location history for current user
  Future<bool> clearLocationHistory() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase.from('locations').delete().eq('user_id', user.id);

      return true;
    } catch (e) {
      debugPrint('Error clearing location history: $e');
      return false;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/user_model.dart';
import '../models/location_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

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
      // First check the admin_settings table
      final adminSettings =
          await supabase.from('admin_settings').select('admin_id').limit(1);

      if (adminSettings.isNotEmpty && adminSettings[0]['admin_id'] != null) {
        return true;
      }

      // As a fallback, check the profiles table
      final result = await supabase
          .from('profiles')
          .select('id')
          .eq('role', 'admin')
          .limit(1);

      return result.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if admin exists: $e');
      return false;
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

        // Create entry in admin_settings table
        final adminSettingsData = {
          'admin_id': response.user!.id,
          'admin_email': email,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        debugPrint(
            'Creating admin_settings entry with data: $adminSettingsData');
        await supabase.from('admin_settings').insert(adminSettingsData);

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

        // Create entry in admin_settings table
        await supabase.from('admin_settings').insert({
          'admin_id': userId,
          'admin_email': userData['email'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

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
          .select('role')
          .eq('id', adminId)
          .single();

      if (userData['role'] != 'admin') {
        Fluttertoast.showToast(
          msg: "Only admin accounts can be deleted",
          toastLength: Toast.LENGTH_LONG,
        );
        return false;
      }

      // Remove from admin_settings table first
      await supabase.from('admin_settings').delete().eq('admin_id', adminId);

      // Delete the admin user
      await supabase.auth.admin.deleteUser(adminId);

      return true;
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error deleting admin account: ${e.toString()}",
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

  // Get user's location history
  Future<List<LocationModel>> getLocationHistory() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final data = await supabase
          .from('locations')
          .select()
          .eq('user_id', user.id)
          .order('timestamp', ascending: false);

      return data
          .map<LocationModel>((item) => LocationModel.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error getting location history: $e');
      return [];
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

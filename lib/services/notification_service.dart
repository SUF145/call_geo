import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// A service for sending cross-device notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final SupabaseService _supabaseService = SupabaseService();

  /// Send a notification to a specific user
  Future<bool> sendNotificationToUser(
    String userId,
    String title,
    String message, {
    bool isAdminNotification = false,
    String? targetUserId,
  }) async {
    try {
      debugPrint('Sending notification to user: $userId');
      debugPrint('Title: $title');
      debugPrint('Message: $message');
      debugPrint('Is admin notification: $isAdminNotification');
      debugPrint('Target user ID: $targetUserId');

      // In a real implementation, we would call a Supabase Edge Function or other backend service
      // to send the notification. For now, we'll simulate this with a direct call to Supabase.

      // Get the current user for authentication
      final User? currentUser = _supabaseService.supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('No authenticated user found');
        return false;
      }

      // Get the user's device tokens
      final response = await _supabaseService.supabase
          .from('device_tokens')
          .select()
          .eq('user_id', userId);

      if (response.isEmpty) {
        debugPrint('No device tokens found for user: $userId');
        return false;
      }

      debugPrint('Found ${response.length} device tokens for user: $userId');

      // In a real implementation, we would call a secure backend service to send the notification
      // For now, we'll just log the tokens and simulate success
      for (final tokenData in response) {
        final String token = tokenData['token'];
        debugPrint('Would send notification to token: $token');
      }

      // Simulate a successful notification
      return true;
    } catch (e) {
      debugPrint('Error sending notification to user: $e');
      return false;
    }
  }

  /// Store a device token in Supabase
  Future<bool> storeDeviceToken(String token) async {
    try {
      // Get the current user
      final User? user = _supabaseService.supabase.auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return false;
      }

      // Save the token to Supabase
      await _supabaseService.supabase.from('device_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'device_type': 'android', // For simplicity, we're assuming Android
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Device token stored in Supabase: $token');
      return true;
    } catch (e) {
      debugPrint('Error storing device token: $e');
      return false;
    }
  }
}

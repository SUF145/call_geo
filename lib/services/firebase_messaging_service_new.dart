import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_cloud_messaging_v1.dart';
import 'supabase_service.dart';

// Define a top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  await Firebase.initializeApp();

  debugPrint("Handling a background message: ${message.messageId}");
  // The system will show the notification for us
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();

  factory FirebaseMessagingService() {
    return _instance;
  }

  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final SupabaseService _supabaseService = SupabaseService();

  // Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      debugPrint('Firebase initialized successfully');

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Request permission for notifications
      await _requestPermission();

      // Handle incoming messages when the app is in the foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when the app is in the background but not terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Get the token and save it to Supabase
      await _saveTokenToSupabase();

      // Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((String token) {
        _saveTokenToSupabase(token);
      });

      debugPrint('Firebase Messaging Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging Service: $e');
    }
  }

  // Request permission for notifications
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint(
          'Message also contained a notification: ${message.notification}');
    }
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped in background: ${message.data}');
    _handleNotificationData(message.data);
  }

  // Handle notification data
  void _handleNotificationData(Map<String, dynamic> data) {
    // Check if this is an admin notification with a user ID
    final bool isAdminNotification = data['is_admin_notification'] == 'true';
    final String? userId = data['user_id'];

    if (isAdminNotification && userId != null) {
      // Navigate to the user's location history
      debugPrint('Navigating to user location history for user: $userId');
      // This will be handled by the app's navigation system
    }
  }

  // Get the FCM token
  Future<String?> getToken() async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      if (token == null) {
        debugPrint('Failed to get FCM token');
      }
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  // Save the FCM token to Supabase
  Future<void> _saveTokenToSupabase([String? newToken]) async {
    try {
      final String? token = newToken ?? await getToken();
      if (token == null) {
        debugPrint('Failed to get FCM token');
        return;
      }

      debugPrint('FCM Token: $token');

      // Get the current user
      final User? user = _supabaseService.supabase.auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found');
        return;
      }

      // Save token for the current user
      await saveTokenForUser(user.id, token);
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // Save a token for a specific user
  Future<void> saveTokenForUser(String userId, String token) async {
    try {
      debugPrint('Saving token for user: $userId');
      debugPrint('Token: $token');
      // Check if this token already exists for this user
      final existingTokens = await _supabaseService.supabase
          .from('device_tokens')
          .select()
          .eq('user_id', userId)
          .eq('token', token);

      if (existingTokens.isNotEmpty) {
        // Token exists, update it
        debugPrint('Updating existing FCM token');
        await _supabaseService.supabase
            .from('device_tokens')
            .update({
              'device_type': Platform.isAndroid ? 'android' : 'ios',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('token', token);
      } else {
        // Token doesn't exist, insert it
        debugPrint('Inserting new FCM token');
        await _supabaseService.supabase.from('device_tokens').insert({
          'user_id': userId,
          'token': token,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      debugPrint('FCM token saved to Supabase');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // Send a notification to a specific user
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

      // Get the user's device tokens
      debugPrint('Querying device_tokens table for user_id: $userId');
      List<dynamic> tokenResponse;
      try {
        // For all notifications, use the standard query
        final response = await _supabaseService.supabase
            .from('device_tokens')
            .select()
            .eq('user_id', userId);

        debugPrint('Query response: $response');

        if (response.isEmpty) {
          debugPrint('No device tokens found for user: $userId');

          // Let's try to get all tokens to see if the table has any data
          final allTokens =
              await _supabaseService.supabase.from('device_tokens').select();

          debugPrint('All tokens in the table: $allTokens');
          debugPrint('Total tokens in the table: ${allTokens.length}');

          return false;
        }

        // Store the response for use outside the try block
        tokenResponse = response;
      } catch (e) {
        debugPrint('Error querying device tokens: $e');
        return false;
      }

      debugPrint(
          'Found ${tokenResponse.length} device tokens for user: $userId');

      // Extract the tokens
      final List<String> tokens =
          tokenResponse.map<String>((data) => data['token'] as String).toList();

      // Create the notification data
      final Map<String, dynamic> data = {
        'title': title,
        'message': message,
        'is_admin_notification': isAdminNotification.toString(),
      };

      if (targetUserId != null) {
        data['user_id'] = targetUserId;
      }

      // Use the FCM v1 API to send the notification
      final FirebaseCloudMessagingV1 fcmV1 = FirebaseCloudMessagingV1();
      final bool success = await fcmV1.sendNotificationToDevices(
        tokens: tokens,
        title: title,
        body: message,
        data: data,
      );

      if (success) {
        debugPrint('Successfully sent notification to at least one device');
      } else {
        debugPrint('Failed to send notification to any device');
      }

      return success;
    } catch (e) {
      debugPrint('Error sending notification to user: $e');
      return false;
    }
  }
}

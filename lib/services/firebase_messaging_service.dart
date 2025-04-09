import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

// Define a top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  await Firebase.initializeApp();

  debugPrint("Handling a background message: ${message.messageId}");
  // We don't need to show a notification here as the system will do it for us
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();

  factory FirebaseMessagingService() {
    return _instance;
  }

  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final SupabaseService _supabaseService = SupabaseService();

  // Initialize Firebase Messaging
  Future<void> initialize() async {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission for notifications
    await _requestPermission();

    // Configure notification channels for Android
    await _configureLocalNotifications();

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

  // Configure local notifications for Android
  Future<void> _configureLocalNotifications() async {
    // Initialize the plugin for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize the plugin for iOS
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    // Initialize settings for all platforms
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint('Notification tapped: ${response.payload}');
        if (response.payload != null) {
          final Map<String, dynamic> data = json.decode(response.payload!);
          _handleNotificationData(data);
        }
      },
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'geofence_alert_channel',
        'Geofence Alerts',
        description: 'This channel is used for geofence alert notifications',
        importance: Importance.high,
      );

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint(
          'Message also contained a notification: ${message.notification}');

      // Show a local notification
      _showLocalNotification(
        message.notification?.title ?? 'Geofence Alert',
        message.notification?.body ?? 'A user has left their geofence area',
        message.data,
      );
    } else if (message.data.isNotEmpty) {
      // Show a local notification from data
      _showLocalNotification(
        message.data['title'] ?? 'Geofence Alert',
        message.data['message'] ?? 'A user has left their geofence area',
        message.data,
      );
    }
  }

  // Show a local notification
  Future<void> _showLocalNotification(
      String title, String body, Map<String, dynamic> data) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'geofence_alert_channel',
      'Geofence Alerts',
      channelDescription:
          'This channel is used for geofence alert notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: json.encode(data),
    );
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

  // Save the FCM token to Supabase
  Future<void> _saveTokenToSupabase([String? newToken]) async {
    try {
      final String? token = newToken ?? await _firebaseMessaging.getToken();
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

      // Save the token to Supabase
      await _supabaseService.supabase.from('device_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'device_type': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('FCM token saved to Supabase');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  // Send a notification to a specific user
  Future<bool> sendNotificationToUser(
      String userId, String title, String message,
      {bool isAdminNotification = false, String? targetUserId}) async {
    try {
      // Get the user's device tokens
      final response = await _supabaseService.supabase
          .from('device_tokens')
          .select()
          .eq('user_id', userId);

      if (response.isEmpty) {
        debugPrint('No device tokens found for user: $userId');
        return false;
      }

      // Send a notification to each device
      bool anySuccess = false;
      for (final tokenData in response) {
        final String token = tokenData['token'];
        final bool success = await _sendFcmMessage(
          token,
          title,
          message,
          isAdminNotification: isAdminNotification,
          userId: targetUserId,
        );

        if (success) {
          anySuccess = true;
        }
      }

      return anySuccess;
    } catch (e) {
      debugPrint('Error sending notification to user: $e');
      return false;
    }
  }

  // Send an FCM message to a specific device
  Future<bool> _sendFcmMessage(
    String token,
    String title,
    String message, {
    bool isAdminNotification = false,
    String? userId,
  }) async {
    try {
      // This would normally use a server to send the notification
      // For testing purposes, we'll simulate this with a direct FCM API call
      // In a production app, this should be done from a secure server

      // For now, we'll just log the message
      debugPrint('Would send FCM message to token: $token');
      debugPrint('Title: $title');
      debugPrint('Message: $message');
      debugPrint('Is admin notification: $isAdminNotification');
      debugPrint('User ID: $userId');

      // In a real implementation, you would use your server to send the notification
      // The following code is for illustration only and won't work without a server key
      /*
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=YOUR_SERVER_KEY',
        },
        body: json.encode({
          'to': token,
          'data': {
            'title': title,
            'message': message,
            'is_admin_notification': isAdminNotification.toString(),
            'user_id': userId,
          },
        }),
      );

      return response.statusCode == 200;
      */

      return true; // Simulating success
    } catch (e) {
      debugPrint('Error sending FCM message: $e');
      return false;
    }
  }
}

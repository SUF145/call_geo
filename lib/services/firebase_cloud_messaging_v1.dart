import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';

import '../config/firebase_config.dart';

class FirebaseCloudMessagingV1 {
  static final FirebaseCloudMessagingV1 _instance =
      FirebaseCloudMessagingV1._internal();
  bool _initialized = false;

  factory FirebaseCloudMessagingV1() {
    return _instance;
  }

  FirebaseCloudMessagingV1._internal();

  // Initialize the FCM service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Verify that we can get an access token
      final token = await _getAccessToken();
      debugPrint(
          'FCM v1 service initialized successfully with token: ${token.substring(0, 10)}...');
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing FCM v1 service: $e');
      rethrow;
    }
  }

  // Get an access token for the FCM API
  Future<String> _getAccessToken() async {
    try {
      // Load the service account key file
      final String serviceAccountJson =
          await rootBundle.loadString(FirebaseConfig.serviceAccountKeyPath);

      // Parse the service account key
      final Map<String, dynamic> serviceAccountData =
          jsonDecode(serviceAccountJson);

      // Create a service account credentials object
      final serviceAccountCredentials =
          ServiceAccountCredentials.fromJson(serviceAccountData);

      // Get an HTTP client with the credentials
      final client = await clientViaServiceAccount(
        serviceAccountCredentials,
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );

      // Return the access token
      return client.credentials.accessToken.data;
    } catch (e) {
      debugPrint('Error getting access token: $e');
      rethrow;
    }
  }

  // Send a notification to a specific device
  Future<bool> sendNotificationToDevice({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    return sendNotificationToToken(token, title, body, data);
  }

  // Send a notification to a specific device token
  Future<bool> sendNotificationToToken(
    String token,
    String title,
    String body,
    Map<String, dynamic>? data,
  ) async {
    try {
      // Get an access token
      final String accessToken = await _getAccessToken();

      // Create an extremely simple message structure that matches what works in the Firebase Console
      // This is the bare minimum needed for a notification to be delivered
      final Map<String, dynamic> message = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
        },
      };

      // Debug the request
      final String apiUrl = FirebaseConfig.fcmApiUrl;
      final String messageJson = jsonEncode(message);
      debugPrint('Sending FCM request to: $apiUrl');
      debugPrint(
          'FCM request headers: Content-Type: application/json, Authorization: Bearer ${accessToken.substring(0, 10)}...');
      debugPrint('FCM request body: $messageJson');

      // Send the message to FCM
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: messageJson,
      );

      // Debug the response
      debugPrint('FCM response status code: ${response.statusCode}');
      debugPrint('FCM response body: ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('Successfully sent notification to FCM');
        return true;
      } else {
        debugPrint(
            'FCM returned status code ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending notification to device: $e');
      return false;
    }
  }

  // Send a notification to multiple devices
  Future<bool> sendNotificationToDevices({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (tokens.isEmpty) {
      debugPrint('No tokens provided');
      return false;
    }

    bool anySuccess = false;

    // Send a notification to each device
    for (final token in tokens) {
      final success = await sendNotificationToDevice(
        token: token,
        title: title,
        body: body,
        data: data,
      );

      if (success) {
        anySuccess = true;
      }
    }

    return anySuccess;
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';

import '../config/firebase_config.dart';

class FirebaseCloudMessagingV1 {
  static final FirebaseCloudMessagingV1 _instance = FirebaseCloudMessagingV1._internal();
  
  factory FirebaseCloudMessagingV1() {
    return _instance;
  }
  
  FirebaseCloudMessagingV1._internal();
  
  // Get an access token for the FCM API
  Future<String> _getAccessToken() async {
    try {
      // Load the service account key file
      final String serviceAccountJson = await rootBundle.loadString(FirebaseConfig.serviceAccountKeyPath);
      
      // Parse the service account key
      final Map<String, dynamic> serviceAccountData = jsonDecode(serviceAccountJson);
      
      // Create a service account credentials object
      final serviceAccountCredentials = ServiceAccountCredentials.fromJson(serviceAccountData);
      
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
    try {
      // Get an access token
      final String accessToken = await _getAccessToken();
      
      // Create the FCM message
      final Map<String, dynamic> message = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
        },
      };
      
      // Send the message to FCM
      final response = await http.post(
        Uri.parse(FirebaseConfig.fcmApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );
      
      if (response.statusCode == 200) {
        debugPrint('Successfully sent notification to FCM');
        return true;
      } else {
        debugPrint('FCM returned status code ${response.statusCode}: ${response.body}');
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

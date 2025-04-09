class FirebaseConfig {
  // Firebase Cloud Messaging API (v1) configuration

  // The URL for the FCM v1 API
  static const String fcmApiUrl =
      'https://fcm.googleapis.com/v1/projects/callgeotracking/messages:send';

  // The path to your service account key file
  // This should be stored securely and not in version control
  static const String serviceAccountKeyPath = 'assets/service_account_key.json';
}

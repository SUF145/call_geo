# Firebase Setup Guide for Call Geo App

## Issue Identified

We've identified that the Firebase Cloud Messaging (FCM) implementation is not working correctly because the Firebase project has not been properly set up. The error message indicates that the Firebase Installations Service is unavailable.

## Steps to Fix

1. **Create a Firebase Project**:
   - Go to the [Firebase Console](https://console.firebase.google.com/)
   - Click "Add project"
   - Enter a name for your project (e.g., "Call Geo App")
   - Follow the prompts to complete the setup

2. **Register Your Android App**:
   - In the Firebase Console, click on your project
   - Click the Android icon to add an Android app
   - Enter the package name: `com.example.call_geo`
   - Enter a nickname (optional)
   - Register the app

3. **Download the Configuration File**:
   - Download the `google-services.json` file
   - Place it in the `android/app` directory of your Flutter project

4. **Update the Firebase Configuration**:
   - Open the `lib/config/firebase_config.dart` file
   - Replace the placeholder FCM server key with the actual server key from the Firebase Console
   - You can find the server key in the Firebase Console under Project Settings > Cloud Messaging

5. **Test the Implementation**:
   - Run the app on two different devices
   - Log in as a user on one device and as an admin on the other
   - Set up a geofence for the user
   - Move the user device outside the geofence area
   - Verify that both the user and admin receive notifications

## Troubleshooting

If you continue to experience issues:

1. **Check the Firebase Console**:
   - Make sure your app is properly registered
   - Verify that the package name matches your app's package name
   - Check that the SHA-1 certificate fingerprint is correct

2. **Verify the `google-services.json` File**:
   - Make sure the file is in the correct location (`android/app`)
   - Check that the file contains the correct package name and other details

3. **Check the Logs**:
   - Look for any Firebase-related errors in the logs
   - Pay attention to any authentication or initialization errors

4. **Test with a Simple Notification**:
   - Use the Firebase Console to send a test notification to your app
   - This can help verify that the basic FCM setup is working

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)
- [Supabase Documentation](https://supabase.io/docs)

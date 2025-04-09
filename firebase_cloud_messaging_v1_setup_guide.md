# Firebase Cloud Messaging API (v1) Setup Guide

This guide provides instructions for setting up Firebase Cloud Messaging (FCM) using the newer HTTP v1 API to enable cross-device notifications in the Call Geo app.

## Overview

The app has been updated to support sending notifications from a user's device to an admin's device when the user leaves their geofence area. This functionality uses the Firebase Cloud Messaging API (v1), which is the recommended approach as the legacy FCM server key method is deprecated.

## Prerequisites

1. A Google account
2. Access to the Firebase Console (https://console.firebase.google.com/)
3. Access to the Google Cloud Console (https://console.cloud.google.com/)

## Step 1: Create a Firebase Project

1. Go to the Firebase Console (https://console.firebase.google.com/)
2. Click "Add project"
3. Enter a project name (e.g., "Call Geo App")
4. Follow the prompts to set up the project
5. Once the project is created, click "Continue"

## Step 2: Add Android App to Firebase Project

1. In the Firebase Console, select your project
2. Click the Android icon to add an Android app
3. Enter the package name: `com.example.call_geo`
4. Enter a nickname (optional)
5. Click "Register app"

## Step 3: Download and Add Configuration Files

1. Download the `google-services.json` file
2. Place the file in the `android/app` directory of your Flutter project
3. Make sure the file is properly added to your version control system

## Step 4: Enable the Firebase Cloud Messaging API

1. Go to the Google Cloud Console (https://console.cloud.google.com/)
2. Select your Firebase project
3. Navigate to "APIs & Services" > "Library"
4. Search for "Firebase Cloud Messaging API"
5. Click on it and then click "Enable"

## Step 5: Create a Service Account

1. In the Google Cloud Console, navigate to "IAM & Admin" > "Service Accounts"
2. Click "Create Service Account"
3. Enter a name for the service account (e.g., "FCM Service Account")
4. Click "Create and Continue"
5. Assign the "Firebase Admin SDK Administrator Service Agent" role to the service account
6. Click "Continue" and then "Done"

## Step 6: Generate a Service Account Key

1. In the Service Accounts list, find the service account you just created
2. Click the three dots in the "Actions" column and select "Manage keys"
3. Click "Add Key" > "Create new key"
4. Select "JSON" as the key type
5. Click "Create"
6. The key file will be downloaded to your computer

## Step 7: Add the Service Account Key to Your Project

1. Rename the downloaded key file to `service_account_key.json`
2. Place the file in the `assets` directory of your Flutter project
3. Make sure the file is referenced in your `pubspec.yaml` file:
   ```yaml
   assets:
     - assets/service_account_key.json
   ```
4. **Important**: Do not commit this file to version control as it contains sensitive credentials

## Step 8: Update the Firebase Configuration

1. Open the `lib/config/firebase_config.dart` file
2. Replace the placeholder project ID with your actual Firebase project ID:
   ```dart
   static const String fcmApiUrl = 'https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send';
   ```

## Step 9: Create Supabase Table for Device Tokens

Run the following SQL in the Supabase SQL Editor to create a table for storing device tokens:

```sql
-- Create a table for storing device tokens
CREATE TABLE IF NOT EXISTS device_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  device_type TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, token)
);

-- Create an index on user_id for faster lookups
CREATE INDEX IF NOT EXISTS device_tokens_user_id_idx ON device_tokens(user_id);

-- Enable RLS
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can insert their own device tokens"
  ON device_tokens FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own device tokens"
  ON device_tokens FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own device tokens"
  ON device_tokens FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own device tokens"
  ON device_tokens FOR SELECT
  USING (auth.uid() = user_id);

-- Allow admins to view all device tokens
CREATE POLICY "Admins can view all device tokens"
  ON device_tokens FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
    )
  );
```

## Step 10: Test the Implementation

1. Run the app on two different devices
2. Log in as a user on one device and as an admin on the other
3. Set up a geofence for the user
4. Move the user device outside the geofence area
5. Verify that both the user and admin receive notifications

## Troubleshooting

If you encounter any issues with Firebase Cloud Messaging:

1. **Check the Service Account Key**:
   - Make sure the service account key file is correctly placed in the assets directory
   - Verify that the service account has the necessary permissions

2. **Check the Firebase Project Configuration**:
   - Make sure your app is properly registered in Firebase
   - Verify that the package name matches your app's package name

3. **Check the FCM API**:
   - Make sure the Firebase Cloud Messaging API is enabled in the Google Cloud Console
   - Check the logs for any API-related errors

4. **Check the Device Tokens**:
   - Verify that device tokens are being saved to the Supabase database
   - Check that the tokens are being correctly retrieved when sending notifications

5. **Test with a Simple Notification**:
   - Use the Firebase Console to send a test notification to your app
   - This can help verify that the basic FCM setup is working

## Additional Resources

- [Firebase Cloud Messaging API (v1) Documentation](https://firebase.google.com/docs/cloud-messaging/migrate-v1)
- [Google Cloud Authentication Documentation](https://cloud.google.com/docs/authentication)
- [Flutter Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)
- [Supabase Documentation](https://supabase.io/docs)

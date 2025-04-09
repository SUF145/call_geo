# Firebase Cloud Messaging Setup Instructions

This document provides instructions for setting up Firebase Cloud Messaging (FCM) to enable cross-device notifications in the Call Geo app.

## Overview

The app has been updated to support sending notifications from a user's device to an admin's device when the user leaves their geofence area. This functionality requires Firebase Cloud Messaging to be properly set up.

## Prerequisites

1. A Google account
2. Access to the Firebase Console (https://console.firebase.google.com/)

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

## Step 4: Update Gradle Files

The app's Gradle files have already been updated to include the necessary Firebase dependencies. However, if you encounter any issues, ensure the following configurations are in place:

### Project-level build.gradle (`android/build.gradle`):

```gradle
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    
    dependencies {
        // Add the Google services Gradle plugin
        classpath 'com.google.gms:google-services:4.4.1'
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

### App-level build.gradle (`android/app/build.gradle`):

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"
}

dependencies {
    implementation 'com.google.android.gms:play-services-location:21.0.1'
    implementation 'androidx.core:core:1.12.0'
    
    // Firebase dependencies
    implementation platform('com.google.firebase:firebase-bom:32.7.4')
    implementation 'com.google.firebase:firebase-messaging'
    implementation 'com.google.firebase:firebase-analytics'
}
```

## Step 5: Update AndroidManifest.xml

The app's AndroidManifest.xml has already been updated to include the necessary Firebase service. Ensure the following service is declared:

```xml
<!-- Firebase Cloud Messaging Service -->
<service
    android:name=".services.MyFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

## Step 6: Create Supabase Table for Device Tokens

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

## Step 7: Set Up Firebase Cloud Messaging on the Server Side

To send notifications from one device to another, you'll need a server component. For a simple implementation, you can use Firebase Cloud Functions or a custom server. Here's a basic example of a Firebase Cloud Function:

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.sendNotificationToAdmin = functions.https.onCall(async (data, context) => {
  // Ensure the user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { adminId, title, message, userId } = data;

  // Get the admin's device tokens
  const tokensSnapshot = await admin.firestore().collection('device_tokens')
    .where('user_id', '==', adminId)
    .get();

  if (tokensSnapshot.empty) {
    throw new functions.https.HttpsError('not-found', 'No device tokens found for admin');
  }

  // Send a notification to each of the admin's devices
  const tokens = tokensSnapshot.docs.map(doc => doc.data().token);
  
  const payload = {
    data: {
      title: title,
      message: message,
      is_admin_notification: 'true',
      user_id: userId || '',
    }
  };

  try {
    const response = await admin.messaging().sendToDevice(tokens, payload);
    return { success: true, results: response.results };
  } catch (error) {
    throw new functions.https.HttpsError('internal', 'Error sending notification', error);
  }
});
```

## Step 8: Test the Implementation

1. Run the app on two different devices
2. Log in as a user on one device and as an admin on the other
3. Set up a geofence for the user
4. Move the user device outside the geofence area
5. Verify that the admin device receives a notification

## Troubleshooting

If you encounter any issues with Firebase Cloud Messaging:

1. Check that the `google-services.json` file is correctly placed in the `android/app` directory
2. Ensure that the Firebase project is properly set up and the app is registered
3. Verify that the device token is being saved to the Supabase database
4. Check the logs for any errors related to Firebase initialization or messaging

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)
- [Supabase Documentation](https://supabase.io/docs)

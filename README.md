# Call & Geo App

A Flutter mobile app with Supabase authentication, call recording simulation, and geo tracking features.

## Features

### Authentication
- Sign up with full name, email, and password
- Sign in with email and password
- Secure authentication using Supabase

### Call Recording
- Permission handling for microphone and storage
- Call recording simulation (for demo purposes)
- Enable/disable call recording

### Geo Tracking
- Background location tracking
- Location updates every minute
- Location history view
- Clear location history

## Setup Instructions

### 1. Supabase Setup

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Run the SQL script in `supabase_setup.sql` in the SQL Editor
3. Get your Supabase URL and anon key from the API settings
4. Update the values in `lib/services/supabase_service.dart`

### 2. Flutter Setup

1. Make sure you have Flutter installed
2. Run `flutter pub get` to install dependencies
3. Connect a device or start an emulator
4. Run `flutter run` to start the app

## Background Location Tracking

The app implements background location tracking that:
- Captures the user's location every minute
- Stores the location data in Supabase
- Continues to work when the app is in the background or killed

## Important Notes

- For real call recording functionality, additional platform-specific setup would be required
- Background location tracking requires specific permissions on both Android and iOS
- Make sure to update the Android and iOS configuration files for proper permissions

## Android Configuration

Add the following permissions to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

## iOS Configuration

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location when open.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to location when in the background.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to microphone for call recording.</string>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
</array>
```

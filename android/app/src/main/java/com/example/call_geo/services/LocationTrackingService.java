package com.example.call_geo.services;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.location.Location;
import android.os.Build;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import com.example.call_geo.MainActivity;
import com.example.call_geo.R;
import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationRequest;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.location.Priority;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.embedding.engine.plugins.shim.ShimPluginRegistry;
import io.flutter.view.FlutterCallbackInformation;
import io.flutter.view.FlutterMain;

public class LocationTrackingService extends Service {
    private static final String TAG = "LocationTrackingService";
    private static final String CHANNEL_ID = "LocationTrackingServiceChannel";
    private static final int NOTIFICATION_ID = 1;

    private FusedLocationProviderClient fusedLocationClient;
    private LocationCallback locationCallback;
    private LocationRequest locationRequest;

    // For Flutter background execution
    private static MethodChannel backgroundChannel;
    private static FlutterEngine backgroundEngine;
    private static long callbackHandle = 0;

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "onCreate: LocationTrackingService started");

        createNotificationChannel();
        startForeground(NOTIFICATION_ID, createNotification());

        setupLocationTracking();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Log.d(TAG, "onStartCommand: LocationTrackingService");

        if (intent != null && intent.hasExtra("callbackHandle")) {
            callbackHandle = intent.getLongExtra("callbackHandle", 0);
            Log.d(TAG, "Received callback handle: " + callbackHandle);

            if (backgroundEngine == null) {
                startBackgroundIsolate();
            }
        }

        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "onDestroy: LocationTrackingService");

        if (fusedLocationClient != null && locationCallback != null) {
            fusedLocationClient.removeLocationUpdates(locationCallback);
        }
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel serviceChannel = new NotificationChannel(
                    CHANNEL_ID,
                    "Location Tracking Service",
                    NotificationManager.IMPORTANCE_LOW
            );
            serviceChannel.setDescription("Used for tracking your location in the background");
            serviceChannel.setShowBadge(false);

            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(serviceChannel);
            }
        }
    }

    private Notification createNotification() {
        Intent notificationIntent = new Intent(this, MainActivity.class);
        PendingIntent pendingIntent = PendingIntent.getActivity(
                this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE);

        return new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Location Tracking Active")
                .setContentText("Your location is being tracked in the background")
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build();
    }

    private void setupLocationTracking() {
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this);

        locationRequest = new LocationRequest.Builder(60000) // 60 seconds interval
                .setPriority(Priority.PRIORITY_HIGH_ACCURACY)
                .setMinUpdateIntervalMillis(30000) // 30 seconds minimum
                .build();

        locationCallback = new LocationCallback() {
            @Override
            public void onLocationResult(LocationResult locationResult) {
                if (locationResult == null) {
                    return;
                }

                for (Location location : locationResult.getLocations()) {
                    Log.d(TAG, "Location update: " + location.getLatitude() + ", " + location.getLongitude());
                    sendLocationToFlutter(location);
                }
            }
        };

        try {
            fusedLocationClient.requestLocationUpdates(
                    locationRequest, locationCallback, Looper.getMainLooper());
        } catch (SecurityException e) {
            Log.e(TAG, "Lost location permission: " + e.getMessage());
        }
    }

    private void startBackgroundIsolate() {
        if (backgroundEngine != null) {
            return;
        }

        FlutterMain.ensureInitializationComplete(getApplicationContext(), null);
        FlutterCallbackInformation callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle);
        if (callbackInfo == null) {
            Log.e(TAG, "Callback handle not found");
            return;
        }

        backgroundEngine = new FlutterEngine(this);

        // Register plugins used by the background service
        new ShimPluginRegistry(backgroundEngine).registrarFor("plugins.flutter.io/path_provider");

        // Start executing Dart code in the background
        backgroundEngine.getDartExecutor().executeDartCallback(
                new DartExecutor.DartCallback(
                        getAssets(),
                        FlutterMain.findAppBundlePath(),
                        callbackInfo
                )
        );

        // Create a MethodChannel for communicating with Dart
        backgroundChannel = new MethodChannel(backgroundEngine.getDartExecutor().getBinaryMessenger(), "com.example.call_geo/location_background");
    }

    private void sendLocationToFlutter(Location location) {
        if (backgroundChannel == null) {
            Log.e(TAG, "Background channel not initialized");
            return;
        }

        Map<String, Object> locationData = new HashMap<>();
        locationData.put("latitude", location.getLatitude());
        locationData.put("longitude", location.getLongitude());
        locationData.put("accuracy", location.getAccuracy());
        locationData.put("altitude", location.getAltitude());
        locationData.put("speed", location.getSpeed());
        locationData.put("time", location.getTime());

        try {
            // Log the location data before sending it to Flutter
            Log.d(TAG, "Location update: " + location.getLatitude() + ", " + location.getLongitude());

            // Send the location data to Flutter
            backgroundChannel.invokeMethod("onLocationUpdate", locationData);
        } catch (Exception e) {
            Log.e(TAG, "Error sending location to Flutter: " + e.getMessage());
        }
    }
}

package com.example.call_geo.location

import android.app.Service
import android.content.Intent
import android.location.Location
import android.os.IBinder
import android.os.Looper
import android.util.Log
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import java.util.concurrent.TimeUnit

/**
 * Enhanced location tracking service with spoofing detection capabilities.
 * This service extends your existing location tracking functionality with
 * comprehensive spoofing detection.
 */
class EnhancedLocationTrackingService : Service() {

    companion object {
        private const val TAG = "EnhancedLocationService"

        // Location request interval (1 minute)
        private val LOCATION_UPDATE_INTERVAL = TimeUnit.MINUTES.toMillis(1)

        // Fastest update interval (30 seconds)
        private val FASTEST_UPDATE_INTERVAL = TimeUnit.SECONDS.toMillis(30)
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private lateinit var locationCallback: LocationCallback
    private lateinit var spoofingDetector: LocationSpoofingDetector
    private lateinit var notificationHelper: SpoofingNotificationHelper

    // Flag to track if we've already shown a spoofing notification recently
    // This prevents spamming the user with notifications
    private var recentlySpoofingNotified = false
    private var lastNotificationTime = 0L

    // Minimum time between notifications (10 seconds)
    private val MIN_NOTIFICATION_INTERVAL = TimeUnit.SECONDS.toMillis(10)

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Enhanced location service created")

        // Initialize components
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
        spoofingDetector = LocationSpoofingDetector(this)
        notificationHelper = SpoofingNotificationHelper(this)

        // Create notification channel
        notificationHelper.createNotificationChannel()

        // Initialize location callback
        initLocationCallback()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Enhanced location service started")

        // Create a notification for the foreground service
        val notification = notificationHelper.createForegroundServiceNotification()

        // Start as a foreground service with notification
        startForeground(SpoofingNotificationHelper.FOREGROUND_SERVICE_ID, notification)

        // Start location updates
        startLocationUpdates()

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        stopLocationUpdates()
        Log.d(TAG, "Enhanced location service destroyed")
    }

    /**
     * Initializes the location callback to handle location updates.
     */
    private fun initLocationCallback() {
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    handleLocationUpdate(location)
                }
            }
        }
    }

    /**
     * Starts location updates with the specified interval.
     */
    private fun startLocationUpdates() {
        try {
            val locationRequest = LocationRequest.Builder(
                Priority.PRIORITY_HIGH_ACCURACY,
                LOCATION_UPDATE_INTERVAL
            )
                .setMinUpdateIntervalMillis(FASTEST_UPDATE_INTERVAL)
                .build()

            fusedLocationClient.requestLocationUpdates(
                locationRequest,
                locationCallback,
                Looper.getMainLooper()
            )

            Log.d(TAG, "Location updates started")
        } catch (e: SecurityException) {
            Log.e(TAG, "Location permission missing", e)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting location updates", e)
        }
    }

    /**
     * Stops location updates.
     */
    private fun stopLocationUpdates() {
        try {
            fusedLocationClient.removeLocationUpdates(locationCallback)
            Log.d(TAG, "Location updates stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping location updates", e)
        }
    }

    /**
     * Handles a new location update, including spoofing detection.
     */
    private fun handleLocationUpdate(location: Location) {
        Log.d(TAG, "Location update received: ${location.latitude}, ${location.longitude}")

        // Check for location spoofing
        val spoofingResult = spoofingDetector.checkLocationSpoofing(location)

        // Create location data with spoofing information
        val locationData = LocationData.fromLocation(location, spoofingResult)

        // Upload location data to your backend
        uploadLocationData(locationData)

        // If spoofing is detected, notify the user (with 10-second interval)
        if (spoofingResult.isSpoofingDetected) {
            Log.w(TAG, "Potential location spoofing detected: ${spoofingResult.reasons}")

            val currentTime = System.currentTimeMillis()
            if (!recentlySpoofingNotified ||
                (currentTime - lastNotificationTime > MIN_NOTIFICATION_INTERVAL)) {

                Log.d(TAG, "Showing spoofing notification with reasons: ${spoofingResult.reasons}")
                notificationHelper.showSpoofingDetectedNotification(spoofingResult.reasons)
                recentlySpoofingNotified = true
                lastNotificationTime = currentTime
            } else {
                Log.d(TAG, "Waiting to show next notification. Time since last: ${(currentTime - lastNotificationTime) / 1000} seconds")
            }
        } else {
            // Reset notification flag if no spoofing detected
            recentlySpoofingNotified = false
        }
    }

    /**
     * Uploads location data to your backend.
     * This is a placeholder - implement your actual upload logic here.
     */
    private fun uploadLocationData(locationData: LocationData) {
        // TODO: Replace with your actual implementation to upload to Supabase/Firebase
        Log.d(TAG, "Uploading location data: $locationData")

        // Example of what you might do:
        // if (locationData.potentiallySpoofed) {
        //     Log.w(TAG, "Uploading potentially spoofed location: ${locationData.spoofingReasons}")
        // }
        //
        // val database = FirebaseDatabase.getInstance().reference
        // database.child("locations").push().setValue(locationData.toMap())
        //   .addOnSuccessListener { Log.d(TAG, "Location uploaded successfully") }
        //   .addOnFailureListener { e -> Log.e(TAG, "Error uploading location", e) }
    }
}

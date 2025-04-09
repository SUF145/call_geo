package com.example.call_geo

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import com.example.call_geo.services.LocationTrackingService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val TAG = "MainActivity"
    private val LOCATION_CHANNEL = "com.example.call_geo/location"
    private val MAIN_CHANNEL = "com.example.call_geo/main"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Location service channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startLocationService" -> {
                    val callbackHandle = call.argument<Long>("callbackHandle")
                    val serviceStarted = startLocationService(callbackHandle)
                    result.success(serviceStarted)
                }
                "stopLocationService" -> {
                    val serviceStopped = stopLocationService()
                    result.success(serviceStopped)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Main channel for handling navigation from notifications
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MAIN_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startLocationService(callbackHandle: Long?): Boolean {
        return try {
            Log.d(TAG, "Starting location service with callback handle: $callbackHandle")
            val intent = Intent(this, LocationTrackingService::class.java)
            if (callbackHandle != null) {
                intent.putExtra("callbackHandle", callbackHandle)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error starting location service: ${e.message}")
            false
        }
    }

    private fun stopLocationService(): Boolean {
        return try {
            Log.d(TAG, "Stopping location service")
            val intent = Intent(this, LocationTrackingService::class.java)
            stopService(intent)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping location service: ${e.message}")
            false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Handle the intent that started this activity
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        // Handle the new intent
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent != null && intent.hasExtra("view_user_location")) {
            val viewUserLocation = intent.getBooleanExtra("view_user_location", false)
            val userId = intent.getStringExtra("user_id")

            if (viewUserLocation && userId != null) {
                Log.d(TAG, "Received intent to view user location: $userId")

                // Wait for Flutter engine to be ready before sending the navigation command
                // This is important for cold starts where the Flutter engine might not be ready yet
                try {
                    // Pass this information to Flutter when the engine is ready
                    if (flutterEngine != null) {
                        Log.d(TAG, "Flutter engine is ready, sending navigation command")
                        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, MAIN_CHANNEL)
                            .invokeMethod("navigateToUserLocation", userId)
                    } else {
                        Log.d(TAG, "Flutter engine not ready, will try again when it's ready")
                        // Store the intent data to process when the engine is ready
                        pendingUserId = userId
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending navigation command: ${e.message}")
                }
            }
        }
    }

    // Store pending user ID for navigation
    private var pendingUserId: String? = null

    override fun onResume() {
        super.onResume()

        // Check if we have a pending navigation request
        pendingUserId?.let { userId ->
            Log.d(TAG, "Processing pending navigation request for user: $userId")
            try {
                flutterEngine?.let { engine ->
                    MethodChannel(engine.dartExecutor.binaryMessenger, MAIN_CHANNEL)
                        .invokeMethod("navigateToUserLocation", userId)
                    pendingUserId = null
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error processing pending navigation: ${e.message}")
            }
        }
    }
}

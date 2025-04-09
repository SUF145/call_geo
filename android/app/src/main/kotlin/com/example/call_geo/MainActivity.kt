package com.example.call_geo

import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import com.example.call_geo.services.LocationTrackingService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val TAG = "MainActivity"
    private val CHANNEL = "com.example.call_geo/location"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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
}

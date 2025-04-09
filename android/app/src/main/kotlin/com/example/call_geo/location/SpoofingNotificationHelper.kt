package com.example.call_geo.location

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.call_geo.MainActivity
import com.example.call_geo.R

/**
 * Helper class to manage notifications related to location spoofing detection.
 */
class SpoofingNotificationHelper(private val context: Context) {

    companion object {
        private const val TAG = "SpoofingNotification"
        private const val CHANNEL_ID = "location_spoofing_channel"
        private const val FOREGROUND_CHANNEL_ID = "location_tracking_channel"
        private const val NOTIFICATION_ID = 12345
        const val FOREGROUND_SERVICE_ID = 54321
    }

    /**
     * Creates the notification channels for spoofing alerts and foreground service
     * (required for Android O and above).
     */
    fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Create spoofing alerts channel
            val alertsName = "Location Spoofing Alerts"
            val alertsDescription = "Notifications for potential location spoofing detection"
            val alertsImportance = NotificationManager.IMPORTANCE_HIGH
            val alertsChannel = NotificationChannel(CHANNEL_ID, alertsName, alertsImportance).apply {
                description = alertsDescription
            }
            notificationManager.createNotificationChannel(alertsChannel)

            // Create foreground service channel
            val serviceName = "Location Tracking Service"
            val serviceDescription = "Notifications for the location tracking service"
            val serviceImportance = NotificationManager.IMPORTANCE_LOW
            val serviceChannel = NotificationChannel(FOREGROUND_CHANNEL_ID, serviceName, serviceImportance).apply {
                description = serviceDescription
            }
            notificationManager.createNotificationChannel(serviceChannel)

            Log.d(TAG, "Notification channels created")
        }
    }

    /**
     * Shows a notification to the user about potential location spoofing.
     *
     * @param reasons List of reasons why spoofing was detected
     */
    fun showSpoofingDetectedNotification(reasons: List<LocationSpoofingDetector.SpoofingReason>) {
        try {
            // Create an intent to open the app when notification is tapped
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }

            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
            )

            // Create notification content based on detected reasons
            val contentText = buildNotificationContent(reasons)

            // Build the notification
            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification) // Make sure this icon exists in your project
                .setContentTitle("Location Spoofing Detected")
                .setContentText(contentText)
                .setStyle(NotificationCompat.BigTextStyle().bigText(contentText))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setContentIntent(pendingIntent)
                .setAutoCancel(true)

            // Show the notification
            with(NotificationManagerCompat.from(context)) {
                try {
                    notify(NOTIFICATION_ID, builder.build())
                    Log.d(TAG, "Spoofing notification shown")
                } catch (e: SecurityException) {
                    // Handle missing notification permission
                    Log.e(TAG, "No permission to show notification", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error showing notification", e)
        }
    }

    /**
     * Creates a notification for the foreground service.
     * This is required for Android O and above.
     *
     * @return The notification to display for the foreground service
     */
    fun createForegroundServiceNotification() = NotificationCompat.Builder(context, FOREGROUND_CHANNEL_ID)
        .setSmallIcon(R.drawable.ic_notification)
        .setContentTitle("Location Tracking Active")
        .setContentText("Enhanced location tracking with spoofing detection is running")
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .setOngoing(true)
        .setCategory(NotificationCompat.CATEGORY_SERVICE)
        .build()

    /**
     * Builds detailed notification content based on detected spoofing reasons.
     */
    private fun buildNotificationContent(reasons: List<LocationSpoofingDetector.SpoofingReason>): String {
        val baseMessage = "We've detected potential location spoofing. "

        if (reasons.isEmpty()) {
            return "$baseMessage Please ensure your location services are working properly."
        }

        val detailsBuilder = StringBuilder("Reasons: ")
        reasons.forEachIndexed { index, reason ->
            if (index > 0) detailsBuilder.append(", ")

            val reasonText = when (reason) {
                LocationSpoofingDetector.SpoofingReason.MOCK_LOCATION_ENABLED ->
                    "Mock location enabled in developer settings"
                LocationSpoofingDetector.SpoofingReason.FROM_MOCK_PROVIDER ->
                    "Location from mock provider"
                LocationSpoofingDetector.SpoofingReason.SPOOFING_APPS_INSTALLED ->
                    "Location spoofing apps detected"
                LocationSpoofingDetector.SpoofingReason.SPEED_ANOMALY ->
                    "Unusual movement speed detected"
                LocationSpoofingDetector.SpoofingReason.NETWORK_LOCATION_MISMATCH ->
                    "GPS and network locations don't match"
            }

            detailsBuilder.append(reasonText)
        }

        return "$baseMessage${detailsBuilder.toString()}"
    }
}

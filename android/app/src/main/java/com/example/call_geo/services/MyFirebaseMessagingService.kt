package com.example.call_geo.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.call_geo.MainActivity
import com.example.call_geo.R
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {
    private val TAG = "FirebaseMsgService"

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d(TAG, "NOTIFICATION RECEIVED: From: ${remoteMessage.from}")
        Log.d(TAG, "NOTIFICATION RECEIVED: Complete message: $remoteMessage")
        Log.d(TAG, "NOTIFICATION RECEIVED: Message ID: ${remoteMessage.messageId}")
        Log.d(TAG, "NOTIFICATION RECEIVED: Message Type: ${remoteMessage.messageType}")
        Log.d(TAG, "NOTIFICATION RECEIVED: Original Priority: ${remoteMessage.originalPriority}")
        Log.d(TAG, "NOTIFICATION RECEIVED: Priority: ${remoteMessage.priority}")
        Log.d(TAG, "NOTIFICATION RECEIVED: Sent Time: ${remoteMessage.sentTime}")
        Log.d(TAG, "NOTIFICATION RECEIVED: To: ${remoteMessage.to}")
        Log.d(TAG, "NOTIFICATION RECEIVED: TTL: ${remoteMessage.ttl}")
        Log.d(TAG, "NOTIFICATION RECEIVED: Data: ${remoteMessage.data}")

        // First check if message contains a notification payload (prioritize this)
        if (remoteMessage.notification != null) {
            val notification = remoteMessage.notification!!
            Log.d(TAG, "Message Notification Title: ${notification.title}")
            Log.d(TAG, "Message Notification Body: ${notification.body}")

            // Get any data that might be included with the notification
            val isAdminNotification = remoteMessage.data["is_admin_notification"]?.toString()?.equals("true", ignoreCase = true) ?: false
            val userId = remoteMessage.data["user_id"]

            Log.d(TAG, "Notification with data - Title: ${notification.title}, Body: ${notification.body}, isAdmin: $isAdminNotification, userId: $userId")

            // Show notification with high priority
            showNotification(notification.title ?: "Geofence Alert", notification.body ?: "A user has left their geofence area", isAdminNotification, userId)
        }
        // If no notification payload, check for data payload
        else if (remoteMessage.data.isNotEmpty()) {
            Log.d(TAG, "Message data payload only: ${remoteMessage.data}")

            val title = remoteMessage.data["title"] ?: "Geofence Alert"
            val message = remoteMessage.data["message"] ?: remoteMessage.data["body"] ?: "A user has left their geofence area"
            val isAdminNotification = remoteMessage.data["is_admin_notification"]?.toString()?.equals("true", ignoreCase = true) ?: false
            val userId = remoteMessage.data["user_id"]

            Log.d(TAG, "Parsed data only - Title: $title, Message: $message, isAdmin: $isAdminNotification, userId: $userId")

            // Show notification with high priority
            showNotification(title, message, isAdminNotification, userId)
        }
    }

    override fun onNewToken(token: String) {
        Log.d(TAG, "Refreshed token: $token")

        // Send the token to your server
        sendRegistrationToServer(token)
    }

    private fun sendRegistrationToServer(token: String) {
        // Implement this method to send token to your server
        // This will be handled by the Flutter app
        Log.d(TAG, "Sending FCM token to server: $token")

        // The Flutter app will retrieve this token using FirebaseMessaging.instance.getToken()
    }

    private fun showNotification(title: String, message: String, isAdminNotification: Boolean, userId: String?) {
        val channelId = "GeofenceAlertChannel"

        Log.d(TAG, "SHOWING NOTIFICATION - Title: $title, Message: $message, isAdmin: $isAdminNotification, userId: $userId")

        // Create notification channel for Android O and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Geofence Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alerts when users leave the allowed area"
                enableVibration(true)
                enableLights(true)
                lightColor = android.graphics.Color.RED
                setShowBadge(true)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                vibrationPattern = longArrayOf(0, 1000, 500, 1000)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)

            // Log all notification channels
            val channels = notificationManager.notificationChannels
            for (ch in channels) {
                Log.d(TAG, "Notification channel: ${ch.id}, name: ${ch.name}, importance: ${ch.importance}")
            }
        }

        // Create an intent to open the app when notification is tapped
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK

            // If this is an admin notification, add the user ID to the intent
            if (isAdminNotification && userId != null) {
                putExtra("view_user_location", true)
                putExtra("user_id", userId)
                Log.d(TAG, "Adding user ID to intent: $userId")
            }
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        // Build the notification
        val notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_MAX) // Use MAX priority for important alerts
            .setCategory(NotificationCompat.CATEGORY_ALARM) // Use ALARM category for important alerts
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setVibrate(longArrayOf(0, 1000, 500, 1000))
            .setDefaults(NotificationCompat.DEFAULT_ALL) // Use all default notification settings

        // Show the notification
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Use a unique notification ID for each notification to ensure they all show up
        val notificationId = if (isAdminNotification) {
            System.currentTimeMillis().toInt() // Use timestamp for admin notifications
        } else {
            2 // Use fixed ID for user notifications
        }

        Log.d(TAG, "Showing notification with ID: $notificationId")
        notificationManager.notify(notificationId, notificationBuilder.build())
    }
}

package com.example.call_geo.location

import android.location.Location
import java.util.Date

/**
 * Data class representing location information with spoofing detection details.
 * This can be used when uploading location data to your backend.
 */
data class LocationData(
    val latitude: Double,
    val longitude: Double,
    val accuracy: Float,
    val altitude: Double,
    val speed: Float,
    val bearing: Float,
    val timestamp: Long,
    val provider: String,
    val potentiallySpoofed: Boolean = false,
    val spoofingReasons: List<String> = emptyList()
) {
    companion object {
        /**
         * Creates a LocationData object from an Android Location object.
         */
        fun fromLocation(
            location: Location,
            spoofingResult: LocationSpoofingDetector.SpoofingCheckResult? = null
        ): LocationData {
            val spoofingReasons = spoofingResult?.reasons?.map { it.name } ?: emptyList()

            return LocationData(
                latitude = location.latitude,
                longitude = location.longitude,
                accuracy = location.accuracy,
                altitude = location.altitude,
                speed = location.speed,
                bearing = location.bearing,
                timestamp = location.time,
                provider = location.provider ?: "unknown",
                potentiallySpoofed = spoofingResult?.isSpoofingDetected ?: false,
                spoofingReasons = spoofingReasons
            )
        }
    }

    /**
     * Converts the LocationData to a Map that can be easily serialized for database upload.
     */
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "latitude" to latitude,
            "longitude" to longitude,
            "accuracy" to accuracy,
            "altitude" to altitude,
            "speed" to speed,
            "bearing" to bearing,
            "timestamp" to timestamp,
            "provider" to provider,
            "potentially_spoofed" to potentiallySpoofed,
            "spoofing_reasons" to spoofingReasons,
            "created_at" to Date().time
        )
    }
}

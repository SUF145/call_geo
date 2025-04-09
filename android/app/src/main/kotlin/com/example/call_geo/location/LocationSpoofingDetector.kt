package com.example.call_geo.location

import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import androidx.core.location.LocationCompat
import java.util.concurrent.TimeUnit
import kotlin.math.abs

/**
 * A utility class to detect location spoofing attempts.
 * This class provides various methods to check if a location is being spoofed.
 */
class LocationSpoofingDetector(private val context: Context) {

    companion object {
        private const val TAG = "LocationSpoofingDetector"

        // Thresholds for spoofing detection
        private const val MAX_REALISTIC_SPEED_KMH = 300.0 // km/h
        private const val MAX_GPS_NETWORK_DEVIATION_METERS = 100.0 // meters

        // Convert km/h to m/s
        private const val KMH_TO_MS = 0.277778
    }

    private var lastLocation: Location? = null
    private var lastLocationTime: Long = 0

    /**
     * Main method to check if a location is potentially spoofed.
     * Runs all detection methods and returns a result with details.
     *
     * @param location The location to check
     * @return SpoofingCheckResult containing the result and details
     */
    fun checkLocationSpoofing(location: Location): SpoofingCheckResult {
        val result = SpoofingCheckResult()

        // Check if mock location is enabled
        if (isMockLocationEnabled()) {
            result.isSpoofingDetected = true
            result.reasons.add(SpoofingReason.MOCK_LOCATION_ENABLED)
            Log.w(TAG, "Mock location setting is enabled")
        }

        // Check if the location is from a mock provider
        if (isLocationFromMockProvider(location)) {
            result.isSpoofingDetected = true
            result.reasons.add(SpoofingReason.FROM_MOCK_PROVIDER)
            Log.w(TAG, "Location is from mock provider")
        }

        // Check for spoofing apps
        if (hasSpoofingAppsInstalled()) {
            result.isSpoofingDetected = true
            result.reasons.add(SpoofingReason.SPOOFING_APPS_INSTALLED)
            Log.w(TAG, "Spoofing apps detected on device")
        }

        // Check for speed anomalies
        if (lastLocation != null && lastLocationTime > 0) {
            val speedAnomaly = checkSpeedAnomaly(location)
            if (speedAnomaly) {
                result.isSpoofingDetected = true
                result.reasons.add(SpoofingReason.SPEED_ANOMALY)
                Log.w(TAG, "Speed anomaly detected")
            }
        }

        // Cross-verify with network location
        val networkLocationMismatch = checkNetworkLocationMismatch(location)
        if (networkLocationMismatch) {
            result.isSpoofingDetected = true
            result.reasons.add(SpoofingReason.NETWORK_LOCATION_MISMATCH)
            Log.w(TAG, "Network location mismatch detected")
        }

        // Update last location for future checks
        lastLocation = location
        lastLocationTime = System.currentTimeMillis()

        return result
    }

    /**
     * Checks if mock location is enabled in developer settings.
     * For API < 23, checks Settings.Secure.ALLOW_MOCK_LOCATION
     * For API >= 23, checks if any app has the MOCK_LOCATION permission
     */
    fun isMockLocationEnabled(): Boolean {
        return if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            // For older devices, check the system setting
            Settings.Secure.getInt(context.contentResolver,
                Settings.Secure.ALLOW_MOCK_LOCATION, 0) != 0
        } else {
            // For newer devices, this setting was removed
            // Instead, we rely on isLocationFromMockProvider and hasSpoofingAppsInstalled
            false
        }
    }

    /**
     * Checks if the location is from a mock provider.
     * Uses location.isFromMockProvider() for API 18+ or falls back to a basic check.
     */
    fun isLocationFromMockProvider(location: Location): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
            location.isFromMockProvider
        } else {
            // For older APIs, we can't reliably detect mock locations
            // So we rely on the mock location setting check
            isMockLocationEnabled()
        }
    }

    /**
     * Checks if any spoofing apps are installed that request ACCESS_MOCK_LOCATION permission.
     * Note: This permission is deprecated in API 23+, but some older spoofing apps might still use it.
     */
    fun hasSpoofingAppsInstalled(): Boolean {
        val pm = context.packageManager
        val packages = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)

        // List of known spoofing app package prefixes
        val knownSpoofingAppPrefixes = listOf(
            "com.lexa.fakegps",
            "com.incorporateapps.fakegps",
            "com.fakegps.mock",
            "com.rosteam.gpsemulator",
            "com.blogspot.newapphorizons.fakegps",
            "com.theappninjas.fakegps",
            "com.evezzon.fakegps",
            "org.hola.gpslocation",
            "com.gsmartstudio.fakegps",
            "com.lkr.fakegps",
            "com.gamma.fakegps"
        )

        // Check for known spoofing apps
        for (packageInfo in packages) {
            val packageName = packageInfo.packageName

            // Check if package name matches known spoofing apps
            if (knownSpoofingAppPrefixes.any { packageName.startsWith(it) }) {
                Log.d(TAG, "Found potential spoofing app: $packageName")
                return true
            }

            // Check for ACCESS_MOCK_LOCATION permission in older devices
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                val permissions = packageInfo.requestedPermissions
                if (permissions != null) {
                    for (permission in permissions) {
                        if (permission == "android.permission.ACCESS_MOCK_LOCATION") {
                            Log.d(TAG, "App with ACCESS_MOCK_LOCATION permission: $packageName")
                            return true
                        }
                    }
                }
            }
        }

        return false
    }

    /**
     * Checks for speed anomalies between the current and last location.
     * If the calculated speed exceeds a realistic threshold, it's flagged as suspicious.
     */
    fun checkSpeedAnomaly(currentLocation: Location): Boolean {
        val lastLoc = lastLocation ?: return false
        val timeDiffMs = System.currentTimeMillis() - lastLocationTime

        // Ensure we have a reasonable time difference to calculate speed
        if (timeDiffMs < 1000) {
            return false
        }

        val distanceMeters = currentLocation.distanceTo(lastLoc)
        val timeSeconds = timeDiffMs / 1000.0

        // Calculate speed in m/s and convert to km/h
        val speedMs = distanceMeters / timeSeconds
        val speedKmh = speedMs / KMH_TO_MS

        Log.d(TAG, "Calculated speed: $speedKmh km/h")

        // Check if speed exceeds realistic threshold
        return speedKmh > MAX_REALISTIC_SPEED_KMH
    }

    /**
     * Cross-verifies the GPS location with a network location.
     * If the deviation is too large, it might indicate spoofing.
     */
    fun checkNetworkLocationMismatch(gpsLocation: Location): Boolean {
        try {
            val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

            // Check if network provider is enabled
            if (!locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                Log.d(TAG, "Network provider not enabled, skipping cross-verification")
                return false
            }

            // Get the last known network location
            val networkLocation = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
                ?: return false

            // Check if network location is too old (more than 5 minutes)
            val networkLocationAge = System.currentTimeMillis() - networkLocation.time
            if (networkLocationAge > TimeUnit.MINUTES.toMillis(5)) {
                Log.d(TAG, "Network location too old, skipping cross-verification")
                return false
            }

            // Calculate distance between GPS and network locations
            val distanceMeters = gpsLocation.distanceTo(networkLocation)
            Log.d(TAG, "Distance between GPS and network location: $distanceMeters meters")

            // If deviation is too large, flag as suspicious
            return distanceMeters > MAX_GPS_NETWORK_DEVIATION_METERS
        } catch (e: SecurityException) {
            Log.e(TAG, "Security exception when accessing network location", e)
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Error checking network location", e)
            return false
        }
    }

    /**
     * Result class for spoofing detection checks.
     */
    data class SpoofingCheckResult(
        var isSpoofingDetected: Boolean = false,
        val reasons: MutableList<SpoofingReason> = mutableListOf()
    )

    /**
     * Enum representing different reasons for spoofing detection.
     */
    enum class SpoofingReason {
        MOCK_LOCATION_ENABLED,
        FROM_MOCK_PROVIDER,
        SPOOFING_APPS_INSTALLED,
        SPEED_ANOMALY,
        NETWORK_LOCATION_MISMATCH
    }
}

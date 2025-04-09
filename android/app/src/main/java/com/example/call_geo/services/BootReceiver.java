package com.example.call_geo.services;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.util.Log;

public class BootReceiver extends BroadcastReceiver {
    private static final String TAG = "BootReceiver";
    private static final String PREFS_NAME = "LocationTrackingPrefs";
    private static final String KEY_TRACKING_ENABLED = "tracking_enabled";
    private static final String KEY_CALLBACK_HANDLE = "callback_handle";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent.getAction() == null) return;
        
        if (intent.getAction().equals(Intent.ACTION_BOOT_COMPLETED) ||
                intent.getAction().equals("android.intent.action.QUICKBOOT_POWERON")) {
            
            Log.d(TAG, "Boot completed, checking if location tracking was enabled");
            
            SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
            boolean trackingEnabled = prefs.getBoolean(KEY_TRACKING_ENABLED, false);
            long callbackHandle = prefs.getLong(KEY_CALLBACK_HANDLE, 0);
            
            if (trackingEnabled && callbackHandle != 0) {
                Log.d(TAG, "Restarting location tracking service after boot");
                
                Intent serviceIntent = new Intent(context, LocationTrackingService.class);
                serviceIntent.putExtra("callbackHandle", callbackHandle);
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent);
                } else {
                    context.startService(serviceIntent);
                }
            }
        }
    }
}

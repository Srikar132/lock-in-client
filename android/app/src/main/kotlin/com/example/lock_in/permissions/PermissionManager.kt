package com.example.lock_in.permissions

import android.app.Activity
import android.app.AppOpsManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationManagerCompat

class PermissionManager(private val activity: Activity) {

    companion object {
        private const val TAG = "PermissionManager"
        private const val USAGE_STATS_REQUEST_CODE = 1001
        private const val OVERLAY_REQUEST_CODE = 1002
        private const val ACCESSIBILITY_REQUEST_CODE = 1003
        private const val BACKGROUND_REQUEST_CODE = 1004
        private const val NOTIFICATION_REQUEST_CODE = 1005
    }

    // USAGE STATS PERMISSION
    fun hasUsageStatsPermission(): Boolean {
        return try {
            val appOps = activity.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    activity.packageName
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    android.os.Process.myUid(),
                    activity.packageName
                )
            }
            val granted = mode == AppOpsManager.MODE_ALLOWED
            Log.d(TAG, "Usage Stats Permission: $granted (mode: $mode)")
            granted
        } catch (e: Exception) {
            Log.e(TAG, "Error checking usage stats permission", e)
            false
        }
    }

    fun requestUsageStatsPermission() {
        try {
            Log.d(TAG, "Requesting Usage Stats Permission")
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.data = Uri.parse("package:${activity.packageName}")
            activity.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error with package-specific intent, trying general intent", e)
            try {
                val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                activity.startActivity(intent)
            } catch (ex: Exception) {
                Log.e(TAG, "Error requesting usage stats permission", ex)
            }
        }
    }

    // ACCESSIBILITY PERMISSION
    fun hasAccessibilityPermission(): Boolean {
        return try {
            val accessibilityEnabled = Settings.Secure.getInt(
                activity.contentResolver,
                Settings.Secure.ACCESSIBILITY_ENABLED,
                0
            )
            val granted = accessibilityEnabled == 1
            Log.d(TAG, "Accessibility Permission: $granted")
            granted
        } catch (e: Exception) {
            Log.e(TAG, "Error checking accessibility permission", e)
            false
        }
    }

    fun requestAccessibilityPermission() {
        try {
            Log.d(TAG, "Requesting Accessibility Permission")
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            activity.startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error requesting accessibility permission", e)
        }
    }

    // BACKGROUND PERMISSION (Battery Optimization Exemption)
    fun hasBackgroundPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val powerManager = activity.getSystemService(Context.POWER_SERVICE) as PowerManager
                val packageName = activity.packageName
                val granted = powerManager.isIgnoringBatteryOptimizations(packageName)
                
                Log.d(TAG, "Background Permission Check:")
                Log.d(TAG, "  - Android Version: ${Build.VERSION.SDK_INT} (${Build.VERSION.RELEASE})")
                Log.d(TAG, "  - Package Name: $packageName")
                Log.d(TAG, "  - Is Ignoring Battery Optimizations: $granted")
                
                granted
            } catch (e: Exception) {
                Log.e(TAG, "Error checking background permission", e)
                false
            }
        } else {
            Log.d(TAG, "Background permission not needed for Android version < M (API 23)")
            true // Permission not needed for older Android versions
        }
    }

    fun requestBackgroundPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                Log.d(TAG, "Requesting Background Permission (Battery Optimization Exemption)")
                
                // First, try the direct package-specific intent
                try {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    intent.data = Uri.parse("package:${activity.packageName}")
                    
                    Log.d(TAG, "Attempting to launch: ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS")
                    activity.startActivity(intent)
                    
                } catch (e: Exception) {
                    Log.w(TAG, "Direct battery optimization request failed, trying settings page", e)
                    
                    // If that fails, open the general battery optimization settings
                    val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                    Log.d(TAG, "Attempting to launch: ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS")
                    activity.startActivity(intent)
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Both battery optimization intents failed", e)
                
                // Last resort: try to open app info settings
                try {
                    Log.d(TAG, "Last resort: Opening app info settings")
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    intent.data = Uri.parse("package:${activity.packageName}")
                    activity.startActivity(intent)
                } catch (ex: Exception) {
                    Log.e(TAG, "Failed to open any settings page", ex)
                }
            }
        } else {
            Log.d(TAG, "Background permission not needed for Android version < M")
        }
    }

    // OVERLAY PERMISSION
    fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val granted = Settings.canDrawOverlays(activity)
            Log.d(TAG, "Overlay Permission: $granted")
            granted
        } else {
            Log.d(TAG, "Overlay permission not needed for Android version < M")
            true
        }
    }

    fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                Log.d(TAG, "Requesting Overlay Permission")
                val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                intent.data = Uri.parse("package:${activity.packageName}")
                activity.startActivity(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Error requesting overlay permission", e)
            }
        }
    }

    // NOTIFICATION PERMISSION
    fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val granted = NotificationManagerCompat.from(activity).areNotificationsEnabled()
            Log.d(TAG, "Notification Permission (API 33+): $granted")
            granted
        } else {
            val notificationManager = activity.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val granted = notificationManager.areNotificationsEnabled()
            Log.d(TAG, "Notification Permission: $granted")
            granted
        }
    }

    fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            try {
                Log.d(TAG, "Requesting Notification Permission (API 33+)")
                val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                intent.putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
                activity.startActivity(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Error requesting notification permission", e)
            }
        } else {
            try {
                Log.d(TAG, "Opening app details for notification settings")
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                intent.data = Uri.parse("package:${activity.packageName}")
                activity.startActivity(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Error opening app details", e)
            }
        }
    }

    // DISPLAY POPUP PERMISSION (same as overlay)
    fun hasDisplayPopupPermission(): Boolean {
        val granted = hasOverlayPermission()
        Log.d(TAG, "Display Popup Permission (same as overlay): $granted")
        return granted
    }

    fun requestDisplayPopupPermission() {
        Log.d(TAG, "Display Popup Permission request (redirecting to overlay)")
        requestOverlayPermission()
    }
}
package com.example.lock_in.utils

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

/**
 * Utility class for managing battery optimization settings to ensure 
 * LockIn accessibility service runs persistently in background
 */
class BatteryOptimizationUtils {
    
    companion object {
        private const val TAG = "BatteryOptimizationUtils"
        
        /**
         * Check if the app is whitelisted from battery optimizations
         */
        fun isIgnoringBatteryOptimizations(context: Context): Boolean {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                powerManager.isIgnoringBatteryOptimizations(context.packageName)
            } else {
                true // Battery optimization not available on older versions
            }
        }
        
        /**
         * Request user to disable battery optimization for this app
         */
        fun requestBatteryOptimizationExemption(context: Context): Intent? {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                try {
                    val intent = Intent().apply {
                        action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                        data = Uri.parse("package:${context.packageName}")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    
                    // Verify the intent can be resolved
                    if (intent.resolveActivity(context.packageManager) != null) {
                        Log.d(TAG, "✅ Battery optimization exemption intent available")
                        intent
                    } else {
                        Log.w(TAG, "⚠️ Battery optimization exemption not available on this device")
                        createFallbackBatteryIntent(context)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error creating battery optimization intent", e)
                    createFallbackBatteryIntent(context)
                }
            } else {
                null
            }
        }
        
        /**
         * Fallback to general battery optimization settings if direct exemption fails
         */
        private fun createFallbackBatteryIntent(context: Context): Intent? {
            return try {
                Intent().apply {
                    action = Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Fallback battery intent also failed", e)
                null
            }
        }
        
        /**
         * Check if battery optimization exemption should be requested
         */
        fun shouldRequestBatteryOptimization(context: Context): Boolean {
            return Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && 
                   !isIgnoringBatteryOptimizations(context)
        }
        
        /**
         * Get user-friendly message explaining battery optimization
         */
        fun getBatteryOptimizationMessage(): String {
            return """
                To ensure LockIn protection works reliably in the background:
                
                1. Tap 'Allow' on the next screen to disable battery optimization
                2. This prevents Android from stopping the protection service
                3. LockIn will continue blocking distracting content even when the app is closed
                
                This is required for persistent background protection.
            """.trimIndent()
        }
    }
}
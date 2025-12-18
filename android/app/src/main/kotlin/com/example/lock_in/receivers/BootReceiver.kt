package com.example.lock_in.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.example.lock_in.managers.FocusModeManager
import com.example.lock_in.workers.SessionWatchdogWorker
import androidx.work.*
import java.util.concurrent.TimeUnit
import android.provider.Settings

/**
 * BootReceiver - Restarts services after device reboot
 * 
 * Listens for BOOT_COMPLETED broadcast and restores:
 * - Active focus sessions
 * - Accessibility service status monitoring
 */
class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
        private const val ACCESSIBILITY_SERVICE_NAME = "com.example.lock_in/.services.LockInAccessibilityService"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            
            Log.i(TAG, "📱 Device booted or app updated - restoring LockIn services")
            
            try {
                // Check focus mode sessions
                val focusModeManager = FocusModeManager.getInstance(context)
                
                // Check if there was an active session before reboot
                if (focusModeManager.isActive()) {
                    Log.i(TAG, "Restoring active focus session")
                    // The session state is already in memory, services will auto-restart
                }
                
                // Check accessibility service status
                checkAccessibilityServiceStatus(context)
                
                // Schedule watchdog worker to monitor service health
                scheduleWatchdog(context)
                
            } catch (e: Exception) {
                Log.e(TAG, "Error handling boot completed", e)
            }
        }
    }
    
    private fun checkAccessibilityServiceStatus(context: Context) {
        try {
            val accessibilityEnabled = isAccessibilityServiceEnabled(context)
            
            if (accessibilityEnabled) {
                Log.d(TAG, "✅ LockIn Accessibility Service is enabled - protection will resume automatically")
            } else {
                Log.d(TAG, "⚠️ LockIn Accessibility Service is disabled - user needs to re-enable protection")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error checking accessibility service status", e)
        }
    }
    
    private fun isAccessibilityServiceEnabled(context: Context): Boolean {
        return try {
            val accessibilityEnabled = Settings.Secure.getInt(
                context.contentResolver,
                Settings.Secure.ACCESSIBILITY_ENABLED
            )
            
            if (accessibilityEnabled == 1) {
                val enabledServices = Settings.Secure.getString(
                    context.contentResolver,
                    Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                )
                
                enabledServices?.contains(ACCESSIBILITY_SERVICE_NAME) == true
            } else {
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking accessibility service", e)
            false
        }
    }
    
    /**
     * Schedule the watchdog worker
     */
    private fun scheduleWatchdog(context: Context) {
        val constraints = Constraints.Builder()
            .setRequiresBatteryNotLow(false)
            .build()
        
        val watchdogRequest = PeriodicWorkRequestBuilder<SessionWatchdogWorker>(
            15, TimeUnit.MINUTES
        )
            .setConstraints(constraints)
            .setInitialDelay(1, TimeUnit.MINUTES)
            .build()
        
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            SessionWatchdogWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            watchdogRequest
        )
        
        Log.i(TAG, "Watchdog worker scheduled")
    }
}

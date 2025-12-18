package com.example.lock_in.workers

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.lock_in.managers.FocusModeManager
import com.example.lock_in.services.AppMonitoringService

/**
 * SessionWatchdogWorker - Periodic worker that ensures services are running
 * 
 * This worker runs periodically to check if the monitoring service is still
 * alive during an active focus session. If not, it restarts the service.
 */
class SessionWatchdogWorker(
    context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {
    
    companion object {
        private const val TAG = "SessionWatchdog"
        const val WORK_NAME = "session_watchdog"
    }
    
    override suspend fun doWork(): Result {
        return try {
            Log.d(TAG, "Watchdog checking session health")
            
            val focusModeManager = FocusModeManager.getInstance(applicationContext)
            
            // Check if session is active
            if (focusModeManager.isActive()) {
                Log.i(TAG, "Focus session is active, verifying services")
                
                // Check if monitoring service is running
                if (!isServiceRunning(AppMonitoringService::class.java)) {
                    Log.w(TAG, "Monitoring service not running, restarting")
                    restartMonitoringService()
                } else {
                    Log.d(TAG, "Monitoring service is running correctly")
                }
            } else {
                Log.d(TAG, "No active focus session")
            }
            
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Watchdog error", e)
            Result.retry()
        }
    }
    
    /**
     * Check if a service is currently running
     */
    private fun isServiceRunning(serviceClass: Class<*>): Boolean {
        try {
            val manager = applicationContext.getSystemService(Context.ACTIVITY_SERVICE) 
                as android.app.ActivityManager
            
            @Suppress("DEPRECATION")
            for (service in manager.getRunningServices(Integer.MAX_VALUE)) {
                if (serviceClass.name == service.service.className) {
                    return true
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking if service is running", e)
        }
        return false
    }
    
    /**
     * Restart the monitoring service
     */
    private fun restartMonitoringService() {
        try {
            val intent = Intent(applicationContext, AppMonitoringService::class.java)
            applicationContext.startForegroundService(intent)
            Log.i(TAG, "Monitoring service restarted")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restart monitoring service", e)
        }
    }
}

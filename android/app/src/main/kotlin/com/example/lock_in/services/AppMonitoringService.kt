package com.example.lock_in.services

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.lock_in.MainActivity
import com.example.lock_in.managers.AppLimitManager
import com.example.lock_in.managers.FlutterOverlayManager
import com.example.lock_in.managers.FocusModeManager
import com.example.lock_in.managers.PermanentBlockManager
import com.example.lock_in.managers.ShortFormBlockManager
import kotlinx.coroutines.*

/**
 * AppMonitoringService - Foreground service that continuously monitors app usage
 * 
 * This service runs in the foreground with a persistent notification and checks
 * which app is currently in use. If a blocked app is detected, it triggers the overlay.
 */
class AppMonitoringService : Service() {
    
    companion object {
        private const val TAG = "AppMonitoringService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "focus_monitoring_channel"
        private const val MONITORING_INTERVAL_MS = 500L // Check every 500ms
    }
    
    private lateinit var focusModeManager: FocusModeManager
    private lateinit var appLimitManager: AppLimitManager
    private lateinit var overlayManager: FlutterOverlayManager
    private lateinit var permanentBlockManager: PermanentBlockManager
    private lateinit var shortFormBlockManager: ShortFormBlockManager
    
    private var serviceJob: Job? = null
    private val serviceScope = CoroutineScope(Dispatchers.Default + SupervisorJob())
    
    private var wakeLock: PowerManager.WakeLock? = null
    private var sessionId: String? = null
    
    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Service created")
        
        // Initialize managers
        focusModeManager = FocusModeManager.getInstance(applicationContext)
        appLimitManager = AppLimitManager.getInstance(applicationContext)
        overlayManager = FlutterOverlayManager.getInstance(applicationContext)
        permanentBlockManager = PermanentBlockManager.getInstance(applicationContext)
        shortFormBlockManager = ShortFormBlockManager.getInstance(applicationContext)
        
        // Acquire wake lock to keep CPU running
        acquireWakeLock()
        
        // Create notification channel
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.i(TAG, "Service started")
        
        sessionId = intent?.getStringExtra("SESSION_ID")
        
        // Start as foreground service
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // Start monitoring loop
        startMonitoring()
        
        return START_STICKY // Restart service if killed
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        super.onDestroy()
        Log.i(TAG, "Service destroyed")
        
        stopMonitoring()
        releaseWakeLock()
    }
    
    /**
     * Start the monitoring loop
     */
    private fun startMonitoring() {
        if (serviceJob?.isActive == true) {
            Log.w(TAG, "Monitoring already active")
            return
        }
        
        Log.i(TAG, "Starting monitoring loop")
        
        serviceJob = serviceScope.launch {
            while (isActive) {
                try {
                    checkCurrentApp()
                    delay(MONITORING_INTERVAL_MS)
                } catch (e: Exception) {
                    Log.e(TAG, "Error in monitoring loop", e)
                    delay(1000) // Wait a bit longer on error
                }
            }
        }
    }
    
    /**
     * Stop the monitoring loop
     */
    private fun stopMonitoring() {
        Log.i(TAG, "Stopping monitoring loop")
        serviceJob?.cancel()
        serviceScope.cancel()
    }
    
    /**
     * Check the current foreground app and block if necessary
     */
    private suspend fun checkCurrentApp() {
        // Check if focus session is active OR if there are permanent blocks
        val isFocusActive = focusModeManager.isActive()
        val hasPermanentBlocks = permanentBlockManager.getBlockedAppsCount() > 0
        
        if (!isFocusActive && !hasPermanentBlocks) {
            Log.d(TAG, "No active blocking, stopping service")
            withContext(Dispatchers.Main) {
                stopSelf()
            }
            return
        }
        
        val currentApp = appLimitManager.getCurrentForegroundApp()
        
        if (currentApp != null && currentApp != packageName) {
            var shouldBlock = false
            var blockReason = ""
            var isStrictMode = false
            
            // Check if app is blocked in focus session
            if (isFocusActive && appLimitManager.isAppBlocked(currentApp)) {
                shouldBlock = true
                blockReason = "This app is blocked during your focus session. Stay focused!"
                isStrictMode = focusModeManager.getSessionInfo()["strictMode"] as? Boolean ?: false
                Log.i(TAG, "Blocked app detected (focus session): $currentApp")
            }
            // Check if app is permanently blocked
            else if (permanentBlockManager.isAppBlocked(currentApp)) {
                shouldBlock = true
                blockReason = "This app is permanently blocked. Break the habit!"
                isStrictMode = true // Permanent blocks are always strict
                Log.i(TAG, "Blocked app detected (permanent): $currentApp")
            }
            // Check if app contains blocked short-form content
            else if (shortFormBlockManager.isPackageBlocked(currentApp)) {
                shouldBlock = true
                blockReason = "Short-form content is blocked. Focus on meaningful content!"
                isStrictMode = true
                Log.i(TAG, "Short-form content blocked: $currentApp")
            }
            
            if (shouldBlock) {
                // Get app name
                val appName = getAppName(currentApp)
                
                // Show blocking overlay on main thread
                withContext(Dispatchers.Main) {
                    overlayManager.showBlockingOverlay(
                        packageName = currentApp,
                        appName = appName,
                        message = blockReason,
                        isStrictMode = isStrictMode
                    )
                }
                
                // Track blocked attempt
                appLimitManager.trackAppUsage(currentApp, MONITORING_INTERVAL_MS)
            }
        }
    }
    
    /**
     * Get human-readable app name from package name
     */
    private fun getAppName(packageName: String): String {
        return try {
            val packageManager = applicationContext.packageManager
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            packageManager.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName // Fallback to package name
        }
    }
    
    /**
     * Create notification channel for Android O+
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Focus Session Active",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when a focus session is active"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    /**
     * Create the foreground service notification
     */
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🔒 Focus Mode Active")
            .setContentText("Lock-In is monitoring your apps")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
    
    /**
     * Acquire wake lock to keep CPU running
     */
    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "LockIn::AppMonitoringWakeLock"
            ).apply {
                acquire(10 * 60 * 1000L) // 10 minutes timeout
            }
            Log.i(TAG, "Wake lock acquired")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire wake lock", e)
        }
    }
    
    /**
     * Release wake lock
     */
    private fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                    Log.i(TAG, "Wake lock released")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to release wake lock", e)
        }
    }
}

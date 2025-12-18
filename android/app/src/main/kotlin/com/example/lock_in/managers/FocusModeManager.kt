package com.example.lock_in.managers

import android.content.Context
import android.content.Intent
import android.util.Log
import com.example.lock_in.permissions.PermissionManager
import com.example.lock_in.services.AppMonitoringService
import kotlinx.coroutines.*
import java.util.concurrent.atomic.AtomicBoolean

/**
 * FocusModeManager - Singleton orchestrator for the entire focus system
 * 
 * This is the single source of truth for focus session state and coordinates
 * all blocking services (app blocking, VPN, accessibility, notifications)
 */
class FocusModeManager private constructor(private val context: Context) {
    
    companion object {
        private const val TAG = "FocusModeManager"
        
        @Volatile
        private var instance: FocusModeManager? = null
        
        fun getInstance(context: Context): FocusModeManager {
            return instance ?: synchronized(this) {
                instance ?: FocusModeManager(context.applicationContext).also {
                    instance = it
                }
            }
        }
    }
    
    // Core managers
    val appLimitManager: AppLimitManager = AppLimitManager.getInstance(context)
    val overlayManager: FlutterOverlayManager = FlutterOverlayManager.getInstance(context)
    
    // Session state
    private val isSessionActive = AtomicBoolean(false)
    private var currentSessionId: String? = null
    private var blockedApps: Set<String> = emptySet()
    private var sessionStartTime: Long = 0
    private var plannedDuration: Int = 0 // in minutes
    private var strictMode: Boolean = false
    
    // Coroutine scope for async operations
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    /**
     * Start a focus session with specified parameters
     */
    fun startFocusSession(
        sessionId: String,
        blockedPackages: Set<String>,
        durationMinutes: Int,
        isStrict: Boolean = false,
        blockHomeScreen: Boolean = false
    ): Boolean {
        if (isSessionActive.get()) {
            Log.w(TAG, "Focus session already active")
            return false
        }
        
        // Note: Permissions should be verified by caller (MainActivity)
        // before calling this method
        
        Log.i(TAG, "Starting focus session: $sessionId")
        
        // Set session state
        currentSessionId = sessionId
        blockedApps = blockedPackages
        sessionStartTime = System.currentTimeMillis()
        plannedDuration = durationMinutes
        strictMode = isStrict
        isSessionActive.set(true)
        
        // Initialize managers
        appLimitManager.setBlockedApps(blockedPackages)
        overlayManager.setSessionActive(true)
        
        // Start monitoring service
        startMonitoringService()
        
        // Start VPN service if needed (for web blocking)
        // startVPNService()
        
        Log.i(TAG, "Focus session started successfully")
        return true
    }
    
    /**
     * Stop the current focus session
     */
    fun stopFocusSession(force: Boolean = false): Boolean {
        if (!isSessionActive.get()) {
            Log.w(TAG, "No active focus session to stop")
            return false
        }
        
        if (strictMode && !force) {
            Log.w(TAG, "Cannot stop session in strict mode without force")
            return false
        }
        
        Log.i(TAG, "Stopping focus session: $currentSessionId")
        
        // Stop all services
        stopMonitoringService()
        // stopVPNService()
        
        // Clear state
        isSessionActive.set(false)
        blockedApps = emptySet()
        appLimitManager.clearBlockedApps()
        overlayManager.setSessionActive(false)
        currentSessionId = null
        
        Log.i(TAG, "Focus session stopped")
        return true
    }
    
    /**
     * Check if a focus session is currently active
     */
    fun isActive(): Boolean = isSessionActive.get()
    
    /**
     * Get current session information
     */
    fun getSessionInfo(): Map<String, Any?> {
        return mapOf(
            "isActive" to isActive(),
            "sessionId" to currentSessionId,
            "blockedAppsCount" to blockedApps.size,
            "startTime" to sessionStartTime,
            "plannedDuration" to plannedDuration,
            "strictMode" to strictMode,
            "elapsedMinutes" to if (isActive()) {
                (System.currentTimeMillis() - sessionStartTime) / 60000
            } else 0
        )
    }
    
    /**
     * Check if a specific app is blocked
     */
    fun isAppBlocked(packageName: String): Boolean {
        return isSessionActive.get() && blockedApps.contains(packageName)
    }
    
    /**
     * Get list of blocked apps
     */
    fun getBlockedApps(): Set<String> = blockedApps.toSet()
    
    /**
     * Start the app monitoring foreground service
     */
    private fun startMonitoringService() {
        try {
            val intent = Intent(context, AppMonitoringService::class.java)
            intent.putExtra("SESSION_ID", currentSessionId)
            context.startForegroundService(intent)
            Log.i(TAG, "App monitoring service started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start monitoring service", e)
        }
    }
    
    /**
     * Stop the app monitoring service
     */
    private fun stopMonitoringService() {
        try {
            val intent = Intent(context, AppMonitoringService::class.java)
            context.stopService(intent)
            Log.i(TAG, "App monitoring service stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop monitoring service", e)
        }
    }
    
    /**
     * Clean up resources
     */
    fun cleanup() {
        scope.cancel()
        if (isActive()) {
            stopFocusSession(force = true)
        }
    }
}

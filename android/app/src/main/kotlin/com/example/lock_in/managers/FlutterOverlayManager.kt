package com.example.lock_in.managers

import android.content.Context
import android.content.Intent
import android.util.Log
import com.example.lock_in.activities.BlockOverlayActivity
import java.util.concurrent.atomic.AtomicBoolean

/**
 * FlutterOverlayManager - Manages when and how blocking overlays appear
 * 
 * Decides when to show the blocking screen and launches the overlay activity
 */
class FlutterOverlayManager private constructor(private val context: Context) {
    
    companion object {
        private const val TAG = "FlutterOverlayManager"
        
        @Volatile
        private var instance: FlutterOverlayManager? = null
        
        fun getInstance(context: Context): FlutterOverlayManager {
            return instance ?: synchronized(this) {
                instance ?: FlutterOverlayManager(context.applicationContext).also {
                    instance = it
                }
            }
        }
        
        // Intent extras
        const val EXTRA_BLOCKED_APP_NAME = "blocked_app_name"
        const val EXTRA_BLOCKED_APP_PACKAGE = "blocked_app_package"
        const val EXTRA_MESSAGE = "message"
        const val EXTRA_SESSION_END_TIME = "session_end_time"
        const val EXTRA_IS_STRICT_MODE = "is_strict_mode"
    }
    
    private val isSessionActive = AtomicBoolean(false)
    private var currentOverlayIntent: Intent? = null
    private var lastBlockedApp: String? = null
    private var lastBlockTime: Long = 0
    
    // Debounce overlay launches (prevent spam)
    private val OVERLAY_COOLDOWN_MS = 1000L
    
    /**
     * Set whether a focus session is currently active
     */
    fun setSessionActive(active: Boolean) {
        isSessionActive.set(active)
        if (!active) {
            dismissOverlay()
        }
    }
    
    /**
     * Show blocking overlay for a specific app
     */
    fun showBlockingOverlay(
        packageName: String,
        appName: String,
        message: String = "This app is blocked during your focus session",
        sessionEndTime: Long = 0,
        isStrictMode: Boolean = false
    ): Boolean {
        if (!isSessionActive.get()) {
            Log.w(TAG, "Cannot show overlay - session not active")
            return false
        }
        
        // Debounce - prevent showing overlay too frequently for same app
        val now = System.currentTimeMillis()
        if (packageName == lastBlockedApp && (now - lastBlockTime) < OVERLAY_COOLDOWN_MS) {
            Log.d(TAG, "Overlay on cooldown for $packageName")
            return false
        }
        
        try {
            Log.i(TAG, "Showing blocking overlay for: $appName ($packageName)")
            
            val intent = Intent(context, BlockOverlayActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                       Intent.FLAG_ACTIVITY_CLEAR_TOP or
                       Intent.FLAG_ACTIVITY_NO_HISTORY
                putExtra(EXTRA_BLOCKED_APP_NAME, appName)
                putExtra(EXTRA_BLOCKED_APP_PACKAGE, packageName)
                putExtra(EXTRA_MESSAGE, message)
                putExtra(EXTRA_SESSION_END_TIME, sessionEndTime)
                putExtra(EXTRA_IS_STRICT_MODE, isStrictMode)
            }
            
            context.startActivity(intent)
            currentOverlayIntent = intent
            lastBlockedApp = packageName
            lastBlockTime = now
            
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show blocking overlay", e)
            return false
        }
    }
    
    /**
     * Dismiss the current overlay (if any)
     */
    fun dismissOverlay() {
        currentOverlayIntent = null
        lastBlockedApp = null
        // Note: The actual dismissal is handled by the activity itself
        Log.d(TAG, "Overlay dismissed")
    }
    
    /**
     * Check if overlay is currently shown
     */
    fun isOverlayShown(): Boolean {
        return currentOverlayIntent != null
    }
    
    /**
     * Get the last blocked app
     */
    fun getLastBlockedApp(): String? = lastBlockedApp
}

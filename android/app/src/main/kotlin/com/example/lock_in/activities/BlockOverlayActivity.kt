package com.example.lock_in.activities

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import android.util.Log
import com.example.lock_in.MainActivity
import com.example.lock_in.managers.FlutterOverlayManager

/**
 * BlockOverlayActivity - Full-screen blocking overlay
 * 
 * This activity appears when a user tries to access a blocked app.
 * It prevents the user from using the app and encourages them to stay focused.
 */
class BlockOverlayActivity : Activity() {
    
    companion object {
        private const val TAG = "BlockOverlayActivity"
    }
    
    private var isStrictMode = false
    private var autoDismissMs: Long = 0
    private val handler = Handler(Looper.getMainLooper())
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.i(TAG, "BlockOverlayActivity created")
        
        // Make activity full-screen and show over lockscreen
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )
        
        // Extract data from intent
        val appName = intent.getStringExtra(FlutterOverlayManager.EXTRA_BLOCKED_APP_NAME) ?: "App"
        val message = intent.getStringExtra(FlutterOverlayManager.EXTRA_MESSAGE) 
            ?: intent.getStringExtra("MESSAGE")
            ?: "This app is blocked during your focus session"
        isStrictMode = intent.getBooleanExtra(FlutterOverlayManager.EXTRA_IS_STRICT_MODE, false)
            || intent.getBooleanExtra("IS_STRICT_MODE", false)
        autoDismissMs = intent.getLongExtra("AUTO_DISMISS_MS", 0L)
        
        // Handle auto-close from new intent extras
        val autoClose = intent.getBooleanExtra("AUTO_CLOSE", false)
        val autoCloseDelay = intent.getLongExtra("AUTO_CLOSE_DELAY", 3000L)
        
        if (autoClose && autoDismissMs == 0L) {
            autoDismissMs = autoCloseDelay
        }
        
        // Create simple layout programmatically
        setContentView(createBlockLayout(appName, message))
        
        // Set up auto-dismiss if specified
        if (autoDismissMs > 0) {
            handler.postDelayed({
                if (!isFinishing) {
                    Log.d(TAG, "Auto-dismissing overlay after ${autoDismissMs}ms")
                    finish()
                }
            }, autoDismissMs)
        }
    }
    
    /**
     * Create the blocking overlay layout
     */
    private fun createBlockLayout(appName: String, message: String): View {
        val layout = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setBackgroundColor(android.graphics.Color.parseColor("#1A1A1A"))
            setPadding(48, 48, 48, 48)
            gravity = android.view.Gravity.CENTER
        }
        
        // Lock icon (emoji)
        val iconText = TextView(this).apply {
            text = "🔒"
            textSize = 72f
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }
        
        // Blocked app name
        val titleText = TextView(this).apply {
            text = "$appName is Blocked"
            textSize = 28f
            setTextColor(android.graphics.Color.WHITE)
            gravity = android.view.Gravity.CENTER
            setPadding(0, 0, 0, 16)
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        
        // Message
        val messageText = TextView(this).apply {
            text = message
            textSize = 16f
            setTextColor(android.graphics.Color.parseColor("#B0B0B0"))
            gravity = android.view.Gravity.CENTER
            setPadding(32, 0, 32, 32)
        }
        
        // Motivational text
        val motivationText = TextView(this).apply {
            text = "Stay focused! You're doing great. 💪"
            textSize = 14f
            setTextColor(android.graphics.Color.parseColor("#82D65D"))
            gravity = android.view.Gravity.CENTER
            setPadding(32, 16, 32, 32)
        }
        
        // Return to Lock-In button
        val returnButton = Button(this).apply {
            text = if (isStrictMode) "Return to Lock-In" else "Go Back to Lock-In"
            textSize = 16f
            setBackgroundColor(android.graphics.Color.parseColor("#82D65D"))
            setTextColor(android.graphics.Color.parseColor("#1A1A1A"))
            setPadding(48, 32, 48, 32)
            setOnClickListener {
                returnToApp()
            }
        }
        
        // Add all views to layout
        layout.addView(iconText)
        layout.addView(titleText)
        layout.addView(messageText)
        layout.addView(motivationText)
        layout.addView(returnButton)
        
        return layout
    }
    
    /**
     * Return to the Lock-In app
     */
    private fun returnToApp() {
        Log.i(TAG, "Returning to Lock-In app")
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        startActivity(intent)
        finish()
    }
    
    /**
     * Handle back button - disabled in strict mode
     */
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK) {
            if (isStrictMode) {
                Log.d(TAG, "Back button disabled in strict mode")
                return true // Consume the event
            } else {
                returnToApp()
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }
    
    /**
     * Prevent activity from being dismissed easily
     */
    override fun onBackPressed() {
        if (!isStrictMode) {
            returnToApp()
        }
        // In strict mode, do nothing
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // Clean up handler to prevent memory leaks
        handler.removeCallbacksAndMessages(null)
    }
}

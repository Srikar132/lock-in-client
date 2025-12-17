package com.example.lock_in.services


import android.Manifest
import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import androidx.annotation.RequiresPermission
import com.lockin.focus.FocusModeManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject

/**
 * ShortFormBlockingService - Accessibility service for detecting and blocking short-form content
 * Blocks YouTube Shorts, Instagram Reels, TikTok, Facebook Reels, Snapchat Spotlight
 */
class ShortFormBlockingService : AccessibilityService() {

    companion object {
        private const val TAG = "ShortFormBlockingService"
        private const val PREFS_NAME = "short_form_blocks"

        // Broadcast actions
        private const val ACTION_UPDATE_BLOCKS = "com.lockin.focus.UPDATE_SHORT_FORM_BLOCKS"

        // Selectors for different platforms
        private val YOUTUBE_SHORTS_SELECTORS = listOf(
            "com.google.android.youtube:id/reel_player_page_container",
            "com.google.android.youtube:id/shorts_player",
            "com.google.android.youtube:id/reel_watch_while_activity",
            "com.google.android.youtube:id/shorts_lockup_overlay",
            "com.google.android.youtube:id/reel_dyn_remix"
        )

        private val INSTAGRAM_REELS_SELECTORS = listOf(
            "com.instagram.android:id/clips_viewer_view_pager",
            "com.instagram.android:id/reel_viewer_container",
            "com.instagram.android:id/clips_media_view",
            "com.instagram.android:id/clips_viewer_container",
            "com. instagram.android:id/reel_item_timer"
        )

        private val FACEBOOK_REELS_SELECTORS = listOf(
            "com.facebook.katana:id/video_player_container",
            "com.facebook.katana:id/reels_viewer",
            "com. facebook.katana:id/reel_composer_container"
        )

        private val SNAPCHAT_SPOTLIGHT_SELECTORS = listOf(
            "com.snapchat.android:id/spotlight_container",
            "com.snapchat.android:id/camera_preview_container"
        )

        /**
         * Static methods for external control
         */
        fun updateBlocks(context: Context, blocks: Map<String, Any>): Boolean {
            return try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().apply {
                    putString("blocks_config", JSONObject(blocks).toString())
                    apply()
                }

                // Send broadcast to update service
                val intent = Intent(ACTION_UPDATE_BLOCKS).apply {
                    putExtra("blocks", JSONObject(blocks).toString())
                }
                context.sendBroadcast(intent)

                Log.d(TAG, "Updated short form blocks configuration")
                true
            } catch (e: Exception) {
                Log.e(TAG, "Error updating blocks", e)
                false
            }
        }

        fun isServiceEnabled(context: Context): Boolean {
            val enabledServices = android.provider.Settings.Secure.getString(
                context. contentResolver,
                android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            return enabledServices?.contains(context.packageName) == true
        }

        fun openAccessibilitySettings(context: Context) {
            val intent = Intent(android.provider.Settings. ACTION_ACCESSIBILITY_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        }
    }

    // Core components
    private lateinit var focusManager: FocusModeManager
    private val handler = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // Blocking configuration
    private var shortFormBlocks = ShortFormBlocks()

    // Detection state
    private var lastDetectedContent = ""
    private var lastDetectionTime = 0L
    private val detectionCooldown = 2000L // 2 seconds

    // Configuration receiver
    private val configReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_UPDATE_BLOCKS) {
                val blocksJson = intent.getStringExtra("blocks")
                if (blocksJson != null) {
                    updateBlocksFromJson(blocksJson)
                }
            }
        }
    }

    @SuppressLint("UnspecifiedRegisterReceiverFlag")
    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "ShortFormBlockingService connected")

        try {
            // Initialize components
            focusManager = FocusModeManager.getInstance(this)

            // Configure accessibility service
            configureAccessibilityService()

            // Load configuration
            loadBlockConfiguration()

            // Register configuration receiver
            registerReceiver(configReceiver, IntentFilter(ACTION_UPDATE_BLOCKS))

            Log.d(TAG, "Service initialized successfully")

        } catch (e: Exception) {
            Log.e(TAG, "Error initializing service", e)
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "ShortFormBlockingService destroyed")
        try {
            unregisterReceiver(configReceiver)
            scope.cancel()
        } catch (e: Exception) {
            Log.e(TAG, "Error during cleanup", e)
        }
        super.onDestroy()
    }

    private fun configureAccessibilityService() {
        val info = AccessibilityServiceInfo().apply {
            // Event types we want to monitor
            eventTypes = AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                    AccessibilityEvent. TYPE_WINDOW_STATE_CHANGED or
                    AccessibilityEvent.TYPE_VIEW_SCROLLED or
                    AccessibilityEvent.TYPE_VIEW_CLICKED

            // Feedback type
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC

            // Flags
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS

            // Target packages
            packageNames = arrayOf(
                "com.google.android.youtube",    // YouTube
                "com.instagram.android",         // Instagram
                "com.facebook.katana",          // Facebook
                "com.zhiliaoapp.musically",     // TikTok
                "com.snapchat.android"          // Snapchat
            )

            // Notification timeout
            notificationTimeout = 100L
        }

        serviceInfo = info
    }

    @RequiresPermission(Manifest.permission.VIBRATE)
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!focusManager.isSessionActive() || event == null) return

        try {
            val packageName = event.packageName?.toString() ?: return

            // Debounce rapid events
            val currentTime = System.currentTimeMillis()
            val contentId = "$packageName:${event.eventType}"
            if (contentId == lastDetectedContent &&
                currentTime - lastDetectionTime < detectionCooldown) {
                return
            }

            when (packageName) {
                "com.google.android.youtube" -> {
                    if (shortFormBlocks.youtubeShorts) {
                        handleYouTubeShorts(event)
                    }
                }
                "com. instagram.android" -> {
                    if (shortFormBlocks.instagramReels) {
                        handleInstagramReels(event)
                    }
                }
                "com.facebook.katana" -> {
                    if (shortFormBlocks.facebookReels) {
                        handleFacebookReels(event)
                    }
                }
                "com.zhiliaoapp.musically" -> {
                    if (shortFormBlocks.tikTok) {
                        handleTikTok(event)
                    }
                }
                "com. snapchat.android" -> {
                    if (shortFormBlocks.snapchatSpotlight) {
                        handleSnapchatSpotlight(event)
                    }
                }
            }

            lastDetectedContent = contentId
            lastDetectionTime = currentTime

        } catch (e: Exception) {
            Log.e(TAG, "Error handling accessibility event", e)
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility service interrupted")
    }

    // ====================
    // PLATFORM-SPECIFIC HANDLERS
    // ====================

    @androidx.annotation.RequiresPermission(android.Manifest.permission.VIBRATE)
    private fun handleYouTubeShorts(event: AccessibilityEvent) {
        scope.launch {
            try {
                val source = event.source ?: return@launch

                if (isYouTubeShortsActive(source)) {
                    blockShortFormContent(
                        contentType = "YouTube Shorts",
                        packageName = "com.google.android.youtube",
                        educationalMessage = "YouTube Shorts are designed to be addictive with endless scrolling. Try watching educational videos or tutorials instead!",
                        actionType = "home"
                    )
                }

                source.recycle()

            } catch (e: Exception) {
                Log.e(TAG, "Error handling YouTube Shorts", e)
            }
        }
    }

    @androidx.annotation.RequiresPermission(android.Manifest.permission.VIBRATE)
    private fun handleInstagramReels(event: AccessibilityEvent) {
        scope.launch {
            try {
                val source = event.source ?: return@launch

                if (isInstagramReelsActive(source)) {
                    blockShortFormContent(
                        contentType = "Instagram Reels",
                        packageName = "com. instagram.android",
                        educationalMessage = "Instagram Reels can consume hours of your valuable time. Consider creating content, checking messages, or connecting with friends instead.",
                        actionType = "back_then_home"
                    )
                }

                source.recycle()

            } catch (e: Exception) {
                Log.e(TAG, "Error handling Instagram Reels", e)
            }
        }
    }

    @androidx.annotation.RequiresPermission(android.Manifest.permission.VIBRATE)
    private fun handleFacebookReels(event: AccessibilityEvent) {
        scope.launch {
            try {
                val source = event. source ?: return@launch

                if (isFacebookReelsActive(source)) {
                    blockShortFormContent(
                        contentType = "Facebook Reels",
                        packageName = "com.facebook.katana",
                        educationalMessage = "Facebook Reels can be a major distraction from your goals. Try connecting with friends, reading articles, or checking your groups instead.",
                        actionType = "back"
                    )
                }

                source.recycle()

            } catch (e:  Exception) {
                Log.e(TAG, "Error handling Facebook Reels", e)
            }
        }
    }

    @androidx.annotation.RequiresPermission(android.Manifest.permission.VIBRATE)
    private fun handleTikTok(event: AccessibilityEvent) {
        scope.launch {
            try {
                // TikTok is entirely short-form content, so block the whole app
                blockShortFormContent(
                    contentType = "TikTok",
                    packageName = "com.zhiliaoapp.musically",
                    educationalMessage = "TikTok's algorithm is designed to keep you scrolling for hours. Use this focus time for something more meaningful and productive!",
                    actionType = "home"
                )

            } catch (e: Exception) {
                Log.e(TAG, "Error handling TikTok", e)
            }
        }
    }

    @androidx.annotation.RequiresPermission(android.Manifest.permission.VIBRATE)
    private fun handleSnapchatSpotlight(event:  AccessibilityEvent) {
        scope.launch  {
            try {
                val source = event.source ?: return@launch

                if (isSnapchatSpotlightActive(source)) {
                    blockShortFormContent(
                        contentType = "Snapchat Spotlight",
                        packageName = "com.snapchat.android",
                        educationalMessage = "Snapchat Spotlight can break your focus flow. Consider sending messages to friends or taking photos instead of consuming content.",
                        actionType = "back"
                    )
                }

                source.recycle()

            } catch (e: Exception) {
                Log.e(TAG, "Error handling Snapchat Spotlight", e)
            }
        }
    }

    // ====================
    // DETECTION METHODS
    // ====================

    private fun isYouTubeShortsActive(source: AccessibilityNodeInfo): Boolean {
        try {
            // Method 1: Check for Shorts-specific UI elements
            for (selector in YOUTUBE_SHORTS_SELECTORS) {
                val nodes = source.findAccessibilityNodeInfosByViewId(selector)
                if (nodes.isNotEmpty()) {
                    Log.d(TAG, "YouTube Shorts detected via selector: $selector")
                    nodes.forEach { it.recycle() }
                    return true
                }
            }

            // Method 2: Check for "Shorts" text in the UI
            if (checkForTextInNode(source, listOf("Shorts", "shorts", "SHORT", "#Shorts"))) {
                Log.d(TAG, "YouTube Shorts detected via text content")
                return true
            }

            // Method 3: Check URL or activity indicators
            if (checkForShortsUrl(source)) {
                Log.d(TAG, "YouTube Shorts detected via URL pattern")
                return true
            }

            return false

        } catch (e: Exception) {
            Log.e(TAG, "Error detecting YouTube Shorts", e)
            return false
        }
    }

    private fun isInstagramReelsActive(source: AccessibilityNodeInfo): Boolean {
        try {
            // Method 1: Check for Reels-specific UI elements
            for (selector in INSTAGRAM_REELS_SELECTORS) {
                val nodes = source. findAccessibilityNodeInfosByViewId(selector)
                if (nodes.isNotEmpty()) {
                    Log.d(TAG, "Instagram Reels detected via selector: $selector")
                    nodes.forEach { it.recycle() }
                    return true
                }
            }

            // Method 2: Check for "Reels" text
            if (checkForTextInNode(source, listOf("Reels", "reels", "REELS", "clips_viewer"))) {
                Log.d(TAG, "Instagram Reels detected via text content")
                return true
            }

            // Method 3: Check for vertical video indicators
            if (checkForVerticalVideoIndicators(source, "instagram")) {
                Log.d(TAG, "Instagram Reels detected via video indicators")
                return true
            }

            return false

        } catch (e: Exception) {
            Log.e(TAG, "Error detecting Instagram Reels", e)
            return false
        }
    }

    private fun isFacebookReelsActive(source: AccessibilityNodeInfo): Boolean {
        try {
            // Method 1: Check for Reels-specific UI elements
            for (selector in FACEBOOK_REELS_SELECTORS) {
                val nodes = source.findAccessibilityNodeInfosByViewId(selector)
                if (nodes.isNotEmpty()) {
                    Log.d(TAG, "Facebook Reels detected via selector: $selector")
                    nodes.forEach { it.recycle() }
                    return true
                }
            }

            // Method 2: Check for "Reels" text
            if (checkForTextInNode(source, listOf("Reels", "reels", "Watch", "Video"))) {
                // Additional validation for Facebook
                if (checkForTextInNode(source, listOf("Like", "Comment", "Share"))) {
                    Log.d(TAG, "Facebook Reels detected via text content")
                    return true
                }
            }

            return false

        } catch (e: Exception) {
            Log.e(TAG, "Error detecting Facebook Reels", e)
            return false
        }
    }

    private fun isSnapchatSpotlightActive(source: AccessibilityNodeInfo): Boolean {
        try {
            // Method 1: Check for Spotlight-specific UI elements
            for (selector in SNAPCHAT_SPOTLIGHT_SELECTORS) {
                val nodes = source.findAccessibilityNodeInfosByViewId(selector)
                if (nodes.isNotEmpty()) {
                    Log.d(TAG, "Snapchat Spotlight detected via selector: $selector")
                    nodes.forEach { it.recycle() }
                    return true
                }
            }

            // Method 2: Check for "Spotlight" or "Discover" text
            if (checkForTextInNode(source, listOf("Spotlight", "spotlight", "Discover", "discover"))) {
                Log.d(TAG, "Snapchat Spotlight detected via text content")
                return true
            }

            return false

        } catch (e:  Exception) {
            Log.e(TAG, "Error detecting Snapchat Spotlight", e)
            return false
        }
    }

    // ====================
    // HELPER DETECTION METHODS
    // ====================

    private fun checkForTextInNode(node: AccessibilityNodeInfo, keywords: List<String>): Boolean {
        try {
            // Check current node text
            node.text?.let { text ->
                keywords.forEach { keyword ->
                    if (text.contains(keyword, ignoreCase = true)) {
                        return true
                    }
                }
            }

            // Check current node content description
            node.contentDescription?.let { desc ->
                keywords. forEach { keyword ->
                    if (desc.contains(keyword, ignoreCase = true)) {
                        return true
                    }
                }
            }

            // Check children recursively (limit depth to prevent performance issues)
            return checkChildrenForText(node, keywords, 0, 3)

        } catch (e: Exception) {
            Log.e(TAG, "Error checking text in node", e)
            return false
        }
    }

    private fun checkChildrenForText(
        node: AccessibilityNodeInfo,
        keywords: List<String>,
        currentDepth: Int,
        maxDepth: Int
    ): Boolean {
        if (currentDepth >= maxDepth) return false

        try {
            for (i in 0 until node.childCount) {
                val child = node.getChild(i) ?: continue

                try {
                    // Check child text
                    child.text?.let { text ->
                        keywords.forEach { keyword ->
                            if (text.contains(keyword, ignoreCase = true)) {
                                return true
                            }
                        }
                    }

                    // Check child content description
                    child.contentDescription?.let { desc ->
                        keywords.forEach { keyword ->
                            if (desc.contains(keyword, ignoreCase = true)) {
                                return true
                            }
                        }
                    }

                    // Recursively check grandchildren
                    if (checkChildrenForText(child, keywords, currentDepth + 1, maxDepth)) {
                        return true
                    }

                } finally {
                    child.recycle()
                }
            }

            return false

        } catch (e:  Exception) {
            Log.e(TAG, "Error checking children for text", e)
            return false
        }
    }

    private fun checkForShortsUrl(source: AccessibilityNodeInfo): Boolean {
        // This is a simplified version - in practice, you might need to check
        // specific UI elements that contain URL information
        return checkForTextInNode(source, listOf("/shorts/", "shorts?", "youtube.com/shorts"))
    }

    private fun checkForVerticalVideoIndicators(source: AccessibilityNodeInfo, platform: String): Boolean {
        // Check for common vertical video UI patterns
        val indicators = when (platform) {
            "instagram" -> listOf("Full Screen", "Swipe up", "Double tap")
            "facebook" -> listOf("Tap to pause", "Swipe up", "Full screen")
            else -> listOf("Swipe", "Tap", "Full")
        }

        return checkForTextInNode(source, indicators)
    }

    // ====================
    // BLOCKING ACTION
    // ====================

    @RequiresPermission(Manifest.permission.VIBRATE)
    private suspend fun blockShortFormContent(
        contentType: String,
        packageName: String,
        educationalMessage: String,
        actionType: String
    ) {
        withContext(Dispatchers.Main) {
            try {
                Log.d(TAG, "Blocking short-form content:  $contentType")

                // Get focus time
                val focusTimeMinutes = getFocusTimeMinutes()

                // Show Flutter overlay
                FlutterOverlayManager.showBlockedShortsOverlay(
                    context = this@ShortFormBlockingService,
                    contentType = contentType,
                    packageName = packageName,
                    focusTimeMinutes = focusTimeMinutes,
                    sessionType = focusManager.getCurrentSession()?.sessionType ?: "timer",
                    sessionId = focusManager.getCurrentSession()?.sessionId ?: "",
                    educationalMessage = educationalMessage
                )

                // Perform navigation action
                performNavigationAction(actionType)

                // Report interruption
                focusManager.reportInterruption(
                    packageName = packageName,
                    appName = contentType,
                    type = "short_form_content",
                    wasBlocked = true
                )

                // Show educational notification
                showEducationalNotification(contentType, educationalMessage)

                // Double vibration pattern for shorts
                vibrateDevice(doublePattern = true)

                // Log analytics
                logShortFormBlock(contentType, packageName)

            } catch (e: Exception) {
                Log.e(TAG, "Error blocking short-form content", e)
            }
        }
    }

    private fun performNavigationAction(actionType: String) {
        try {
            when (actionType) {
                "home" -> {
                    performGlobalAction(GLOBAL_ACTION_HOME)
                }
                "back" -> {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                }
                "back_then_home" -> {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                    // Schedule home action after a short delay
                    handler.postDelayed({
                        if (isCurrentlyInTargetApp()) {
                            performGlobalAction(GLOBAL_ACTION_HOME)
                        }
                    }, 1000)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error performing navigation action: $actionType", e)
        }
    }

    private fun isCurrentlyInTargetApp(): Boolean {
        // Check if we're still in one of the target apps
        try {
            val am = getSystemService(Context.ACTIVITY_SERVICE) as android.app.ActivityManager
            val tasks = am.getRunningTasks(1)
            if (tasks.isNotEmpty()) {
                val currentPackage = tasks[0].topActivity?.packageName
                return currentPackage in listOf(
                    "com.google.android.youtube",
                    "com.instagram.android",
                    "com.facebook.katana",
                    "com.zhiliaoapp.musically",
                    "com.snapchat.android"
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking current app", e)
        }
        return false
    }

    // ====================
    // UTILITY METHODS
    // ====================

    private fun getFocusTimeMinutes(): Int {
        return try {
            val sessionStatus = focusManager. getCurrentSessionStatus()
            (sessionStatus?. get("elapsedMinutes") as? Int) ?: 0
        } catch (e: Exception) {
            0
        }
    }

    private fun showEducationalNotification(contentType: String, message: String) {
        try {
            NotificationHelper.showEducationalNotification(
                context = this,
                title = "$contentType Blocked",
                message = message,
                contentType = contentType
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error showing educational notification", e)
        }
    }

    @RequiresPermission(Manifest.permission.VIBRATE)
    private fun vibrateDevice(doublePattern: Boolean = false) {
        try {
            val vibrator = getSystemService(Context. VIBRATOR_SERVICE) as Vibrator

            if (Build. VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val pattern = if (doublePattern) {
                    longArrayOf(0, 200, 100, 200) // Short-long-short pattern
                } else {
                    longArrayOf(0, 300) // Single vibration
                }

                val amplitudes = if (doublePattern) {
                    intArrayOf(0, 255, 0, 255)
                } else {
                    intArrayOf(0, 255)
                }

                val vibrationEffect = VibrationEffect.createWaveform(pattern, amplitudes, -1)
                vibrator.vibrate(vibrationEffect)
            } else {
                @Suppress("DEPRECATION")
                if (doublePattern) {
                    vibrator.vibrate(longArrayOf(0, 200, 100, 200), -1)
                } else {
                    vibrator.vibrate(300)
                }
            }
        } catch (e:  Exception) {
            Log.e(TAG, "Error vibrating device", e)
        }
    }

    private fun logShortFormBlock(contentType:  String, packageName:  String) {
        scope.launch(Dispatchers.IO) {
            try {
                // Log to analytics (Firebase, local storage, etc.)
                val logData = mapOf(
                    "type" to "short_form_blocked",
                    "content_type" to contentType,
                    "package_name" to packageName,
                    "timestamp" to System.currentTimeMillis(),
                    "session_id" to (focusManager.getCurrentSession()?.sessionId ?: ""),
                    "focus_time_minutes" to getFocusTimeMinutes()
                )

                // Store locally for analytics
                storeAnalyticsEvent(logData)

            } catch (e:  Exception) {
                Log.e(TAG, "Error logging short form block", e)
            }
        }
    }

    private fun storeAnalyticsEvent(logData: Map<String, Any>) {
        try {
            val prefs = getSharedPreferences("analytics", Context.MODE_PRIVATE)
            val today = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault())
                .format(java.util.Date())

            val existingData = prefs.getString("events_$today", "[]")
            val eventsArray = org.json.JSONArray(existingData)
            eventsArray.put(org.json.JSONObject(logData))

            prefs.edit().putString("events_$today", eventsArray.toString()).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Error storing analytics event", e)
        }
    }

    // ====================
    // CONFIGURATION MANAGEMENT
    // ====================

    private fun loadBlockConfiguration() {
        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val blocksJson = prefs.getString("blocks_config", "{}")
            if (!blocksJson.isNullOrEmpty()) {
                updateBlocksFromJson(blocksJson)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading block configuration", e)
        }
    }

    private fun updateBlocksFromJson(json: String) {
        try {
            val jsonObject = JSONObject(json)
            shortFormBlocks = ShortFormBlocks(
                youtubeShorts = jsonObject.optBoolean("youtubeShorts", false),
                instagramReels = jsonObject.optBoolean("instagramReels", false),
                facebookReels = jsonObject.optBoolean("facebookReels", false),
                tikTok = jsonObject.optBoolean("tikTok", false),
                snapchatSpotlight = jsonObject.optBoolean("snapchatSpotlight", false)
            )

            Log.d(TAG, "Updated blocks configuration: $shortFormBlocks")

        } catch (e: Exception) {
            Log.e(TAG, "Error updating blocks from JSON", e)
        }
    }

    // ====================
    // DATA CLASSES
    // ====================

    data class ShortFormBlocks(
        val youtubeShorts: Boolean = false,
        val instagramReels: Boolean = false,
        val facebookReels: Boolean = false,
        val tikTok: Boolean = false,
        val snapchatSpotlight: Boolean = false
    )
}
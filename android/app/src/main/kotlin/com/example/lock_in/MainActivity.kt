package com.example.lock_in

import android.util.Log
import androidx.annotation.NonNull
import com.example.lock_in.managers.FocusModeManager
import com.example.lock_in.managers.AppLimitManager
import com.example.lock_in.managers.PermanentBlockManager
import com.example.lock_in.managers.WebsiteBlockManager
import com.example.lock_in.managers.ShortFormBlockManager
import com.example.lock_in.permissions.PermissionManager
import com.example.lock_in.utils.BatteryOptimizationUtils
import com.example.lock_in.utils.AppUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter

class MainActivity: FlutterActivity() {

    companion object {
        private const val TAG = "MainActivity"
        private const val METHOD_CHANNEL = "com.lockin.focus/native"
        private const val EVENT_CHANNEL = "com.lockin.focus/events"
    }

    // CORE MANAGERS
    private lateinit var permissionManager: PermissionManager
    private lateinit var focusModeManager: FocusModeManager
    private lateinit var appLimitManager: AppLimitManager
    private lateinit var permanentBlockManager: PermanentBlockManager
    private lateinit var websiteBlockManager: WebsiteBlockManager
    private lateinit var shortFormBlockManager: ShortFormBlockManager

    // Method channels
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    // SCOPE
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    // Website blocking broadcast receiver
    private val websiteBlockReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == "com.lockin.WEBSITE_BLOCKED") {
                try {
                    val eventData = intent.getSerializableExtra("event_data") as? HashMap<String, Any>
                    if (eventData != null) {
                        sendEvent(eventData.toMap())
                        Log.d(TAG, "Website block event forwarded to Flutter: ${eventData["url"]}")
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error handling website block broadcast", e)
                }
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        try {
            initializeManagers()
            setUpMethodChannels(flutterEngine)
            setUpEventChannels(flutterEngine)
            registerWebsiteBlockReceiver()
        } catch (e: Exception) {
            Log.e(TAG, "ERROR CONFIGURING FLUTTER ENGINE", e)
        }
    }

    private fun initializeManagers() {
        try {
            permissionManager = PermissionManager(this)
            focusModeManager = FocusModeManager.getInstance(applicationContext)
            appLimitManager = AppLimitManager.getInstance(applicationContext)
            permanentBlockManager = PermanentBlockManager.getInstance(applicationContext)
            websiteBlockManager = WebsiteBlockManager.getInstance(applicationContext)
            shortFormBlockManager = ShortFormBlockManager.getInstance(applicationContext)

            Log.d(TAG, "All managers initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing managers", e)
            throw e
        }
    }

    private fun setUpMethodChannels(flutterEngine: FlutterEngine) {
        // MAIN METHOD CHANNEL
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            handleMainMethodCall(call.method, call.arguments, result)
        }
    }

    private fun setUpEventChannels(flutterEngine: FlutterEngine) {
        // EVENT CHANNEL for real-time updates
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                Log.d(TAG, "Event channel listener attached")
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                Log.d(TAG, "Event channel listener cancelled")
            }
        })
    }

    private fun registerWebsiteBlockReceiver() {
        try {
            val filter = IntentFilter("com.lockin.WEBSITE_BLOCKED")
            registerReceiver(websiteBlockReceiver, filter)
            Log.d(TAG, "Website block receiver registered")
        } catch (e: Exception) {
            Log.e(TAG, "Error registering website block receiver", e)
        }
    }

    private fun unregisterWebsiteBlockReceiver() {
        try {
            unregisterReceiver(websiteBlockReceiver)
            Log.d(TAG, "Website block receiver unregistered")
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering website block receiver", e)
        }
    }

    private fun getSupportedInstalledBrowsers(): List<String> {
        val supportedBrowserPackages = listOf(
            "com.android.chrome",
            "org.mozilla.firefox", 
            "com.sec.android.app.sbrowser",
            "com.microsoft.emmx",
            "com.opera.browser",
            "com.brave.browser",
            "com.kiwibrowser.browser"
        )
        
        val installedBrowsers = mutableListOf<String>()
        val packageManager = packageManager
        
        for (packageName in supportedBrowserPackages) {
            try {
                packageManager.getApplicationInfo(packageName, 0)
                val appName = packageManager.getApplicationLabel(
                    packageManager.getApplicationInfo(packageName, 0)
                ).toString()
                installedBrowsers.add("$appName ($packageName)")
            } catch (e: Exception) {
                // Browser not installed
            }
        }
        
        return installedBrowsers
    }

    /**
     * Send event to Flutter via event channel
     */
    private fun sendEvent(event: Map<String, Any>) {
        eventSink?.success(event)
    }

    private fun handleMainMethodCall(
        method: String,
        arguments: Any?,
        result: MethodChannel.Result
    ) {
        scope.launch {
            try {
                Log.v(TAG, "Method call: $method")

                when (method) {
                    // =======================
                    // FOCUS CONTROL
                    // =======================
                    "startFocusSession" -> {
                        val args = arguments as? Map<*, *>
                        val sessionId = args?.get("sessionId") as? String
                        val blockedApps = (args?.get("blockedApps") as? List<*>)
                            ?.mapNotNull { it as? String }
                            ?.toSet() ?: emptySet()
                        val duration = args?.get("duration") as? Int ?: 25
                        val strictMode = args?.get("strictMode") as? Boolean ?: false
                        val blockHomeScreen = args?.get("blockHomeScreen") as? Boolean ?: false

                        if (sessionId != null) {
                            // Check required permissions before starting
                            val hasPermissions = permissionManager.hasUsageStatsPermission() &&
                                               permissionManager.hasOverlayPermission() &&
                                               permissionManager.hasAccessibilityPermission()
                            
                            if (!hasPermissions) {
                                result.error(
                                    "MISSING_PERMISSIONS", 
                                    "Required permissions not granted. Please grant all permissions first.", 
                                    null
                                )
                                return@launch
                            }
                            
                            val success = focusModeManager.startFocusSession(
                                sessionId = sessionId,
                                blockedPackages = blockedApps,
                                durationMinutes = duration,
                                isStrict = strictMode,
                                blockHomeScreen = blockHomeScreen
                            )
                            
                            if (success) {
                                sendEvent(mapOf(
                                    "type" to "focus_started",
                                    "sessionId" to sessionId,
                                    "timestamp" to System.currentTimeMillis()
                                ))
                            }
                            
                            result.success(success)
                        } else {
                            result.error("INVALID_ARGS", "sessionId is required", null)
                        }
                    }

                    "stopFocusSession" -> {
                        val args = arguments as? Map<*, *>
                        val force = args?.get("force") as? Boolean ?: false
                        val success = focusModeManager.stopFocusSession(force)
                        
                        if (success) {
                            sendEvent(mapOf(
                                "type" to "focus_stopped",
                                "timestamp" to System.currentTimeMillis()
                            ))
                        }
                        
                        result.success(success)
                    }

                    "getFocusSessionInfo" -> {
                        val info = focusModeManager.getSessionInfo()
                        result.success(info)
                    }

                    "isBlockedApp" -> {
                        val args = arguments as? Map<*, *>
                        val packageName = args?.get("packageName") as? String
                        if (packageName != null) {
                            result.success(focusModeManager.isAppBlocked(packageName))
                        } else {
                            result.error("INVALID_ARGS", "packageName is required", null)
                        }
                    }

                    "getBlockedApps" -> {
                        val blockedApps = focusModeManager.getBlockedApps().toList()
                        result.success(blockedApps)
                    }

                    // =======================
                    // APP USAGE
                    // =======================
                    "getCurrentForegroundApp" -> {
                        val currentApp = appLimitManager.getCurrentForegroundApp()
                        result.success(currentApp)
                    }

                    "getAppUsageTime" -> {
                        val args = arguments as? Map<*, *>
                        val packageName = args?.get("packageName") as? String
                        val startTime = (args?.get("startTime") as? Number)?.toLong()
                            ?: System.currentTimeMillis() - 86400000 // 24 hours ago
                        
                        if (packageName != null) {
                            val usage = appLimitManager.getAppUsageTime(packageName, startTime)
                            result.success(usage)
                        } else {
                            result.error("INVALID_ARGS", "packageName is required", null)
                        }
                    }

                    "getTodayUsageStats" -> {
                        withContext(Dispatchers.IO) {
                            val stats = appLimitManager.getTodayUsageStats()
                            val usageList = stats.map { stat ->
                                mapOf(
                                    "packageName" to stat.packageName,
                                    "totalTime" to stat.totalTimeInForeground,
                                    "lastTimeUsed" to stat.lastTimeUsed
                                )
                            }
                            withContext(Dispatchers.Main) {
                                result.success(usageList)
                            }
                        }
                    }

                    // =======================
                    // PERMISSIONS
                    // =======================
                    // Usage Stats
                    "hasUsageStatsPermission" -> {
                        result.success(permissionManager.hasUsageStatsPermission())
                    }
                    "requestUsageStatsPermission" -> {
                        permissionManager.requestUsageStatsPermission()
                        result.success(null)
                    }
                    // Accessibility
                    "hasAccessibilityPermission" -> {
                        result.success(permissionManager.hasAccessibilityPermission())
                    }
                    "requestAccessibilityPermission" -> {
                        permissionManager.requestAccessibilityPermission()
                        result.success(null)
                    }
                    // Background
                    "hasBackgroundPermission" -> {
                        result.success(permissionManager.hasBackgroundPermission())
                    }
                    "requestBackgroundPermission" -> {
                        permissionManager.requestBackgroundPermission()
                        result.success(null)
                    }
                    // Overlay
                    "hasOverlayPermission" -> {
                        result.success(permissionManager.hasOverlayPermission())
                    }
                    "requestOverlayPermission" -> {
                        permissionManager.requestOverlayPermission()
                        result.success(null)
                    }
                    // Display Popup
                    "hasDisplayPopupPermission" -> {
                        result.success(permissionManager.hasDisplayPopupPermission())
                    }
                    "requestDisplayPopupPermission" -> {
                        permissionManager.requestDisplayPopupPermission()
                        result.success(null)
                    }
                    // Notifications
                    "hasNotificationPermission" -> {
                        result.success(permissionManager.hasNotificationPermission())
                    }
                    "requestNotificationPermission" -> {
                        permissionManager.requestNotificationPermission()
                        result.success(null)
                    }

                    // =============
                    // APP MANAGEMENT
                    // =============
                    "getInstalledApps" -> {
                        withContext(Dispatchers.IO) {
                            val apps = AppUtils.getInstalledApps(this@MainActivity)
                            withContext(Dispatchers.Main) {
                                result.success(apps)
                            }
                        }
                    }

                    "getAppIcon" -> {
                        val args = arguments as? Map<*, *>
                        val packageName = args?.get("packageName") as? String

                        if (packageName != null) {
                            scope.launch(Dispatchers.IO) {
                                val iconBytes = AppUtils.getAppIcon(
                                    this@MainActivity,
                                    packageName
                                )
                                withContext(Dispatchers.Main) {
                                    result.success(iconBytes)
                                }
                            }
                        } else {
                            result.error("INVALID_ARG", "Package name is null", null)
                        }
                    }

                    // =======================
                    // APP LIMITS
                    // =======================
                    "setAppLimit" -> {
                        val args = arguments as? Map<*, *>
                        val packageName = args?.get("packageName") as? String
                        val limitMinutes = args?.get("limitMinutes") as? Int
                        
                        if (packageName != null && limitMinutes != null) {
                            appLimitManager.setAppLimit(packageName, limitMinutes)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "packageName and limitMinutes are required", null)
                        }
                    }

                    "removeAppLimit" -> {
                        val args = arguments as? Map<*, *>
                        val packageName = args?.get("packageName") as? String
                        
                        if (packageName != null) {
                            appLimitManager.removeAppLimit(packageName)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "packageName is required", null)
                        }
                    }

                    "getAppLimit" -> {
                        val args = arguments as? Map<*, *>
                        val packageName = args?.get("packageName") as? String
                        
                        if (packageName != null) {
                            val limit = appLimitManager.getAppLimit(packageName)
                            result.success(limit)
                        } else {
                            result.error("INVALID_ARGS", "packageName is required", null)
                        }
                    }

                    "getAllAppLimits" -> {
                        val limits = appLimitManager.getAllAppLimits().map { limitData ->
                            mapOf(
                                "packageName" to limitData.packageName,
                                "limitMinutes" to limitData.limitMinutes,
                                "usedMinutes" to limitData.usedMinutes
                            )
                        }
                        result.success(limits)
                    }

                    "isAppLimitExceeded" -> {
                        val args = arguments as? Map<*, *>
                        val packageName = args?.get("packageName") as? String
                        
                        if (packageName != null) {
                            result.success(appLimitManager.hasExceededLimit(packageName))
                        } else {
                            result.error("INVALID_ARGS", "packageName is required", null)
                        }
                    }

                    // =======================
                    // PERMANENT BLOCKS
                    // =======================
                    "setPermanentlyBlockedApps" -> {
                        val args = arguments as? Map<*, *>
                        val apps = (args?.get("apps") as? List<*>)
                            ?.mapNotNull { it as? String }
                            ?.toSet() ?: emptySet()
                        
                        permanentBlockManager.setBlockedApps(apps)
                        result.success(true)
                    }

                    "addPermanentlyBlockedApp" -> {
                        val args = arguments as? Map<*, *>
                        val packageName = args?.get("packageName") as? String
                        
                        if (packageName != null) {
                            permanentBlockManager.addBlockedApp(packageName)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "packageName is required", null)
                        }
                    }

                    "removePermanentlyBlockedApp" -> {
                        val args = arguments as? Map<*, *>
                        val packageName = args?.get("packageName") as? String
                        
                        if (packageName != null) {
                            permanentBlockManager.removeBlockedApp(packageName)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "packageName is required", null)
                        }
                    }

                    "getPermanentlyBlockedApps" -> {
                        val apps = permanentBlockManager.getBlockedApps().toList()
                        result.success(apps)
                    }

                    "isPermanentlyBlocked" -> {
                        val args = arguments as? Map<*, *>
                        val packageName = args?.get("packageName") as? String
                        
                        if (packageName != null) {
                            result.success(permanentBlockManager.isAppBlocked(packageName))
                        } else {
                            result.error("INVALID_ARGS", "packageName is required", null)
                        }
                    }

                    // =======================
                    // APP LIMITS
                    // =======================
                    "setAppLimit" -> {
                        val args = arguments as? Map<*, *>
                        val packageName = args?.get("packageName") as? String
                        val limitMinutes = args?.get("limitMinutes") as? Int
                        
                        if (packageName != null && limitMinutes != null) {
                            appLimitManager.setAppLimit(packageName, limitMinutes)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "packageName and limitMinutes are required", null)
                        }
                    }

                    "removeAppLimit" -> {
                        val args = arguments as? Map<*, *>
                        val packageName = args?.get("packageName") as? String
                        
                        if (packageName != null) {
                            appLimitManager.removeAppLimit(packageName)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "packageName is required", null)
                        }
                    }

                    "getTodayUsage" -> {
                        val args = arguments as? Map<*, *>
                        val packageName = args?.get("packageName") as? String
                        
                        if (packageName != null) {
                            val usage = appLimitManager.getTodayUsage(packageName)
                            result.success(usage)
                        } else {
                            result.error("INVALID_ARGS", "packageName is required", null)
                        }
                    }

                    "hasExceededLimit" -> {
                        val args = arguments as? Map<*, *>
                        val packageName = args?.get("packageName") as? String
                        
                        if (packageName != null) {
                            result.success(appLimitManager.hasExceededLimit(packageName))
                        } else {
                            result.error("INVALID_ARGS", "packageName is required", null)
                        }
                    }

                    "getRemainingTime" -> {
                        val args = arguments as? Map<*, *>
                        val packageName = args?.get("packageName") as? String
                        
                        if (packageName != null) {
                            val remaining = appLimitManager.getRemainingTime(packageName)
                            result.success(remaining)
                        } else {
                            result.error("INVALID_ARGS", "packageName is required", null)
                        }
                    }

                    "resetDailyUsage" -> {
                        appLimitManager.resetDailyUsage()
                        result.success(true)
                    }

                    // =======================
                    // WEBSITE BLOCKS
                    // =======================
                    "addBlockedWebsite" -> {
                        val args = arguments as? Map<*, *>
                        val url = args?.get("url") as? String
                        val name = args?.get("name") as? String
                        val isActive = args?.get("isActive") as? Boolean ?: true
                        
                        if (url != null && name != null) {
                            websiteBlockManager.addBlockedWebsite(url, name, isActive)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "url and name are required", null)
                        }
                    }

                    "removeBlockedWebsite" -> {
                        val args = arguments as? Map<*, *>
                        val url = args?.get("url") as? String
                        
                        if (url != null) {
                            websiteBlockManager.removeBlockedWebsite(url)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "url is required", null)
                        }
                    }

                    "toggleBlockedWebsite" -> {
                        val args = arguments as? Map<*, *>
                        val url = args?.get("url") as? String
                        
                        if (url != null) {
                            websiteBlockManager.toggleWebsite(url)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "url is required", null)
                        }
                    }

                    "getBlockedWebsites" -> {
                        val websites = websiteBlockManager.getBlockedWebsites().map { website ->
                            mapOf(
                                "url" to website.url,
                                "name" to website.name,
                                "isActive" to website.isActive
                            )
                        }
                        result.success(websites)
                    }

                    "isUrlBlocked" -> {
                        val args = arguments as? Map<*, *>
                        val url = args?.get("url") as? String
                        
                        if (url != null) {
                            result.success(websiteBlockManager.isUrlBlocked(url))
                        } else {
                            result.error("INVALID_ARGS", "url is required", null)
                        }
                    }

                    "getWebsiteBlockingDiagnostics" -> {
                        val diagnostics = mutableMapOf<String, Any>()
                        
                        // Accessibility service status
                        val accessibilityEnabled = permissionManager.hasAccessibilityPermission()
                        diagnostics["accessibilityServiceEnabled"] = accessibilityEnabled
                        
                        // Active blocked websites
                        val activeWebsites = websiteBlockManager.getActiveBlockedWebsites()
                        diagnostics["activeBlockedWebsites"] = activeWebsites.map { mapOf(
                            "url" to it.url,
                            "name" to it.name,
                            "isActive" to it.isActive
                        )}
                        
                        // Supported browsers (installed)
                        val supportedBrowsers = getSupportedInstalledBrowsers()
                        diagnostics["installedBrowsers"] = supportedBrowsers
                        
                        // Service status
                        diagnostics["serviceRunning"] = 
                            com.example.lock_in.services.LockInAccessibilityService.isServiceRunning
                        
                        result.success(diagnostics)
                    }

                    "testWebsiteBlocking" -> {
                        val args = arguments as? Map<*, *>
                        val url = args?.get("url") as? String
                        
                        if (url != null) {
                            // Test if URL is blocked and if blocking mechanisms are ready
                            val isBlocked = websiteBlockManager.isUrlBlocked(url)
                            val hasPermissions = permissionManager.hasAccessibilityPermission()
                            
                            val testResult = isBlocked && hasPermissions
                            result.success(testResult)
                        } else {
                            result.error("INVALID_ARGS", "url is required", null)
                        }
                    }

                    "getSupportedBrowsers" -> {
                        val browsers = getSupportedInstalledBrowsers()
                        result.success(browsers)
                    }

                    // =======================
                    // SHORT FORM BLOCKS
                    // =======================
                    "setShortFormBlock" -> {
                        val args = arguments as? Map<*, *>
                        val platform = args?.get("platform") as? String
                        val feature = args?.get("feature") as? String
                        val isBlocked = args?.get("isBlocked") as? Boolean ?: false
                        
                        if (platform != null && feature != null) {
                            shortFormBlockManager.setShortFormBlock(platform, feature, isBlocked)
                            result.success(true)
                        } else {
                            result.error("INVALID_ARGS", "platform and feature are required", null)
                        }
                    }

                    "getShortFormBlocks" -> {
                        val blocks = shortFormBlockManager.getAllBlocks().map { block ->
                            mapOf(
                                "platform" to block.platform,
                                "feature" to block.feature,
                                "isBlocked" to block.isBlocked
                            )
                        }
                        result.success(blocks)
                    }

                    "isAccessibilityServiceEnabled" -> {
                        val isEnabled = permissionManager.hasAccessibilityPermission()
                        result.success(isEnabled)
                    }

                    "requestBatteryOptimizationExemption" -> {
                        try {
                            when {
                                BatteryOptimizationUtils.isIgnoringBatteryOptimizations(this@MainActivity) -> {
                                    result.success(mapOf(
                                        "granted" to true,
                                        "message" to "Battery optimization exemption already granted"
                                    ))
                                }
                                BatteryOptimizationUtils.shouldRequestBatteryOptimization(this@MainActivity) -> {
                                    val intent = BatteryOptimizationUtils.requestBatteryOptimizationExemption(this@MainActivity)
                                    if (intent != null) {
                                        startActivity(intent)
                                    }
                                    result.success(mapOf(
                                        "granted" to false,
                                        "message" to BatteryOptimizationUtils.getBatteryOptimizationMessage()
                                    ))
                                }
                                else -> {
                                    result.success(mapOf(
                                        "granted" to false,
                                        "message" to "Battery optimization cannot be disabled on this device"
                                    ))
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error requesting battery optimization exemption", e)
                            result.error("BATTERY_OPT_ERROR", e.message, null)
                        }
                    }

                    "checkBatteryOptimizationStatus" -> {
                        try {
                            result.success(mapOf(
                                "isIgnoringBatteryOptimizations" to BatteryOptimizationUtils.isIgnoringBatteryOptimizations(this@MainActivity),
                                "shouldRequest" to BatteryOptimizationUtils.shouldRequestBatteryOptimization(this@MainActivity),
                                "message" to BatteryOptimizationUtils.getBatteryOptimizationMessage()
                            ))
                        } catch (e: Exception) {
                            Log.e(TAG, "Error checking battery optimization status", e)
                            result.error("BATTERY_STATUS_ERROR", e.message, null)
                        }
                    }

                    "getShortFormBlockingStatus" -> {
                        val status = mapOf(
                            "accessibilityServiceEnabled" to permissionManager.hasAccessibilityPermission(),
                            "totalBlocks" to shortFormBlockManager.getAllBlocks().size,
                            "activeBlocks" to shortFormBlockManager.getAllBlocks().count { it.isBlocked },
                            "youtubeBlocked" to shortFormBlockManager.isYoutubeShortsBlocked(),
                            "instagramBlocked" to shortFormBlockManager.isInstagramReelsBlocked(),
                            "facebookBlocked" to shortFormBlockManager.isFacebookReelsBlocked(),
                            "snapchatBlocked" to shortFormBlockManager.isSnapchatStoriesBlocked(),
                            "tiktokBlocked" to shortFormBlockManager.isTikTokBlocked()
                        )
                        result.success(status)
                    }

                    "isShortFormBlocked" -> {
                        val args = arguments as? Map<*, *>
                        val platform = args?.get("platform") as? String
                        val feature = args?.get("feature") as? String
                        
                        if (platform != null && feature != null) {
                            result.success(shortFormBlockManager.isPlatformBlocked(platform, feature))
                        } else {
                            result.error("INVALID_ARGS", "platform and feature are required", null)
                        }
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling method call: $method", e)
                result.error("METHOD_ERROR", "Error handling method $method: ${e.message}", mapOf(
                    "method" to method,
                    "error" to e.javaClass.simpleName,
                    "message" to (e.message ?: "Unknown error"),
                    "stackTrace" to e.stackTrace.take(5).map { it.toString() }
                ))
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterWebsiteBlockReceiver()
        scope.cancel()
    }
}
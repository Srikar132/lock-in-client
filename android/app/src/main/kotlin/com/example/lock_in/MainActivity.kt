package com.example.lock_in

import android.util.Log
import androidx.annotation.NonNull
import com.example.lock_in.permissions.PermissionManager
import com.example.lock_in.services.AppLimitManager
import com.example.lock_in.utils.AppUtils
import com.lockin.focus.FocusModeManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.util.concurrent.ConcurrentHashMap

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

    // Method channels
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel

    // Event sinks
    private var eventSink: EventChannel.EventSink? = null
    private val eventQueue = ConcurrentHashMap<String, Any>()

    // SCOPE
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        try {
            initializeManagers()
            setupMethodChannels(flutterEngine)
            setupEventChannels(flutterEngine)
        } catch (e: Exception) {
            Log.e(TAG, "ERROR CONFIGURING FLUTTER ENGINE", e)
        }
    }

    private fun initializeManagers() {
        try {
            permissionManager = PermissionManager(this)
            focusModeManager = FocusModeManager(this)
            appLimitManager = AppLimitManager(this)

            Log.d(TAG, "All managers initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing managers", e)
            throw e
        }
    }

    private fun setupMethodChannels(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            handleMainMethodCall(call.method, call.arguments, result)
        }
        Log.d(TAG, "Method channel configured")
    }

    private fun setupEventChannels(flutterEngine: FlutterEngine) {
        eventChannel = EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                focusModeManager.setEventSink(events)

                // Send queued events
                eventQueue.forEach { (event, data) ->
                    sendEventToFlutter(event, data)
                }
                eventQueue.clear()

                Log.d(TAG, "Event channel connected")
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                focusModeManager.setEventSink(null)
                Log.d(TAG, "Event channel disconnected")
            }
        })
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
                    // ====================
                    // FOCUS SESSION METHODS
                    // ====================
                    "startFocusSession" -> {
                        val sessionData = arguments as? Map<String, Any>
                        if (sessionData != null) {
                            scope.launch {
                                try {
                                    Log.d(TAG, "Starting focus session with data: $sessionData")
                                    val success = focusModeManager.startSession(sessionData)
                                    withContext(Dispatchers.Main) {
                                        result.success(success)
                                    }
                                } catch (e: Exception) {
                                    Log.e(TAG, "Error starting focus session", e)
                                    withContext(Dispatchers.Main) {
                                        result.error("START_SESSION_ERROR", e.message, null)
                                    }
                                }
                            }
                        } else {
                            result.error("INVALID_ARGUMENT", "Session data is required", null)
                        }
                    }

                    "pauseFocusSession" -> {
                        scope.launch {
                            try {
                                val success = focusModeManager.pauseSession()
                                withContext(Dispatchers.Main) {
                                    result.success(success)
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "Error pausing session", e)
                                withContext(Dispatchers.Main) {
                                    result.error("PAUSE_SESSION_ERROR", e.message, null)
                                }
                            }
                        }
                    }

                    "resumeFocusSession" -> {
                        scope.launch {
                            try {
                                val success = focusModeManager.resumeSession()
                                withContext(Dispatchers.Main) {
                                    result.success(success)
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "Error resuming session", e)
                                withContext(Dispatchers.Main) {
                                    result.error("RESUME_SESSION_ERROR", e.message, null)
                                }
                            }
                        }
                    }

                    "endFocusSession" -> {
                        scope.launch {
                            try {
                                val success = focusModeManager.endSession()
                                withContext(Dispatchers.Main) {
                                    result.success(success)
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "Error ending session", e)
                                withContext(Dispatchers.Main) {
                                    result.error("END_SESSION_ERROR", e.message, null)
                                }
                            }
                        }
                    }

                    "getCurrentSessionStatus" -> {
                        val status = focusModeManager.getCurrentSessionStatus()
                        result.success(status)
                    }

                    // =======================
                    // PERMISSIONS
                    // =======================
                    "hasUsageStatsPermission" -> {
                        result.success(permissionManager.hasUsageStatsPermission())
                    }
                    "requestUsageStatsPermission" -> {
                        permissionManager.requestUsageStatsPermission()
                        result.success(null)
                    }
                    "hasAccessibilityPermission" -> {
                        result.success(permissionManager.hasAccessibilityPermission())
                    }
                    "requestAccessibilityPermission" -> {
                        permissionManager.requestAccessibilityPermission()
                        result.success(null)
                    }
                    "hasBackgroundPermission" -> {
                        result.success(permissionManager.hasBackgroundPermission())
                    }
                    "requestBackgroundPermission" -> {
                        permissionManager.requestBackgroundPermission()
                        result.success(null)
                    }
                    "hasOverlayPermission" -> {
                        result.success(permissionManager.hasOverlayPermission())
                    }
                    "requestOverlayPermission" -> {
                        permissionManager.requestOverlayPermission()
                        result.success(null)
                    }
                    "hasDisplayPopupPermission" -> {
                        result.success(permissionManager.hasDisplayPopupPermission())
                    }
                    "requestDisplayPopupPermission" -> {
                        permissionManager.requestDisplayPopupPermission()
                        result.success(null)
                    }
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

                    // ====================
                    // PERSISTENT (ALWAYS-ON) BLOCKING
                    // ====================
                    
                    // App blocking
                    "setPersistentAppBlocking" -> {
                        val args = arguments as? Map<*, *>
                        val enabled = args?.get("enabled") as? Boolean ?: false
                        val apps = (args?.get("blockedApps") as? List<*>)?.mapNotNull { it as? String }
                        focusModeManager.setPersistentAppBlocking(enabled, apps)
                        result.success(null)
                    }

                    "isPersistentAppBlockingEnabled" -> {
                        result.success(focusModeManager.isPersistentAppBlockingEnabled())
                    }

                    "getPersistentBlockedApps" -> {
                        result.success(focusModeManager.getPersistentBlockedApps())
                    }

                    // Website blocking
                    "setPersistentWebsiteBlocking" -> {
                        val args = arguments as? Map<*, *>
                        val enabled = args?.get("enabled") as? Boolean ?: false
                        val websites = (args?.get("blockedWebsites") as? List<*>)?.mapNotNull { 
                            it as? Map<String, Any> 
                        }
                        focusModeManager.setPersistentWebsiteBlocking(enabled, websites)
                        result.success(null)
                    }

                    "isPersistentWebsiteBlockingEnabled" -> {
                        result.success(focusModeManager.isPersistentWebsiteBlockingEnabled())
                    }

                    "getPersistentBlockedWebsites" -> {
                        result.success(focusModeManager.getPersistentBlockedWebsites())
                    }

                    // Short-form content blocking
                    "setPersistentShortFormBlocking" -> {
                        val args = arguments as? Map<*, *>
                        val enabled = args?.get("enabled") as? Boolean ?: false
                        val blocks = args?.get("shortFormBlocks") as? Map<String, Any>
                        focusModeManager.setPersistentShortFormBlocking(enabled, blocks)
                        result.success(null)
                    }

                    "isPersistentShortFormBlockingEnabled" -> {
                        result.success(focusModeManager.isPersistentShortFormBlockingEnabled())
                    }

                    "getPersistentShortFormBlocks" -> {
                        result.success(focusModeManager.getPersistentShortFormBlocks())
                    }

                    // Notification blocking
                    "setPersistentNotificationBlocking" -> {
                        val args = arguments as? Map<*, *>
                        val enabled = args?.get("enabled") as? Boolean ?: false
                        val blocks = args?.get("notificationBlocks") as? Map<String, Any>
                        focusModeManager.setPersistentNotificationBlocking(enabled, blocks)
                        result.success(null)
                    }

                    "isPersistentNotificationBlockingEnabled" -> {
                        result.success(focusModeManager.isPersistentNotificationBlockingEnabled())
                    }

                    "getPersistentNotificationBlocks" -> {
                        result.success(focusModeManager.getPersistentNotificationBlocks())
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling method call: $method", e)
                result.error("METHOD_ERROR", "Error: ${e.message}", mapOf(
                    "method" to method,
                    "error" to e.javaClass.simpleName,
                    "message" to (e.message ?: "Unknown error")
                ))
            }
        }
    }

    private fun sendEventToFlutter(event: String, data: Any) {
        try {
            val eventData = mapOf(
                "event" to event,
                "data" to data,
                "timestamp" to System.currentTimeMillis()
            )

            if (eventSink != null) {
                eventSink?.success(eventData)
            } else {
                eventQueue[event] = data
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error sending event to Flutter: $event", e)
        }
    }
}
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
        private const val HEALTH_CHANNEL = "com.lockin.focus/health"
        private const val ANALYTICS_CHANNEL = "com.lockin.focus/analytics"
    }

    private val CHANNEL = "com.example.lock_in/native"

    // CORE MANAGERS
    private lateinit var permissionManager: PermissionManager
    private lateinit var focusModeManager : FocusModeManager
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

            setUpMethodChannels(flutterEngine)
        }catch (e : Exception) {
            Log.e(TAG , "ERROR CONFIGURING FLUTTER ENGINE")
        }
        

    }

    private fun initializeManagers() {
        try {
            permissionManager = PermissionManager(this)
            focusModeManager = FocusModeManager(this)
            appLimitManager = AppLimitManager(this)


            Log.d(TAG, "All managers initialized successfully")
        }catch (e : Exception) {
            Log.e(TAG, "Error initializing managers", e)
            throw e
        }
    }

    private fun setUpMethodChannels(flutterEngine: FlutterEngine) {
        // MAIN METHOD CHANNEL
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler{ call , result ->
            handleMainMethodCall(call.method , call.arguments , result)
        }

    }


    private fun setupEventChannels(flutterEngine: FlutterEngine) {
        // Main event channel
        eventChannel = EventChannel(flutterEngine. dartExecutor.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(object : EventChannel. StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                focusModeManager.setEventSink(events)

                // Send queued events
                eventQueue.forEach { (event, data) ->
                    sendEventToFlutter(event, data)
                }
                eventQueue.clear()
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                focusModeManager.setEventSink(null)
            }
        })

        Log.d(TAG, "Event channels configured")
    }

    private fun handleMainMethodCall(
        method: String,
        arguments:  Any?,
        result: MethodChannel.Result
    ) {
        scope.launch {
            try {
                Log.v(TAG, "Method call: $method")

                when(method) {
                    // ====================
                    // FOCUS SESSION METHODS
                    // ====================
                    // ====================
                    "startFocusSession" -> {
                        val sessionData = arguments as? Map<String, Any>
                        if (sessionData != null) {
                            val success = focusModeManager.startSession(sessionData)
                            result.success(success)
                        } else {
                            result.error("INVALID_ARGUMENT", "Session data is required", null)
                        }
                    }

                    "pauseFocusSession" -> {
                        val success = focusModeManager.pauseSession()
                        result.success(success)
                    }

                    "resumeFocusSession" -> {
                        val success = focusModeManager.resumeSession()
                        result. success(success)
                    }

                    "endFocusSession" -> {
                        val success = focusModeManager.endSession()
                        result.success(success)
                    }

                    "getCurrentSessionStatus" -> {
                        val status = focusModeManager.getCurrentSessionStatus()
                        result.success(status)
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





                    else -> {
                        result.notImplemented()
                    }
                }
            }catch (e : Exception) {
                Log.e(TAG, "Error handling method call: $method", e)
                result.error("METHOD_ERROR", "Error handling method $method: ${e.message}", mapOf(
                    "method" to method,
                    "error" to e.javaClass.simpleName,
                    "message" to (e.message ?:  "Unknown error"),
                    "stackTrace" to e.stackTrace.take(5).map { it.toString() }
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
                // Queue event for later delivery
                eventQueue[event] = data
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error sending event to Flutter: $event", e)
        }
    }

}
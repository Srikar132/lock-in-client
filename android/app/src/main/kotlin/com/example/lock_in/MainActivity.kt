package com.example.lock_in

import android.util.Log
import androidx.annotation.NonNull
import com.example.lock_in.permissions.PermissionManager
import com.example.lock_in.utils.AppUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

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

    // Method channels
    private lateinit var methodChannel: MethodChannel


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

    private fun handleMainMethodCall(
        method: String,
        arguments:  Any?,
        result: MethodChannel.Result
    ) {
        scope.launch {
            try {
                Log.v(TAG, "Method call: $method")

                when(method) {
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

}
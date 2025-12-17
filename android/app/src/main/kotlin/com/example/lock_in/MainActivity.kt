package com.example.lock_in

import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import com.example.lock_in.permissions.PermissionManager
import com.example.lock_in.focus.FocusModeManager
import com.example.lock_in.focus.SessionData
import com.example.lock_in.focus.SessionType

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.lock_in/native"
    private val EVENT_CHANNEL = "com.example.lock_in/focus_events"
    private lateinit var permissionManager: PermissionManager
    private lateinit var focusModeManager: FocusModeManager

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        permissionManager = PermissionManager(this)
        focusModeManager = FocusModeManager.getInstance(this)
        
        // Setup EventChannel for focus mode events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    focusModeManager.setEventSink(events)
                }
                
                override fun onCancel(arguments: Any?) {
                    focusModeManager.setEventSink(null)
                }
            })
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
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
                    
                    // Debug method
                    "debugAccessibilityPermission" -> {
                        result.success(permissionManager.debugAccessibilityPermission())
                    }
                    
                    // Focus Mode Management
                    "startFocusSession" -> {
                        try {
                            val args = call.arguments as? Map<*, *>
                            if (args == null) {
                                result.error("INVALID_ARGUMENTS", "Session data required", null)
                                return@setMethodCallHandler
                            }
                            
                            @Suppress("UNCHECKED_CAST")
                            val sessionData = SessionData.fromMap(args as Map<String, Any>)
                            val startResult = focusModeManager.startSession(sessionData)
                            
                            if (startResult.isSuccess) {
                                result.success(true)
                            } else {
                                val exception = startResult.exceptionOrNull()
                                result.error("START_SESSION_ERROR", exception?.message ?: "Failed to start session", null)
                            }
                        } catch (e: Exception) {
                            result.error("START_SESSION_ERROR", e.message, null)
                        }
                    }
                    
                    "pauseFocusSession" -> {
                        try {
                            val pauseResult = focusModeManager.pauseSession()
                            if (pauseResult.isSuccess) {
                                result.success(true)
                            } else {
                                val exception = pauseResult.exceptionOrNull()
                                result.error("PAUSE_SESSION_ERROR", exception?.message ?: "Failed to pause session", null)
                            }
                        } catch (e: Exception) {
                            result.error("PAUSE_SESSION_ERROR", e.message, null)
                        }
                    }
                    
                    "resumeFocusSession" -> {
                        try {
                            val resumeResult = focusModeManager.resumeSession()
                            if (resumeResult.isSuccess) {
                                result.success(true)
                            } else {
                                val exception = resumeResult.exceptionOrNull()
                                result.error("RESUME_SESSION_ERROR", exception?.message ?: "Failed to resume session", null)
                            }
                        } catch (e: Exception) {
                            result.error("RESUME_SESSION_ERROR", e.message, null)
                        }
                    }
                    
                    "endFocusSession" -> {
                        try {
                            val endResult = focusModeManager.endSession()
                            if (endResult.isSuccess) {
                                val stats = endResult.getOrNull()
                                result.success(stats?.toMap())
                            } else {
                                val exception = endResult.exceptionOrNull()
                                result.error("END_SESSION_ERROR", exception?.message ?: "Failed to end session", null)
                            }
                        } catch (e: Exception) {
                            result.error("END_SESSION_ERROR", e.message, null)
                        }
                    }
                    
                    "getFocusSessionStatus" -> {
                        try {
                            val sessionState = focusModeManager.getCurrentSessionStatus()
                            if (sessionState != null) {
                                result.success(mapOf(
                                    "sessionId" to sessionState.sessionId,
                                    "status" to sessionState.status.name,
                                    "elapsedTime" to sessionState.elapsedTime,
                                    "startTime" to sessionState.startTime,
                                    "sessionData" to sessionState.sessionData.toMap()
                                ))
                            } else {
                                result.success(null)
                            }
                        } catch (e: Exception) {
                            result.error("GET_STATUS_ERROR", e.message, null)
                        }
                    }
                    
                    "isFocusSessionRunning" -> {
                        result.success(focusModeManager.isSessionRunning())
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        focusModeManager.cleanup()
    }
}
package com.example.lock_in

import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.lock_in.permissions.PermissionManager

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.lock_in/native"
    private lateinit var permissionManager: PermissionManager

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        permissionManager = PermissionManager(this)
        
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
                    
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service class to handle all native Android permissions required by the app.
/// This service communicates with the native Android side through method channels
/// to request and check various permissions needed for the app to function properly.
class PermissionService {
  static const _platform = MethodChannel('com.example.lock_in/native');

  /// Check if the app has usage stats permission.
  /// This permission is required to monitor app usage and identify distracting apps.
  static Future<bool> hasUsageStatsPermission() async {
    try {
      final result = await _platform.invokeMethod('hasUsageStatsPermission');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('Error checking usage stats permission: $e');
      return false;
    }
  }

  /// Request usage stats permission from the user.
  /// Opens the device settings screen where the user can grant usage access.
  static Future<void> requestUsageStatsPermission() async {
    try {
      await _platform.invokeMethod('requestUsageStatsPermission');
    } catch (e) {
      debugPrint('Error requesting usage stats permission: $e');
    }
  }

  /// Check if the app has accessibility permission.
  /// This permission is required for advanced app blocking functionality.
  static Future<bool> hasAccessibilityPermission() async {
    try {
      final result = await _platform.invokeMethod('hasAccessibilityPermission');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('Error checking accessibility permission: $e');
      return false;
    }
  }

  /// Request accessibility permission from the user.
  /// Opens the accessibility settings screen where the user can enable the service.
  static Future<void> requestAccessibilityPermission() async {
    try {
      await _platform.invokeMethod('requestAccessibilityPermission');
    } catch (e) {
      debugPrint('Error requesting accessibility permission: $e');
    }
  }

  /// Check if the app has background execution permission.
  /// This permission allows the app to run continuously in the background.
  static Future<bool> hasBackgroundPermission() async {
    try {
      final result = await _platform.invokeMethod('hasBackgroundPermission');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('Error checking background permission: $e');
      return false;
    }
  }

  /// Request background permission for background tasks.
  /// This allows the app to continue monitoring even when not in foreground.
  static Future<void> requestBackgroundPermission() async {
    try {
      await _platform.invokeMethod('requestBackgroundPermission');
    } catch (e) {
      debugPrint('Error requesting background permission: $e');
    }
  }

  /// Check if the app has overlay permission (display over other apps).
  /// This permission is required to show blocking screens over other apps.
  static Future<bool> hasOverlayPermission() async {
    try {
      final result = await _platform.invokeMethod('hasOverlayPermission');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('Error checking overlay permission: $e');
      return false;
    }
  }

  /// Request overlay permission from the user.
  /// Opens the system settings where the user can allow displaying over other apps.
  static Future<void> requestOverlayPermission() async {
    try {
      await _platform.invokeMethod('requestOverlayPermission');
    } catch (e) {
      debugPrint('Error requesting overlay permission: $e');
    }
  }

  /// Check if the app has display popup permission.
  /// This permission allows showing popup notifications and reminders.
  static Future<bool> hasDisplayPopupPermission() async {
    try {
      final result = await _platform.invokeMethod('hasDisplayPopupPermission');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('Error checking display popup permission: $e');
      return false;
    }
  }

  /// Request display popup permission from the user.
  /// This allows the app to show focus reminders and motivational popups.
  static Future<void> requestDisplayPopupPermission() async {
    try {
      await _platform.invokeMethod('requestDisplayPopupPermission');
    } catch (e) {
      debugPrint('Error requesting display popup permission: $e');
    }
  }

  /// Check if the app has notification permission.
  /// This permission is required to send notifications to the user.
  static Future<bool> hasNotificationPermission() async {
    try {
      final result = await _platform.invokeMethod('hasNotificationPermission');
      return result as bool? ?? false;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  /// Request notification permission from the user.
  /// Opens the notification settings or shows a system dialog.
  static Future<void> requestNotificationPermission() async {
    try {
      await _platform.invokeMethod('requestNotificationPermission');
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }
}
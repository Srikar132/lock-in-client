import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lock_in/data/models/installed_app_model.dart';

/// Service class to handle all native Android permissions required by the app.
/// This service communicates with the native Android side through method channels
/// to request and check various permissions needed for the app to function properly.
class NativeService {
  static const _platform = MethodChannel('com.lockin.focus/native');

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

  /// Debug method to get detailed accessibility permission information.
  /// Returns a detailed string with debugging information about accessibility service status.
  static Future<String> debugAccessibilityPermission() async {
    try {
      final result = await _platform.invokeMethod('debugAccessibilityPermission');
      return result as String? ?? 'No debug info available';
    } catch (e) {
      debugPrint('Error getting accessibility debug info: $e');
      return 'Error getting debug info: $e';
    }
  }



  /// Get all installed apps on the device.
  /// Returns a list of [InstalledApp] objects containing app information.
  /// Filters out most system apps and only includes user-installed apps
  /// and important system apps (Chrome, YouTube, Play Store, etc.).
  static Future<List<InstalledApp>> getInstalledApps() async {
    try {
      final result = await _platform.invokeMethod('getInstalledApps');

      if (result == null) {
        debugPrint('❌✅getInstalledApps returned null');
        return [];
      }

      final List<dynamic> appsList = result as List<dynamic>;

      return appsList.map((app) {
        final Map<String, dynamic> appMap = Map<String, dynamic>.from(app as Map);
        return InstalledApp.fromMap(appMap);
      }).toList();
    } catch (e) {
      debugPrint('Error getting installed apps: $e');
      return [];
    }
  }

  static Future<Uint8List?> getAppIcon(String packageName) async {
    try {
      final result = await _platform.invokeMethod('getAppIcon', {
        'packageName': packageName,
      });

      if (result == null) return null;

      return result as Uint8List;

    } on PlatformException catch (e) {
      // It's common for some system apps to fail icon retrieval, just log it lightly
      debugPrint("NativeService Icon Error ($packageName): '${e.message}'");
      return null;
    } catch (e) {
      debugPrint("NativeService Icon Error: $e");
      return null;
    }
  }
}
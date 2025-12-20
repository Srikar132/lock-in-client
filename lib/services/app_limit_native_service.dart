import 'package:flutter/services.dart';

/// Native service for app limit management
/// Communicates with Android's AccessibilityService + UsageStatsManager
/// This implementation follows the simplified architecture:
/// - Kotlin handles all usage tracking and enforcement
/// - Flutter only manages UI and pushes limits to native
class AppLimitNativeService {
  static const _limitsChannel = MethodChannel('lockin/app_limits');
  static const _eventsChannel = MethodChannel('lockin/app_limits_events');

  /// Update limits in native (Kotlin)
  /// @param limits Map of packageName -> limitMinutes
  Future<bool> updateLimits(Map<String, int> limits) async {
    try {
      final limitsList = limits.entries
          .map((entry) => {'package': entry.key, 'limitMinutes': entry.value})
          .toList();

      final result = await _limitsChannel.invokeMethod<bool>('updateLimits', {
        'limits': limitsList,
      });
      return result ?? false;
    } catch (e) {
      print('Error updating limits: $e');
      return false;
    }
  }

  /// Set a single app limit (calls updateLimits internally)
  Future<bool> setAppLimit(String packageName, int limitMinutes) async {
    return updateLimits({packageName: limitMinutes});
  }

  /// Remove an app limit by setting it to 0 or removing from map
  Future<bool> removeAppLimit(String packageName) async {
    return updateLimits({packageName: 0});
  }

  /// Get today's usage for a specific app (in minutes)
  Future<int> getTodayUsage(String packageName) async {
    try {
      final result = await _limitsChannel.invokeMethod<int>(
        'getTodayUsage',
        packageName,
      );
      return result ?? 0;
    } catch (e) {
      print('Error getting today usage: $e');
      return 0;
    }
  }

  /// Get usage stats for all apps with limits
  Future<Map<String, Map<String, dynamic>>> getAllUsageStats() async {
    try {
      final result = await _limitsChannel.invokeMethod<Map>('getAllUsageStats');

      if (result == null) return {};

      return Map<String, Map<String, dynamic>>.from(
        result.map(
          (key, value) =>
              MapEntry(key.toString(), Map<String, dynamic>.from(value as Map)),
        ),
      );
    } catch (e) {
      print('Error getting usage stats: $e');
      return {};
    }
  }

  /// Force check all limits (useful for immediate updates)
  Future<List<String>> forceCheckLimits() async {
    try {
      final result = await _limitsChannel.invokeMethod<List>(
        'forceCheckLimits',
      );
      return result?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      print('Error forcing check limits: $e');
      return [];
    }
  }

  /// Initialize limit events handler
  void initLimitEventsHandler(Function(String packageName) onLimitReached) {
    print('🔔 Setting up app limit events handler...');
    _eventsChannel.setMethodCallHandler((call) async {
      print('🔔 Received method call: ${call.method}');
      print('🔔 Arguments: ${call.arguments}');
      if (call.method == 'limitReached') {
        final packageName = call.arguments['package'] as String?;
        print('⚠️ Limit reached event for: $packageName');
        if (packageName != null) {
          onLimitReached(packageName);
        } else {
          print('❌ Package name is null in limit reached event');
        }
      }
    });
    print('✅ App limit events handler setup complete');
  }
}

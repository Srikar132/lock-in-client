import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// FocusSessionService - Flutter service for controlling focus sessions
///
/// Communicates with native Android code to start/stop focus sessions,
/// monitor app blocking, and receive real-time updates
class FocusSessionService {
  static const MethodChannel _methodChannel = MethodChannel(
    'com.lockin.focus/native',
  );
  static const EventChannel _eventChannel = EventChannel(
    'com.lockin.focus/events',
  );

  static Stream<Map<String, dynamic>>? _eventStream;
  static final StreamController<FocusEvent> _focusEventController =
      StreamController<FocusEvent>.broadcast();

  /// Stream of focus events (session started/stopped, app blocked, etc.)
  static Stream<FocusEvent> get focusEvents => _focusEventController.stream;

  /// Initialize the event stream listener
  static void initialize() {
    _eventStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      return Map<String, dynamic>.from(event as Map);
    });

    _eventStream!.listen(
      (event) {
        try {
          final eventType = event['type'] as String?;
          if (eventType != null) {
            final focusEvent = FocusEvent.fromMap(event);
            _focusEventController.add(focusEvent);
          }
        } catch (e) {
          debugPrint('Error processing focus event: $e');
        }
      },
      onError: (error) {
        debugPrint('Focus event stream error: $error');
      },
    );
  }

  /// Start a focus session
  ///
  /// [sessionId]: Unique identifier for this session
  /// [blockedApps]: List of package names to block
  /// [duration]: Duration in minutes
  /// [strictMode]: If true, session cannot be ended early
  /// [blockHomeScreen]: If true, blocks access to home screen
  static Future<bool> startFocusSession({
    required String sessionId,
    required List<String> blockedApps,
    required int duration,
    bool strictMode = false,
    bool blockHomeScreen = false,
  }) async {
    try {
      debugPrint('Starting focus session: $sessionId');
      final result = await _methodChannel
          .invokeMethod<bool>('startFocusSession', {
            'sessionId': sessionId,
            'blockedApps': blockedApps,
            'duration': duration,
            'strictMode': strictMode,
            'blockHomeScreen': blockHomeScreen,
          });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error starting focus session: ${e.message}');
      return false;
    }
  }

  /// Stop the current focus session
  ///
  /// [force]: If true, stops even in strict mode
  static Future<bool> stopFocusSession({bool force = false}) async {
    try {
      debugPrint('Stopping focus session (force: $force)');
      final result = await _methodChannel.invokeMethod<bool>(
        'stopFocusSession',
        {'force': force},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error stopping focus session: ${e.message}');
      return false;
    }
  }

  /// Get current focus session information
  static Future<FocusSessionInfo?> getSessionInfo() async {
    try {
      final result = await _methodChannel.invokeMethod<Map>(
        'getFocusSessionInfo',
      );
      if (result != null) {
        return FocusSessionInfo.fromMap(Map<String, dynamic>.from(result));
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint('Error getting session info: ${e.message}');
      return null;
    }
  }

  /// Check if a specific app is blocked
  static Future<bool> isAppBlocked(String packageName) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isBlockedApp', {
        'packageName': packageName,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error checking if app is blocked: ${e.message}');
      return false;
    }
  }

  /// Get list of currently blocked apps
  static Future<List<String>> getBlockedApps() async {
    try {
      final result = await _methodChannel.invokeMethod<List>('getBlockedApps');
      return result?.cast<String>() ?? [];
    } on PlatformException catch (e) {
      debugPrint('Error getting blocked apps: ${e.message}');
      return [];
    }
  }

  /// Get the current foreground app
  static Future<String?> getCurrentForegroundApp() async {
    try {
      final result = await _methodChannel.invokeMethod<String>(
        'getCurrentForegroundApp',
      );
      return result;
    } on PlatformException catch (e) {
      debugPrint('Error getting current foreground app: ${e.message}');
      return null;
    }
  }

  /// Get app usage time
  static Future<int> getAppUsageTime(
    String packageName, {
    int? startTime,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod<int>('getAppUsageTime', {
        'packageName': packageName,
        'startTime':
            startTime ??
            DateTime.now()
                .subtract(const Duration(hours: 24))
                .millisecondsSinceEpoch,
      });
      return result ?? 0;
    } on PlatformException catch (e) {
      debugPrint('Error getting app usage time: ${e.message}');
      return 0;
    }
  }

  /// Get today's usage statistics for all apps
  static Future<List<AppUsageStats>> getTodayUsageStats() async {
    try {
      final result = await _methodChannel.invokeMethod<List>(
        'getTodayUsageStats',
      );
      if (result != null) {
        return result.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return AppUsageStats.fromMap(map);
        }).toList();
      }
      return [];
    } on PlatformException catch (e) {
      debugPrint('Error getting usage stats: ${e.message}');
      return [];
    }
  }

  /// Dispose resources
  static void dispose() {
    _focusEventController.close();
  }
}

/// Focus event types
class FocusEvent {
  final String type;
  final String? sessionId;
  final int timestamp;
  final Map<String, dynamic>? data;

  FocusEvent({
    required this.type,
    this.sessionId,
    required this.timestamp,
    this.data,
  });

  factory FocusEvent.fromMap(Map<String, dynamic> map) {
    return FocusEvent(
      type: map['type'] as String,
      sessionId: map['sessionId'] as String?,
      timestamp: map['timestamp'] as int,
      data: map,
    );
  }

  bool get isFocusStarted => type == 'focus_started';
  bool get isFocusStopped => type == 'focus_stopped';
  bool get isAppBlocked => type == 'app_blocked';
}

/// Focus session info
class FocusSessionInfo {
  final bool isActive;
  final String? sessionId;
  final int blockedAppsCount;
  final int startTime;
  final int plannedDuration;
  final bool strictMode;
  final int elapsedMinutes;

  FocusSessionInfo({
    required this.isActive,
    this.sessionId,
    required this.blockedAppsCount,
    required this.startTime,
    required this.plannedDuration,
    required this.strictMode,
    required this.elapsedMinutes,
  });

  factory FocusSessionInfo.fromMap(Map<String, dynamic> map) {
    return FocusSessionInfo(
      isActive: map['isActive'] as bool,
      sessionId: map['sessionId'] as String?,
      blockedAppsCount: map['blockedAppsCount'] as int,
      startTime: map['startTime'] as int,
      plannedDuration: map['plannedDuration'] as int,
      strictMode: map['strictMode'] as bool,
      elapsedMinutes: map['elapsedMinutes'] as int,
    );
  }

  int get remainingMinutes => plannedDuration - elapsedMinutes;
}

/// App usage statistics
class AppUsageStats {
  final String packageName;
  final int totalTime; // in milliseconds
  final int lastTimeUsed; // timestamp

  AppUsageStats({
    required this.packageName,
    required this.totalTime,
    required this.lastTimeUsed,
  });

  factory AppUsageStats.fromMap(Map<String, dynamic> map) {
    return AppUsageStats(
      packageName: map['packageName'] as String,
      totalTime: map['totalTime'] as int,
      lastTimeUsed: map['lastTimeUsed'] as int,
    );
  }

  Duration get duration => Duration(milliseconds: totalTime);
  DateTime get lastUsed => DateTime.fromMillisecondsSinceEpoch(lastTimeUsed);
}

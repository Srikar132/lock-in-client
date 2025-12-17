# FocusModeManager Integration Guide

## Overview

The `FocusModeManager` is a singleton coordinator for all focus mode operations in the Lock-in app. It manages focus sessions, timers, and coordinates with various blocking services.

## Architecture

### Package Structure
```
com.example.lock_in.focus/
  └── FocusModeManager.kt  # Main manager class with all data classes
```

### Key Components

1. **FocusModeManager** - Singleton coordinator
2. **SessionData** - Configuration for focus sessions
3. **SessionState** - Current state of active session
4. **SessionStats** - Statistics after session completion
5. **SessionType** - TIMER, STOPWATCH, or POMODORO
6. **SessionStatus** - ACTIVE, PAUSED, COMPLETED, or CANCELLED

## Features

### 1. Session Management

#### Start Session
```kotlin
val sessionData = SessionData(
    sessionType = SessionType.TIMER,
    plannedDuration = 25 * 60 * 1000L, // 25 minutes
    userId = "user123",
    blockedApps = listOf("com.instagram.android", "com.twitter.android"),
    blockedWebsites = listOf("facebook.com", "twitter.com"),
    blockNotifications = true,
    allowBreaks = false
)

val result = focusModeManager.startSession(sessionData)
if (result.isSuccess) {
    // Session started successfully
}
```

#### Pause Session
```kotlin
val result = focusModeManager.pauseSession()
```

#### Resume Session
```kotlin
val result = focusModeManager.resumeSession()
```

#### End Session
```kotlin
val result = focusModeManager.endSession()
if (result.isSuccess) {
    val stats = result.getOrNull()
    println("Completed ${stats?.completionRate}% of planned duration")
}
```

#### Get Current Status
```kotlin
val sessionState = focusModeManager.getCurrentSessionStatus()
sessionState?.let {
    println("Session ID: ${it.sessionId}")
    println("Status: ${it.status}")
    println("Elapsed: ${it.elapsedTime}ms")
}
```

### 2. Timer Modes

#### Timer Mode
Fixed duration with auto-completion. Timer broadcasts updates every second.

```dart
// Flutter side - Start a 25-minute timer
await platform.invokeMethod('startFocusSession', {
  'sessionType': 'TIMER',
  'plannedDuration': 25 * 60 * 1000,
  'userId': userId,
});
```

#### Stopwatch Mode
Unlimited duration, manual stop only.

```dart
// Flutter side - Start stopwatch
await platform.invokeMethod('startFocusSession', {
  'sessionType': 'STOPWATCH',
  'plannedDuration': 0,
  'userId': userId,
});
```

#### Pomodoro Mode
Work/break cycles:
- 25 minutes work
- 5 minutes short break
- 15 minutes long break (after 4 cycles)

```dart
// Flutter side - Start Pomodoro
await platform.invokeMethod('startFocusSession', {
  'sessionType': 'POMODORO',
  'plannedDuration': 25 * 60 * 1000,
  'userId': userId,
});
```

### 3. Event Broadcasting

The manager broadcasts events via EventChannel to Flutter:

#### Setup EventChannel (Flutter)
```dart
static const EventChannel _eventChannel = 
    EventChannel('com.example.lock_in/focus_events');

Stream<dynamic> get focusEvents => _eventChannel.receiveBroadcastStream();

// Listen to events
focusEvents.listen((event) {
  final type = event['type'];
  switch (type) {
    case 'SESSION_STARTED':
      print('Session ${event['sessionId']} started');
      break;
    case 'TIMER_UPDATE':
      final elapsed = event['elapsed'];
      final remaining = event['remaining'];
      updateUI(elapsed, remaining);
      break;
    case 'POMODORO_UPDATE':
      final isWorkPhase = event['isWorkPhase'];
      final cycleCount = event['cycleCount'];
      updatePomodoroUI(isWorkPhase, cycleCount);
      break;
    case 'SESSION_PAUSED':
      showPausedState();
      break;
    case 'SESSION_RESUMED':
      showActiveState();
      break;
    case 'SESSION_ENDED':
      final stats = event['stats'];
      showCompletionScreen(stats);
      break;
    case 'TIMER_COMPLETED':
      showTimerCompletedNotification();
      break;
    case 'POMODORO_PHASE_CHANGE':
      final isWorkPhase = event['isWorkPhase'];
      showPhaseChangeNotification(isWorkPhase);
      break;
  }
});
```

### 4. MethodChannel API (Flutter Integration)

#### Available Methods

| Method | Arguments | Return | Description |
|--------|-----------|--------|-------------|
| `startFocusSession` | SessionData map | Boolean | Start new session |
| `pauseFocusSession` | None | Boolean | Pause current session |
| `resumeFocusSession` | None | Boolean | Resume paused session |
| `endFocusSession` | None | SessionStats map | End and get stats |
| `getFocusSessionStatus` | None | SessionState map or null | Get current state |
| `isFocusSessionRunning` | None | Boolean | Check if session active |

#### SessionData Map Structure
```dart
{
  'sessionType': 'TIMER' | 'STOPWATCH' | 'POMODORO',
  'plannedDuration': int (milliseconds),
  'userId': string,
  'blockedApps': List<String> (optional),
  'blockedWebsites': List<String> (optional),
  'blockNotifications': bool (default: true),
  'allowBreaks': bool (default: false)
}
```

#### SessionStats Map Structure
```dart
{
  'sessionId': string,
  'sessionType': string,
  'plannedDuration': int (milliseconds),
  'actualDuration': int (milliseconds),
  'completionRate': double (0-100),
  'startTime': long (timestamp),
  'endTime': long (timestamp),
  'interruptions': int
}
```

### 5. Event Types

| Event Type | Payload | Description |
|------------|---------|-------------|
| `SESSION_STARTED` | sessionId, sessionType, plannedDuration | Session started |
| `SESSION_PAUSED` | sessionId, elapsedTime | Session paused |
| `SESSION_RESUMED` | sessionId | Session resumed |
| `SESSION_ENDED` | sessionId, stats | Session ended |
| `TIMER_UPDATE` | elapsed, planned, remaining | Timer tick (every second) |
| `TIMER_COMPLETED` | sessionId | Timer reached planned duration |
| `POMODORO_UPDATE` | elapsed, phaseDuration, remaining, isWorkPhase, cycleCount | Pomodoro tick |
| `POMODORO_PHASE_CHANGE` | isWorkPhase, cycleCount | Work/break phase changed |
| `SERVICES_ACTIVATED` | None | Blocking services started |
| `SERVICES_DEACTIVATED` | None | Blocking services stopped |
| `SERVICES_ERROR` | error | Service activation error |

### 6. Persistent Storage

Sessions are automatically saved to SharedPreferences and restored on app restart:
- Current session data
- Session state (ACTIVE/PAUSED)
- Elapsed time

This ensures sessions survive app restarts and device reboots.

### 7. Service Coordination

The manager coordinates with these services (to be implemented):
- **AppMonitoringService** - Monitors app usage
- **ShortFormBlockingService** - Blocks short-form content
- **WebBlockingVPNService** - Blocks distracting websites
- **NotificationBlockingService** - Blocks notifications

Services are automatically activated when a session starts and deactivated when it ends.

### 8. Thread Safety

The manager uses:
- `synchronized` blocks for critical sections
- `AtomicBoolean` and `AtomicReference` for thread-safe state
- Kotlin Coroutines for async operations
- Main thread Handler for UI callbacks

### 9. Error Handling

All public methods return `Result<T>` type:

```kotlin
val result = focusModeManager.startSession(sessionData)
if (result.isSuccess) {
    // Success
    val value = result.getOrNull()
} else {
    // Error
    val exception = result.exceptionOrNull()
    Log.e(TAG, "Error: ${exception?.message}")
}
```

Common errors:
- `IllegalStateException` - Session already active, no active session, etc.
- General `Exception` - Other errors with descriptive messages

### 10. Cleanup

The manager automatically cleans up resources when MainActivity is destroyed:

```kotlin
override fun onDestroy() {
    super.onDestroy()
    focusModeManager.cleanup()
}
```

This:
- Cancels all coroutines
- Stops timers
- Disconnects event channel

## Example: Complete Flutter Integration

```dart
class FocusSessionService {
  static const MethodChannel _platform = 
      MethodChannel('com.example.lock_in/native');
  static const EventChannel _eventChannel = 
      EventChannel('com.example.lock_in/focus_events');

  Stream<dynamic>? _eventStream;
  
  Stream<dynamic> get focusEvents {
    _eventStream ??= _eventChannel.receiveBroadcastStream();
    return _eventStream!;
  }

  Future<bool> startSession({
    required String sessionType,
    required int durationMinutes,
    required String userId,
    List<String>? blockedApps,
    List<String>? blockedWebsites,
  }) async {
    try {
      final result = await _platform.invokeMethod('startFocusSession', {
        'sessionType': sessionType,
        'plannedDuration': durationMinutes * 60 * 1000,
        'userId': userId,
        'blockedApps': blockedApps ?? [],
        'blockedWebsites': blockedWebsites ?? [],
        'blockNotifications': true,
        'allowBreaks': false,
      });
      return result == true;
    } catch (e) {
      print('Error starting session: $e');
      return false;
    }
  }

  Future<bool> pauseSession() async {
    try {
      final result = await _platform.invokeMethod('pauseFocusSession');
      return result == true;
    } catch (e) {
      print('Error pausing session: $e');
      return false;
    }
  }

  Future<bool> resumeSession() async {
    try {
      final result = await _platform.invokeMethod('resumeFocusSession');
      return result == true;
    } catch (e) {
      print('Error resuming session: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> endSession() async {
    try {
      final result = await _platform.invokeMethod('endFocusSession');
      return result as Map<String, dynamic>?;
    } catch (e) {
      print('Error ending session: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSessionStatus() async {
    try {
      final result = await _platform.invokeMethod('getFocusSessionStatus');
      return result as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting session status: $e');
      return null;
    }
  }

  Future<bool> isSessionRunning() async {
    try {
      final result = await _platform.invokeMethod('isFocusSessionRunning');
      return result == true;
    } catch (e) {
      print('Error checking session status: $e');
      return false;
    }
  }
}
```

## Next Steps

To complete the focus mode system, implement:

1. **AppMonitoringService** - Track app usage in real-time
2. **ShortFormBlockingService** - Detect and block short-form content
3. **WebBlockingVPNService** - VPN-based website blocking
4. **NotificationBlockingService** - Block notifications during sessions
5. Integrate services with FocusModeManager's `activateBlockingServices()` and `deactivateBlockingServices()` methods

## Notes

- The manager is designed to be memory efficient and battery friendly
- All operations are asynchronous to avoid blocking the UI thread
- Sessions persist across app restarts
- Comprehensive logging is available for debugging (use tag "FocusModeManager")
- The implementation follows Android best practices for background operations

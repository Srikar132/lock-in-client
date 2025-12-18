# New Clean Architecture Implementation

## Overview

This document describes the new clean architecture implemented for the Lock-In Android app, which provides clear separation of concerns between focus sessions, app limits, and various blocking mechanisms.

## Architecture Principles

### Separation of Concerns

The new architecture separates functionality into distinct, independent systems:

1. **Focus Mode System** - Session-based blocking during active focus sessions
2. **App Limits System** - Always-on daily/weekly app usage limits
3. **Content Blocking System** - Always-on blocking for shorts, websites, and notifications

### Key Improvements

- **No Mixed Responsibilities**: Each service has one clear purpose
- **Independent Operation**: Blocking systems work independently of focus sessions
- **Centralized Configuration**: All persistent settings stored in one place
- **Single Overlay Entry Point**: All overlays launched through one launcher
- **Clean State Management**: Session state completely separate from blocking state

## System Architecture

### System 1: Focus Mode (Session-Based)

```
┌─────────────────────────────────────────────────────────┐
│                    FOCUS MODE SYSTEM                     │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
              ┌─────────────────────────┐
              │  FocusSessionManager    │  ← ONLY manages sessions
              │  - Start/Pause/End      │
              │  - Timer management     │
              │  - Session state        │
              │  - Interruption tracking│
              └────────────┬────────────┘
                           │
                           │ When session active
                           ▼
              ┌─────────────────────────┐
              │ FocusMonitoringService  │  ← ONLY monitors during sessions
              │  - Foreground service   │
              │  - Checks current app   │
              │  - Shows overlay if     │
              │    app is in session's  │
              │    blocked list         │
              └─────────────────────────┘
```

**Files:**
- `services/focus/FocusSessionManager.kt` - Pure session management
- `services/focus/FocusMonitoringService.kt` - Session-based app monitoring

### System 2: Always-On Blocking

```
┌─────────────────────────────────────────────────────────┐
│                   BLOCKING SYSTEM                        │
└─────────────────────────────────────────────────────────┘
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────┐ ┌──────────────┐ ┌──────────────────┐
│  App Limiter    │ │ Shorts/Web   │ │  Notification    │
│  Manager        │ │ Blocker      │ │  Blocker         │
│                 │ │              │ │                  │
│ - Check usage   │ │ - Detect     │ │ - Filter notifs  │
│ - Show overlay  │ │   shorts     │ │ - Allow critical │
│ - Independent   │ │ - Block web  │ │ - Independent    │
└─────────────────┘ └──────────────┘ └──────────────────┘
         │                 │                  │
         └─────────────────┼──────────────────┘
                           │
                           ▼
                 ┌────────────────────┐
                 │   OverlayLauncher  │
                 │   (Shared Entry)   │
                 └────────────────────┘
```

**Files:**
- `services/limits/AppLimitMonitoringService.kt` - App usage limits
- `services/ShortFormBlockingService.kt` - Short-form content blocking
- `services/WebBlockingVPNService.kt` - Website blocking via VPN
- `services/NotificationBlockingService.kt` - Notification filtering
- `services/overlay/OverlayLauncher.kt` - Single overlay entry point

### System 3: Shared Infrastructure

```
┌─────────────────────────────────────────────────────────┐
│                  SHARED INFRASTRUCTURE                   │
└─────────────────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
┌──────────────────┐      ┌──────────────────┐
│ BlockingConfig   │      │ MonitoringHelper │
│                  │      │                  │
│ - Persistent     │      │ - Get current    │
│   app blocks     │      │   foreground app │
│ - Persistent     │      │ - Usage stats    │
│   web blocks     │      │ - App names      │
│ - Short-form     │      │ - Permissions    │
│   config         │      │ - Utilities      │
│ - Notification   │      │                  │
│   config         │      │                  │
└──────────────────┘      └──────────────────┘
```

**Files:**
- `services/shared/BlockingConfig.kt` - Centralized configuration storage
- `services/shared/MonitoringHelper.kt` - Shared utility functions

## Component Details

### FocusSessionManager

**Responsibilities:**
- Start/pause/resume/end focus sessions
- Timer management (countdown, stopwatch, pomodoro)
- Session state persistence
- Interruption tracking
- Flutter event communication

**Does NOT handle:**
- App blocking (delegated to FocusMonitoringService)
- Persistent blocking (delegated to BlockingConfig)
- App limits (delegated to AppLimitManager)

**Key Methods:**
```kotlin
fun startSession(sessionData: Map<String, Any>): Boolean
fun pauseSession(): Boolean
fun resumeSession(): Boolean
fun endSession(): Boolean
fun recordInterruption(packageName: String, appName: String, type: String, wasBlocked: Boolean)
fun isSessionActive(): Boolean
fun getCurrentSession(): FocusSession?
fun getCurrentSessionStatus(): Map<String, Any>?
```

### FocusMonitoringService

**Responsibilities:**
- Runs as foreground service ONLY during active focus sessions
- Monitors current foreground app every 1.5 seconds
- Shows overlay when blocked app is detected
- Records interruptions via FocusSessionManager

**Lifecycle:**
- Started when focus session starts (via MainActivity)
- Stopped when focus session ends (via MainActivity)
- Automatically stops if session becomes inactive

**Key Methods:**
```kotlin
companion object {
    fun start(context: Context)
    fun stop(context: Context)
}
```

### AppLimitMonitoringService

**Responsibilities:**
- Runs as foreground service when app limits are configured
- Monitors app usage against daily/weekly limits
- Shows overlay when limit is exceeded
- Completely independent of focus sessions

**Lifecycle:**
- Started when app limits are configured
- Stopped when all app limits are removed
- Resets daily blocks at midnight

### OverlayLauncher

**Responsibilities:**
- Single entry point for ALL block overlays
- Manages overlay priority (Focus > Limits > Shorts > Websites)
- Debounces rapid overlay requests
- Creates appropriate Intents for BlockOverlayActivity

**Overlay Types:**
- `blocked_app` - Focus session blocking
- `app_limit` - Daily/weekly limit exceeded
- `blocked_shorts` - Short-form content
- `blocked_website` - Blocked website
- `blocked_notification` - Notification blocked

**Key Methods:**
```kotlin
fun showFocusBlockOverlay(packageName: String, appName: String, sessionData: Map<String, Any>?)
fun showAppLimitOverlay(packageName: String, appName: String, usedMinutes: Int, limitMinutes: Int)
fun showShortsBlockOverlay(packageName: String, appName: String, contentType: String)
fun showWebsiteBlockOverlay(url: String, reason: String)
fun showNotificationBlockOverlay(packageName: String, appName: String, notificationTitle: String)
```

### BlockingConfig

**Responsibilities:**
- Centralized storage for all persistent blocking settings
- Separate from session-based blocking
- Used by always-on blocking services

**Configuration Types:**
- Persistent app blocking (always-on)
- Persistent website blocking (always-on)
- Short-form blocking settings
- Notification blocking settings

**Key Methods:**
```kotlin
fun setPersistentAppBlocking(enabled: Boolean)
fun setPersistentBlockedApps(packageNames: List<String>)
fun isPersistentAppBlockingEnabled(): Boolean
fun getPersistentBlockedApps(): List<String>
// Similar methods for websites, shorts, notifications
```

### MonitoringHelper

**Responsibilities:**
- Shared utility functions for all monitoring services
- App detection and usage stats
- Permission checks
- Common helpers

**Key Functions:**
```kotlin
fun getCurrentForegroundApp(context: Context): String
fun getAppName(context: Context, packageName: String): String
fun getTodayUsageMinutes(context: Context, packageName: String): Int
fun hasUsageStatsPermission(context: Context): Boolean
fun hasOverlayPermission(context: Context): Boolean
```

## Flow Diagrams

### Flow 1: Focus Mode Session

```
User starts focus session (Flutter)
         │
         ▼
MainActivity.startFocusSession()
         │
         ├─ FocusSessionManager.startSession()
         │   ├─ Save session to SharedPreferences
         │   ├─ Start timer
         │   └─ Send "session_started" event to Flutter
         │
         └─ FocusMonitoringService.start()
                    │
                    ▼
         FocusMonitoringService runs
                    │
         ┌──────────┴──────────┐
         │  Every 1.5 seconds  │
         │  Check current app  │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │ Is current app in   │
         │ session.blockedApps?│
         └──────────┬──────────┘
                    │
              Yes   │   No
         ┌──────────┼──────────┐
         ▼                     ▼
OverlayLauncher.showFocusBlockOverlay()
         │                Continue monitoring
         ▼
BlockOverlayActivity shown
         │
         ▼
FocusSessionManager.recordInterruption()
```

### Flow 2: App Limits (Always-On)

```
User sets app limit (30 min/day for Instagram)
         │
         ▼
MainActivity.setAppLimits()
         │
         ├─ AppLimitManager.setAppLimits()
         │   └─ Save to SharedPreferences
         │
         └─ AppLimitMonitoringService.start()
                    │
                    ▼
         Service monitors every 2 seconds
                    │
         ┌──────────▼──────────┐
         │  Get usage stats    │
         │  for limited apps   │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │ Is usage > limit?   │
         └──────────┬──────────┘
                    │
              Yes   │   No
         ┌──────────┼──────────┐
         ▼                     ▼
OverlayLauncher.showAppLimitOverlay()
         │                Continue checking
         ▼
BlockOverlayActivity shown
         │
         ▼
Block app for rest of day
```

### Flow 3: Short-Form Content (Always-On)

```
User enables "Block YouTube Shorts"
         │
         ▼
ShortFormBlockingService detects Shorts UI
         │
         ▼
OverlayLauncher.showShortsBlockOverlay()
         │
         ▼
BlockOverlayActivity shown
         │
         ▼
performGlobalAction(GLOBAL_ACTION_BACK)
         │
         ▼
If session active: sessionManager.recordInterruption()
```

## Migration Guide

### Old vs New

**OLD (FocusModeManager):**
```kotlin
// Mixed responsibilities - sessions AND persistent blocking
val focusManager = FocusModeManager(context)
focusManager.startSession(data)
focusManager.setPersistentAppBlocking(enabled, apps)
```

**NEW (Clean Architecture):**
```kotlin
// Session management
val sessionManager = FocusSessionManager.getInstance(context)
sessionManager.startSession(data)
FocusMonitoringService.start(context)

// Persistent blocking
val blockingConfig = BlockingConfig.getInstance(context)
blockingConfig.setPersistentAppBlocking(enabled)
blockingConfig.setPersistentBlockedApps(apps)
```

### Key Changes

1. **FocusModeManager** → **FocusSessionManager** (session only)
2. **AppMonitoringService** → **FocusMonitoringService** (session only) + **AppLimitMonitoringService** (limits only)
3. Persistent blocking moved to **BlockingConfig**
4. All overlay launches go through **OverlayLauncher**
5. Shared utilities in **MonitoringHelper**

## Benefits

### 1. Clear Separation of Concerns
- Each service has ONE responsibility
- No mixed logic between sessions and persistent blocking
- Easy to understand and maintain

### 2. Independent Operation
- App limits work WITHOUT active session
- Short-form blocking works WITHOUT active session
- Website blocking works WITHOUT active session
- Focus sessions don't interfere with persistent blocking

### 3. Better Testing
- Each component can be tested independently
- Mock dependencies easily
- Clear input/output contracts

### 4. Easier Debugging
- Clear responsibility boundaries
- Single source of truth for each concern
- Simple data flow

### 5. Scalability
- Easy to add new blocking types
- Easy to add new monitoring services
- Clean extension points

## Edge Cases Handled

1. **App killed during session** → Restore session from SharedPreferences on restart
2. **Multiple blocks active** → OverlayLauncher handles priority (Focus > Limits > Shorts)
3. **Quick app switching** → Debounce detection (1.5s cooldown)
4. **Service crashes** → Restart with JobScheduler / START_STICKY
5. **Battery optimization** → Request exemption via PermissionManager
6. **Overlay permissions** → Check before launching, graceful fallback
7. **VPN already active** → Detect conflict in WebBlockingVPNService
8. **Accessibility disabled** → Detect and show settings prompt

## Testing Checklist

- [ ] Start focus session → FocusMonitoringService starts
- [ ] End focus session → FocusMonitoringService stops
- [ ] Open blocked app during session → Overlay shows
- [ ] Set app limit → AppLimitMonitoringService starts
- [ ] Exceed app limit → Overlay shows
- [ ] Enable shorts blocking → Blocks work WITHOUT session
- [ ] Enable website blocking → VPN blocks work WITHOUT session
- [ ] Enable notification blocking → Notifications filtered WITHOUT session
- [ ] Session + app limit → Both work independently
- [ ] Session + shorts blocking → Both work independently
- [ ] Kill app during session → Session restores on restart
- [ ] Clear data → All services handle gracefully

## Future Enhancements

1. **Pomodoro Timer** - Implement full pomodoro cycle logic in FocusSessionManager
2. **Group Sessions** - Add multi-user focus sessions
3. **Smart Limits** - AI-based app limit suggestions
4. **Better Overlays** - Enhanced BlockOverlayActivity with better UX
5. **Analytics** - Comprehensive usage analytics and insights
6. **Widgets** - Home screen widgets for quick session control
7. **Wear OS** - Android Watch integration

## Conclusion

The new architecture provides a clean, maintainable, and scalable foundation for the Lock-In app. Each component has clear responsibilities, operates independently, and follows SOLID principles. This makes the codebase easier to understand, test, and extend.

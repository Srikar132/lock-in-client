# Persistent (Always-On) Blocking System

## Overview

The Lock-In app now supports **persistent blocking** that works independently of focus sessions. Users can enable different types of blocking that will remain active even when no focus session is running.

## Blocking Types

### 1. App Blocking
- **Method**: `setPersistentAppBlocking(enabled, blockedApps)`
- **Query**: `isPersistentAppBlockingEnabled()`, `getPersistentBlockedApps()`
- **Description**: Blocks specific apps 24/7 regardless of focus sessions

### 2. Website Blocking  
- **Method**: `setPersistentWebsiteBlocking(enabled, blockedWebsites)`
- **Query**: `isPersistentWebsiteBlockingEnabled()`, `getPersistentBlockedWebsites()`
- **Description**: Blocks websites through VPN service always-on

### 3. Short-Form Content Blocking
- **Method**: `setPersistentShortFormBlocking(enabled, shortFormBlocks)`
- **Query**: `isPersistentShortFormBlockingEnabled()`, `getPersistentShortFormBlocks()`
- **Description**: Blocks short-form content (reels, shorts, etc.) permanently

### 4. Notification Blocking
- **Method**: `setPersistentNotificationBlocking(enabled, notificationBlocks)`
- **Query**: `isPersistentNotificationBlockingEnabled()`, `getPersistentNotificationBlocks()`
- **Description**: Blocks notifications from specific apps always

## Implementation Details

### Storage
All persistent settings are stored in `SharedPreferences` with these keys:
- `KEY_PERSISTENT_APP_BLOCKING` + `KEY_PERSISTENT_BLOCKED_APPS`
- `KEY_PERSISTENT_WEBSITE_BLOCKING` + `KEY_PERSISTENT_BLOCKED_WEBSITES`  
- `KEY_PERSISTENT_SHORT_FORM_BLOCKING` + `KEY_PERSISTENT_SHORT_FORM_BLOCKS`
- `KEY_PERSISTENT_NOTIFICATION_BLOCKING` + `KEY_PERSISTENT_NOTIFICATION_BLOCKS`

### Service Coordination
- `AppMonitoringService` handles app blocking and runs when any blocking is active
- `WebBlockingVPNService` is controlled for website blocking
- `ShortFormBlockingService` is updated for short-form blocking
- `NotificationBlockingService` is updated for notification blocking

### Method Channel Integration
Flutter can control all blocking types via these method channels:

```dart
// App blocking
await NativeService.setPersistentAppBlocking(enabled: true, blockedApps: ['com.instagram.android']);
bool isEnabled = await NativeService.isPersistentAppBlockingEnabled();
List<String> apps = await NativeService.getPersistentBlockedApps();

// Website blocking  
await NativeService.setPersistentWebsiteBlocking(enabled: true, blockedWebsites: [{'domain': 'facebook.com'}]);

// Short-form blocking
await NativeService.setPersistentShortFormBlocking(enabled: true, shortFormBlocks: {'youtube_shorts': true});

// Notification blocking
await NativeService.setPersistentNotificationBlocking(enabled: true, notificationBlocks: {'instagram': true});
```

## Monitoring Logic

The system now monitors for blocking based on these conditions:

1. **App Blocking**: Active if focus session running OR persistent app blocking enabled
2. **Website Blocking**: Active if focus session running OR persistent website blocking enabled  
3. **Short-Form Blocking**: Active if focus session running OR persistent short-form blocking enabled
4. **Notification Blocking**: Active if focus session running OR persistent notification blocking enabled

## Service Lifecycle

- Services start automatically when persistent blocking is enabled
- Services stop automatically when persistent blocking is disabled (and no active session)
- Services restart after task removal if any persistent blocking is active
- Each blocking type is independent - can enable/disable individually

## Benefits

1. **Independent Control**: Each blocking type works separately
2. **Persistent**: Blocking continues even without focus sessions
3. **Automatic**: Services manage themselves based on settings
4. **Flexible**: Users can enable only the blocking they need
5. **Reliable**: Survives app restarts and system kills

## Usage Example

```kotlin
// Enable persistent Instagram app blocking
focusModeManager.setPersistentAppBlocking(true, listOf("com.instagram.android"))

// Enable persistent social media website blocking  
focusModeManager.setPersistentWebsiteBlocking(true, listOf(
    mapOf("domain" to "facebook.com"),
    mapOf("domain" to "twitter.com")
))

// Enable persistent YouTube Shorts blocking
focusModeManager.setPersistentShortFormBlocking(true, mapOf("youtube_shorts" to true))

// Enable persistent notification blocking for social apps
focusModeManager.setPersistentNotificationBlocking(true, mapOf(
    "instagram" to true,
    "facebook" to true
))
```

This creates a comprehensive always-on digital wellness system independent of focus sessions.
